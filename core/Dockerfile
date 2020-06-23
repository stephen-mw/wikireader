FROM ubuntu:bionic

ENV DEBIAN_FRONTEND="noninteractive"

WORKDIR /wikireader

RUN apt update -y
RUN apt update && apt install -y \
    bison                        \
    curl                         \
    dvipng                       \
    flex                         \
    g++                          \
    gawk                         \
    gforth                       \
    git                          \
    guile-2.2                    \
    libqt4-dev                   \
    m4                           \
    make                         \
    mecab-ipadic-utf8            \
    netpbm                       \
    nodejs                       \
    npm                          \
    ocaml                        \
    parallel                     \
    python-dev                   \
    python-gd                    \
    python-lzma                  \
    python-mecab                 \
    python-serial                \
    python3-jinja2               \
    qt4-qmake                    \
    sqlite3                      \
    vim                          \
    wget                         \
    xfonts-utils

RUN apt install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt update && apt install -y \
    php5.6-cli                   \
    php5.6-common                \
    php5.6-json                  \
    php5.6-mbstring              \
    php5.6-sqlite                \
    php5.6-tidy                  \
    php5.6-xml
RUN ln -s /usr/bin/php5.6 /usr/bin/php5

# Install python3.8 for cleaning up the XML
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install -y python3.8

# Removing the annoying gnu parallel prompt
RUN mkdir /root/.parallel && touch /root/.parallel/will-cite

RUN git clone https://github.com/stephen-mw/wikireader.git /wikireader

# There will be a binutils failure here
RUN make clean && make requirements && make || true
RUN cp /wikireader/SavedCaches/config.cache-binutils-12.10 /wikireader/host-tools/binutils-2.10.1/build/config.cache

# There will be a gcc error here
RUN make || true
RUN cp /wikireader/SavedCaches/config.cache-gcc-12.10 /wikireader/host-tools/gcc-3.3.2/build/config.cache

# Should be good to go
RUN make

# Make a simple combination, which will download additional tools
RUN make DESTDIR=/tools/image WORKDIR=/tools/work XML_FILES="XML-Licenses/en/license.xml XML-Licenses/en/terms.xml xml-file-samples/text-example.xml" cleandirs createdirs iprc
RUN make DESTDIR=/tools/image WORKDIR=/tools/work combine install

# Make the compiled tools available on the path
ENV PATH="/wikireader/host-tools/toolchain-install/bin:${PATH}"
