# SPDX-License-Identifier: 0BSD

all:
	docker build . -t ghgsql

run:
	docker run -p 3306:3306 -p 80:80 ghgsql
