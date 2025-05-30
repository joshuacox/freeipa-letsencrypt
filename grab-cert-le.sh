#!/usr/bin/bash
set -o nounset -o errexit
source .env
source lib.sh
WORKDIR=$(dirname "$(realpath $0)")

check_reqs

do_certbot_run
