# SPDX-License-Identifier: 0BSD

all:
	docker build . -t ghgsql --progress=plain

run:
	docker run -t -i -p 127.0.0.1:3306:3306 -p 127.0.0.1:80:80 ghgsql
