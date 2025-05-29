#!/usr/bin/bash
set -o nounset -o errexit
source .env
WORKDIR=$(dirname "$(realpath $0)")
CERTS=("isrgrootx1.pem" "isrg-root-x2.pem")
CERTS2=("e5.pem" "e6.pem" "e7.pem" "e8.pem" "e9.pem" "r10.pem" "r11.pem" "r12.pem" "r13.pem" "r14.pem")
source lib.sh
check_dirman

main () {
  sed -i "s/server.example.test/$FQDN/g" $WORKDIR/ipa-httpd.cnf

  dnf install letsencrypt -y

  if [ ! -d "/etc/ssl/$FQDN" ]
  then
    mkdir -p "/etc/ssl/$FQDN"
  fi

  do_roots
  do_intermediaries 
  ipa-server-certinstallrrr
}

main 
#"$WORKDIR/renew-le.sh" --first-time
