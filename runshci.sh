#!/bin/bash
# SPDX-License-Identifier: 0BSD
# last update: 2026-02-11
# https://github.com/hannob/codingstyle
set -euo pipefail

shfiles=$(grep -rl --exclude-dir=.git '^#!/bin/bash\|^#!/bin/sh' .)

shfmt --diff $shfiles
