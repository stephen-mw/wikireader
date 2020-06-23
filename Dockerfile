FROM stephenmw/wikireader_core:latest

WORKDIR /wikireader
RUN mv /wikireader/host-tools/toolchain-install /tmp/tool_backup
RUN rm -rf /wikireader
RUN git clone https://github.com/stephen-mw/wikireader.git /wikireader

# Restore pre-built tools
RUN ln -sf /host-tools/toolchain-install /wikireader/host-tools/toolchain-install
