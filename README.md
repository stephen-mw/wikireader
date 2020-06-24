# Wikireader build utilities
This repo (and docker container) contain the tools necessary to build an updated wikireader image.

## Differences between this and the original wikireader repo
* This repo includes an updated fork of the [WikiExtractor.py](https://github.com/attardi/wikiextractor) script built specifically for the wikireader. This file is used to dedupe and generate the plaintext XML and makes processing MUCH faster.
* The docker container is pre-built with everything you need.
* Concurrency can be set independently of the `Build` script (in fact, you shouldn't set parallelism in the `Build` script at all).

# Get the latest image
Pull it down from dockerhub
```
docker pull stephenmw/wikireader:latest
```

Or you can build it yourself after checking out the repo.
```
docker build -t wikireader .
```

to build the core system (the wikireader binaries), you can build from within the `core` directory:
```
cd core
docker build -t wikireader_core .
```

# Building your own wikireader image
## Requirements
In order to build a new wikireader image, you'll need:
1. [docker](https://www.docker.com/products/docker-desktop)
2. [git](https://git-scm.com/downloads)
3. Very basic knowledge of the command line

## Building
Once you have those tools, you can simply clone this repo and run the `autowiki` command inside docker, which is completely automated and will do the entire processing for you.

It's important to note that we're "sharing" the `build` folder with docker, so once docker exits the processed image will be in that folder.

The following command builds the 20200601 image of wikireader (you can see what's available at the [wikimedia dump page](https://dumps.wikimedia.org/enwiki/20200620/))
```
git clone https://github.com/stephen-mw/wikireader.git
cd wikireader
docker run --rm -v $(pwd)/build:/build -ti docker.io/stephenmw/wikireader:latest autogen 20200601
```

After processing is complete (A little over 12 hours on my setup), you just need to copy the contents of `build/20200601/image` to the root of your SD card. If you only want to update the `enpedia` directory, then copy the contents of `build/20200601/image/enpedia` to the `enpedia` directory of your SD card (remove the existing files in there first).


## Building manually
The build process involves 4 steps.

1. Download and decompress a wikimedia dump index.
2. Clean/parse the XML using the `clean_xml` script.
    * This script effectively creates a text version of the dump, which is much faster at processing.
3. Complete the parsing, rendering, and combining.
4. Copy the contents to a FAT32 SD card and enjoy.

## Resource requirements
Processing takes about 16 GB of ram, the largest section being the sorting of the index. I set MAX_CONCURRENCY to 8 which is the number of processors I have on my i7. The `autowiki` script defaults `MAX_CONCURRENCY` to the number of CPUs on the host.

### Docker settings
By default docker doesn't share a lot of resources if running on a mac or windows. You'll want to max out the CPU and memory share to your container in your docker configuration. On linux this is not an issue as far as I know.

## Preparing a wikipedia dump file
This repo included a forked version of the [WikiExtractor.py](https://github.com/attardi/wikiextractor) file which is renamed to `clean_xml`. Before processing the XML dump, you'll need to run the `clean_xml` script on it to tidy things up. In my fork, I've made some improvements that are specific to the wikireader.

If you were to create a wikireader image without running `clean_xml` on it, it would be full of all kinds of `{{ foo }}` internal unrendered template strings.

Using the `clean_xml` file also has the bonus of making the parsing phase of the wikireader process go by much faster. Days faster! And it reduces the final dump size from around 70 GB to 16 GB (20200601 data). Check below for the 1-liner for downloading, decompressing, and cleaning the dump all in 1 go. It will save you from storing 70 GB.

The `clean_xml` script does 3 important things:

* The pages are rendered to text, and links are preserved in a wikireader-specific format.
* Links are translated to the wikireader format
* Bullets are translated to the wikireader format
* Titles are deduped.
* The output template is an XML format understood by the wikireader rendering process.

On my machine, it takes approximately 90 minutes to download, decompress, and clean the XML file, which reduces the filesize from 70GB to around 16GB.

### Download, decompress, clean (long way)
```
# This is the link to the June 2020 dump. Change as needed
wget https://dumps.wikimedia.org/enwiki/20200601/enwiki-20200601-pages-articles.xml.bz2

# Decompress
bzip -d https://dumps.wikimedia.org/enwiki/20200601/enwiki-20200601-pages-articles.xml.bz2

# Clean
../scripts/clean_xml enwiki-20200601-pages-articles.xml --wikireader --links --keep_tables -o- > enwiki-20200601-pages-articles.xml_clean
```

### Download, decompress, clean (one-liner)
Do it all in 1 go and save yourself 70GB of unnecessary disk space.

```
# Download, decompress, and clean
curl -L 'https://dumps.wikimedia.org/enwiki/20200601/enwiki-20200601-pages-articles.xml.bz2' -o- | bzcat | ../scripts/clean_xml - --wikireader --links --keep_tables -o- > enwiki-20200601-pages-articles.xml_clean
```

## Commands for building
The entire build process takes place inside a docker container. You'll need to share your `build/` directory over to the container. Remember, if you're running on mac or windows make sure you share enough resources with the container to do the build (max CPU and max ram).

In these examples I do the `clean_xml` script in the docker container. There's no requirement that this is done from within the container, but the container does have the right tools for it (requires bzip2 and python3.7+).

```
# Get the latest docker image
docker pull stephenmw/wikireader

# This is where the wikimedia dump and rendered output will be
mkdir build

# Launch docker and share the build directory with `/build`. Make sure you run this from your `wikireader` directory.
docker run --rm -v $(pwd)/build:/build -ti stephenmw/wikireader:latest bash

# Usually best to set this value to the number of CPU cores of the system.
export MAX_CONCURRENCY=8 

# The URI for the database dump you want to use
export URI="https://dumps.wikimedia.org/enwiki/20200601/enwiki-20200601-pages-articles.xml.bz2"

# This will automatically set the RUNVER to the dateint of the dump
export RUNVER="$(echo $URI | perl -wnlE 'say /(\d{8})/')"

# Download/clean the wikimedia dump
time curl -L "${URI}" -o- | bzcat | python3.8 scripts/clean_xml - --wikireader --links --lists -o- > /build/enwiki-${RUNVER}-pages-articles.xml_clean

# Symlink the file to create a filename expected by the processing application. The actual file name will vary depending on which dump of the wikimedia software you downloaded.
ln -s /build/enwiki-${RUNVER}-pages-articles.xml_clean enwiki-pages-articles.xml

# Start the processing!
time scripts/Run --parallel=64 --machines=1 --farm=1 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm en:::NO:255::: 2>&1 < /dev/null

# Combine the files and create the image
make WORKDIR=/build/${RUNVER}/work DESTDIR=/build/${RUNVER}/image combine install
```

After this process, you can shutdown your container. The new image will be found under `build/${RUNVER}/image`. You can copy this entire directory over to your SD card.

# Building on multiple computers
The `Run` script also allows you to build on multiple computers. The caveat is that the computers should have similar resources, since the work is split evenly. The process is exactly the same as building with 1 computer, except you change the `--farm=N` flag and `--machines=N` flag.

After the build completes, you copy the `.dat` files to one of the computers (either one) in order to finish the last combine step.

```
# Note the -32 in the command field. This will ensure that of the 64 shards, 32 are built per host (32 * 2 computers = 64 shards).

# On host 1
time scripts/Run --parallel=64 --machines=2 --farm=1 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm ::::::-32: 2>&1 < /dev/null

# On host 2
time scripts/Run --parallel=64 --machines=1 --farm=2 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm ::::::-32: 2>&1 < /dev/null

# Copy the files from host2 to host1
scp /build/${RUNVER}/image/* host1:/build/${RUNVER}/image/

# On host 1, do final combine and install
make WORKDIR=/build/${RUNVER}/work DESTDIR=/build/${RUNVER}/image combine install
```

# Testing the image using the wiki-simulator
After building, you might want to test the image using the simulator before loading it onto your SD card. You can use the `wiki-simulator` command to do this.

On my mac I have [xquartz](https://www.xquartz.org/) installed. I connect to my build server with X Forwarding so that I don't have to install any of the software locally. 

Unfortunately this process can't be done in a container build server. I haven't had time to figure out exactly what's necessary to fix it. In the meantime I keep the software installed on a linux server for this process.

```
# Connect from my mac to the build server with X Forwarding
ssh -X buildserver

# Run the simuilator
make DESTDIR=build/20200101/ wiki-simulate
```

This will build and run the simulator for you to test the wikireader behavior.

# Preparing the SD card
The SD card must be formatted as fat32. I've tested with 32GB and 16GB sd cards and they both work fine.

# Old doc
The old readme can be found under doc/
