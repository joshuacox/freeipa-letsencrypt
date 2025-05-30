#!/usr/bin/bash
set -o nounset -o errexit
source .env
source lib.sh
WORKDIR=$(dirname "$(realpath $0)")

main () {
  check_dirman
  check_reqs
  check_cert_age
  #generate_CSR_deprecated
  certbot renew
  do_roots
  do_intermediaries 
  ipa-server-certinstallrrr
}

main
