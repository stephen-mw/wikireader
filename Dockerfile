FROM ubuntu:precise

ADD apt.sources.list /etc/apt/sources.list
RUN echo 'Acquire::http::Proxy "http://10.10.10.10:3142";' > /etc/apt/apt.conf.d/02proxy
RUN apt-get update -y && apt-get install -y \
        openssh-server mg lynx bash-completion \
        git build-essential flex bison \
        xfonts-utils ocaml guile-2.0 gforth \
        sqlite3 qt4-qmake libqt4-dev \
        cjk-latex \
        php5-cli \
        dvipng \
        mecab-ipadic-utf8 \
        php5-sqlite php5-tidy \
        gawk \
        python-gd python-mecab python-lzma

# Set up the base board
RUN git clone https://github.com/wikireader/wikireader.git

WORKDIR wikireader

RUN make clean && make requirements

# There will be a binutils failure here
RUN make || true
RUN cp SavedCaches/config.cache-binutils-12.10 host-tools/binutils-2.10.1/build/config.cache

# There will be a gcc error here
RUN make || true
RUN cp SavedCaches/config.cache-gcc-12.10 host-tools/gcc-3.3.2/build/config.cache

# Should be good to go
RUN make

RUN echo "New app created: wiki/wiki.app"
