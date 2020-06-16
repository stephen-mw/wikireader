FROM stephenmw/wikireader_core:latest

WORKDIR /wikireader
RUN git clone https://github.com/stephen-mw/wikireader.git /wikireader
