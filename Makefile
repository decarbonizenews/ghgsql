# SPDX-License-Identifier: 0BSD

IMGNAME=ghgsql

all:
	docker build . -t $(IMGNAME) --progress=plain

run:
	docker run --rm -t -i -p 127.0.0.1:3306:3306 -p 127.0.0.1:80:80 $(IMGNAME)
