#!/bin/sh
# SPDX-License-Identifier: 0BSD

mysqld --user=root &

echo "\$cfg['blowfish_secret'] ='$(head -c 20 /dev/urandom | base64)';" >>/var/www/html/config.inc.php
apachectl -D FOREGROUND
