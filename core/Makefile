.PHONY: build

SHELL:=/bin/bash

build:
	docker build --rm --compress --no-cache -t stephenmw/wikireader_core:latest .

release: build
	docker push stephenmw/wikireader_core:latest
