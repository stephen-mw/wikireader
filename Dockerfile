# This will probably work on other distros, but some of the package names have
# changed.
FROM ubuntu:xenial

RUN apt-get update -y && apt-get install -y \
        openssh-server mg lynx bash-completion \
        git build-essential flex bison \
        xfonts-utils ocaml guile-2.0 gforth \
        sqlite3 qt4-qmake libqt4-dev \
        cjk-latex \
        php-cli \
        dvipng \
        mecab-ipadic-utf8 \
        php-sqlite3 php-tidy \
        gawk \
        python-gd \
        python-mecab \
        python-lzma \
        vim strace # for debugging

WORKDIR wikireader
ADD . /wikireader

# There will be a binutils failure here
RUN make clean && make requirements && make || true
RUN cp SavedCaches/config.cache-binutils-12.10 host-tools/binutils-2.10.1/build/config.cache

# There will be a gcc error here
RUN make || true
RUN cp SavedCaches/config.cache-gcc-12.10 host-tools/gcc-3.3.2/build/config.cache

# Should be good to go
RUN make
