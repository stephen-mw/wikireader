# Wikireader build utilies
This repo (and docker container) contain the tools necessary to build an updated wikireader image.

## Differences between this and the original wikireader repo
* All dependencies already installed and ready to go.
* Maximum concurrency per host can be controlled via the `MAX_CONCURRENCY` var.
* Can be built from any host that runs docker.
* Script added to cleanup xml file.

## Known issues
* There appears to be a corruption issue with some of the indexes, causing some many articles not to load. You will see the message `The article, 4ab978, failed to load. Please restart your WikiReader and try again.`

# Get the latest image
Pull it down from dockerhub
```
docker pull stephenmw/wikireader:latest
```

Or you can build it yourself after checking out the repo.
```
docker build -t wikireader .
```

# Building a new wikireader image
The build process currency takes 3 steps:

1. Download the latest `enwiki-<date>-pages-articles.xml` file dump.
2. Run the `clean_xml` script on the file and create a new parsed XML file. This process will basically remove all formatting other than text and links, as well as dedupe the index.
3. Do the rendering.
4. After rendering is complete, look in the en-log file and find all of the titles which didn't render.
6. Run the entire process over again.

You must do a parallized build in order to create `dat` files that are small enough for the wikireader. Parallelism is controlled via parameters of the `Run` script. See below for examples.

By default the `Run` file runs all parallelized processes at once. This can often be too much for your system to handle memory wise. To control the max number of concurrent parsers and renders running at once, you can set the environment variable `MAX_CONCURRENT`, which prevents new parsers or renders from running until they can get a semaphor lock.

On my machine, which is an 4 core 8 thread i7 with 32 GB of ram, I find that running `MAX_CONCURRENT` at 8 with parallelism to 64 works well. That will use about 16 GB of ram during the sort phase. Make sure you have enough ram or swap to get it through.

## Docker settings
By default docker doesn't share a lot of resources if running on a mac or windows. You'll want to max out the CPU and memory share to your container in your docker configuration. On linux this is not an issue as far as I know.

# Preparing a wikipedia dump file
Wikipedia dump files can be downloaded directly from wikipedia. There's some preparation you'll need to do to the file before it will work.

You can use the `scripts/clean_xml` script to prepare the dump. By default it will cleanup the XML file. This will create a new dump file that's approximately 16 GB as of June 8th, 2020. The `clean_xml` script requires python3.7 or above, which is installed on the container.

```
# Assuming you have the dump downloaded to the `build` directory
../scripts/clean_xml enwiki-20200501-pages-articles.xml --wikireader --links -o- > enwiki-20200501-pages-articles.xml_clean
```

After cleanup, you'll either need to place or symlink the wikipedia file into the `wikireader` directory, since the `Run` script has rigid rules about the files. Since you probably don't want to upload the entire file to your docker context, this is best solved by sharing the `build` directory with your docker container and then symlinking into your wikireader directory (see the script parameters at the bottom to see how it's done).

# Commands for building
The below commands assume you've downloaded a wikipedia dump to the `build` directory. I'm using the Dec 20 dump as an example.
```
# Get the latest docker image
docker pull stephenmw/wikireader

# Dedupe/clean the wikipedia file.
scripts/clean_xml build/enwiki-20191201-pages-articles.xml --wikireader --links -o- > build/enwiki-20191201-pages-articles.xml_clean

# Launch docker and share the build directory with `/build`. Make sure you run this from your `wikireader` directory.
docker run --rm -v $(pwd)/build:/build -ti stephenmw/wikireader:latest bash

# Symlink the file to create a filename expected by the processing application. The actual file name will vary depending on which dump of the wikimedia software you downloaded.
ln -s /build/enwiki-20191201-pages-articles.xml_clean enwiki-pages-articles.xml

# Set the max concurrency and give this attempt a name. I use 8 for my system. Use whatever works for you. I recommend you use high parallel counts with the number of cores you have minus 1. Keep in mind there's skew in the processing and the first worker will take about 2x longer than the others.
export MAX_CONCURRENCY=8 
export RUNVER="test"

# Start the processing and wait a really link time (4.5 days for me). The `parallel=16` creates 16 shards but doesn't actually run them all in parallel. See MAX_CONCURRENCY for adjusting that. This parallel number must be greater than 4 to create files small enough to fit onto a FAT32 SD card.
time scripts/Run --parallel=64 --machines=1 --farm=1 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm --clear ::::::: 2>&1 < /dev/null

# Combine the files and create the image
make WORKDIR=/build/${RUNVER}/work DESTDIR=/build/${RUNVER}/image combine install

# Remove / cleanup the work directory
rm -rfv /build/${RUNVER}/work
```

After this process, you can shutdown your container. The new image will be found under `build/${RUNVER}/image`. You can copy this entire directory over to your SD card.

# Building on multiple computers
The `Run` script also allows you to build on multiple computers. The caveat is that the computers should have similar resources, since the work is split evenly. The process is exactly the same as building with 1 computer, except you change the `--farm=N` flag and `--machines=N` flag.

After the build completes, you copy the `.dat` files to one of the computers (either one) in order to finish the last combine step.

```
# Note the -8 in the command field. This will ensure that of the 16 shards, 8 are built per host (8 * 2 computers = 16 shards).

# On host 1
time scripts/Run --parallel=8 --machines=2 --farm=1 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm --clear ::::::-8: 2>&1 < /dev/null

# On host 2
time scripts/Run --parallel=8 --machines=1 --farm=2 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm --clear ::::::-8: 2>&1 < /dev/null

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
