# Wikireader build utilies
This repo (and docker container) contain the tools necessary to build an updated wikireader image.

# Get the latest image
Pull it down from dockerhub
```
docker pull stephenmw/wikireader
```

Or you can build it yourself after checking out the repo.
```
docker build -t <image name> .
```

# Building
You must do a parallized build in order to create `dat` files that are small enough for the wikireader. Parallelism is controlled via parameters of the `Run` script.

By default the `Run` file runs all parallelized processes at once. This can often be too much for your system to handle memory wise. To control the max number of concurrent parsers and renders running at once, you can set the environment variable `MAX_CONCURRENT`, which prevents new parsers or renders from running until they can get a semaphor lock.

On my machine, which is an 4 core 8 thread i7 with 32 GB of ram, I find that running `MAX_CONCURRENT` at 8 with parallelism to 16 is good enough. That will use about 16 GB of ram.

## Docker settings
By default docker doesn't share a lot of resources. You'll want to max out the CPU and memory share to your container in your docker configuration.

# Preparing a wikipedia dump file
Wikipedia dump files can be downloaded directly from wikipedia. There's some preparation you'll need to do to the file before it will work. You'll need to dedupe the titles as well as cleanup some of the unnused template (```{{#invoke:....}}```).

You can use the `scripts/clean_xml` script to complete that task. By default it will cleanup the XML file. Beware that this script temporarily create a new file the same size as the original, so make sure you have enough space.

After cleanup, you'll either need to place or symlink the wikipedia file into the `wikireader` directory, since the `Run` script has rigid rules about the files. Since you probably don't want to upload the entire file to your docker context, this is best solved by sharing the `build` directory with your docker container and then symlinking into your wikireader directory (see the script parameters at the bottom to see how it's done).

# Commands for building
The below commands assume you've downloaded a wikipedia dump to the `build` directory. I'm using the Dec 20 dump as an example.
```
# Dedupe/clean the wikipedia file. Note that this creates a temporary file of roughly the same size until the process is finished. Make sure you have enough space.
scripts/clean_xml build/enwiki-20191201-pages-articles.xml

# Launch docker and share the build directory with `/build`. Make sure you run this from your `wikireader` directory.
docker run --rm -v $(pwd)/build:/build -ti stephenmw/wikireader:latest bash

# Symlink over the file
ln -s /build/enwiki-pages-articles.xml enwiki-pages-articles.xml

# Set the max concurrency and give this attempt a name. I use 8 for my system. Use whatever works for you.
export MAX_CONCURRENCY=8 
export RUNVER="test"

# Start the processing and wait a really link time (4.5 days for me)
time scripts/Run --parallel=16 --machines=1 --farm=1 --work=/build/${RUNVER}/work --dest=/build/${RUNVER}/image --temp=/dev/shm --clear ::::::: 2>&1 < /dev/null

# Combine the files and create the image
make WORKDIR=/build/${RUNVER}/work DESTDIR=/build/${RUNVER}/image combine install

# Remove / cleanup the work directory
rm -rfv /build/${RUNVER}/work
```

After this process, you can shutdown your container. The new image will be found under `build/${RUNVER}/image`. You can copy this entire directory over to your SD card.

# Preparing the SD card
The SD card must be formatted as fat32.

# Old doc
The old readme can be found under doc/
