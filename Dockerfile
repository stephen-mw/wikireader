FROM stephenmw/wikireader_core:latest

WORKDIR /wikireader
RUN cd /wikireader && git pull
ENV PATH="/wikireader/scripts:${PATH}"
