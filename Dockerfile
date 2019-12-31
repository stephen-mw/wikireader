FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /wikireader

RUN apt update -y
RUN apt update && apt install -y \
    bison                        \
    dvipng                       \
    flex                         \
    gawk                         \
    gforth                       \
    git                          \
    libqt4-dev                   \
    m4                           \
    make                         \
    mecab-ipadic-utf8            \
    netpbm                       \
    ocaml                        \
    parallel                     \
    python-dev                   \
    python-gd                    \
    python-lzma                  \
    python-mecab                 \
    python-serial                \
    qt4-qmake                    \
    sqlite3                      \
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

RUN git clone https://github.com/stephen-mw/wikireader.git /wikireader && \
    tar xvf required_packages.tgz && \
    cd packages && dpkg -i *

RUN make clean
