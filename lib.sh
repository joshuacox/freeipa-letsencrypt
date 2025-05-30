#!/usr/bin/env bash

do_roots () {
  CERTS=("isrgrootx1.pem" "isrg-root-x2.pem")
  for CERT in "${CERTS[@]}"
  do
    if command -v wget &> /dev/null
    then
      wget -O "/etc/ssl/$FQDN/$CERT" "https://letsencrypt.org/certs/$CERT"
    elif command -v curl &> /dev/null
    then
      curl -o "/etc/ssl/$FQDN/$CERT" "https://letsencrypt.org/certs/$CERT"
    else
      echo 'no download command found'
      exit 1
    fi
    ipa-cacert-manage install "/etc/ssl/$FQDN/$CERT"
  done
}

do_intermediaries () {
  CERTS2=("e5.pem" "e6.pem" "e7.pem" "e8.pem" "e9.pem" "r10.pem" "r11.pem" "r12.pem" "r13.pem" "r14.pem")
  for CERT2 in "${CERTS2[@]}"
  do
    if command -v wget &> /dev/null
    then
      wget -O "/etc/ssl/$FQDN/$CERT2" "https://letsencrypt.org/certs/2024/$CERT2"
    elif command -v curl &> /dev/null
    then
      curl -o "/etc/ssl/$FQDN/$CERT2" "https://letsencrypt.org/certs/2024/$CERT2"
    else
      echo 'no download command found'
      exit 1
    fi
    ipa-cacert-manage install "/etc/ssl/$FQDN/$CERT2"
  done
}

check_dirman () {
  if [ ! -d "/etc/ssl/$FQDN" ]
  then
    mkdir -p "/etc/ssl/$FQDN"
  fi
  DIRMAN_PASSWORD_PATH=.dirman-password
  if [[ -f "${DIRMAN_PASSWORD_PATH}" ]]; then
    DIRMAN_PASSWORD=$(cat "${DIRMAN_PASSWORD_PATH}"|tail -n1)
  else
	  read -s -p "Enter DIRMAN_PASSWORD: " DIRMAN_PASSWORD
	  echo ''
	  read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	  echo -n "${DIRMAN_PASSWORD}" > "${DIRMAN_PASSWORD_PATH}"
  fi
}

ipa-server-certinstallrrr () {
  ipa-certupdate -v
  ipa-server-certinstall \
	  -w \
	  --dirman-password="${DIRMAN_PASSWORD}" \
	  -d /etc/letsencrypt/live/${FQDN}/privkey.pem /etc/letsencrypt/live/$FQDN/fullchain.pem \
	  --pin=''
  ipactl restart
}

check_reqs () {
  if ! type "certbot" > /dev/null; then
    echo "certbot was not found in your path, attempting to install now"
    dnf install letsencrypt -y
  fi
}

check_cert_age () {
	### cron
	# skip renewal if the cert is still valid for more than 30 days
	# comment out this line for the first run
	if [ "${1:-renew}" != "--first-time" ]
	then
		end_timestamp=`date +%s --date="$(openssl x509 -enddate -noout -in /var/lib/ipa/certs/httpd.crt | cut -d= -f2)"`
		now_timestamp=`date +%s`
		let diff=($end_timestamp-$now_timestamp)/86400
		if [ "$diff" -gt "30" ]; then
		  exit 0
		fi
	fi
}

stop_httpd_process () {
  # httpd process prevents letsencrypt from working, stop it
  if ! command -v service >/dev/null 2>&1; then
	  systemctl stop httpd
  else
	  service httpd stop
  fi
}

start_httpd_process () {
  # start httpd with the new cert
  if ! command -v service >/dev/null 2>&1; then
	  systemctl start httpd
  else
	  service httpd start
  fi
}

generate_CSR_deprecated () {
	# cert renewal is needed if we reached this line
	cd "$WORKDIR"
	# cleanup
	rm -f "$WORKDIR"/*.pem
	rm -f "$WORKDIR"/httpd-csr.*
	# generate CSR
	OPENSSL_PASSWD_FILE="/var/lib/ipa/passwds/$HOSTNAME-443-RSA"
	[ -f "$OPENSSL_PASSWD_FILE" ] && OPENSSL_EXTRA_ARGS="-passin file:$OPENSSL_PASSWD_FILE" || OPENSSL_EXTRA_ARGS=""
  TMP=$(mktemp -d)
  cat $WORKDIR/ipa-httpd.cnf |sed "s/server.example.test/$FQDN/g" > ${TMP}/ipa-httpd.cnf
	openssl req -new -sha256 -config "$${TMP}/ipa-httpd.cnf" -key /var/lib/ipa/private/httpd.key -out "$WORKDIR/httpd-csr.der" $OPENSSL_EXTRA_ARGS
  rm -Rf ${TMP}
  stop_httpd_process
  # get a new cert
  letsencrypt certonly --standalone --csr "$WORKDIR/httpd-csr.der" --email "$EMAIL" --agree-tos
  # replace the cert
  cp /var/lib/ipa/certs/httpd.crt /var/lib/ipa/certs/httpd.crt.bkp
  mv -f "$WORKDIR/0000_cert.pem" /var/lib/ipa/certs/httpd.crt
  restorecon -v /var/lib/ipa/certs/httpd.crt
  start_httpd_process
}

do_certbot_run () {
  stop_httpd_process

  certbot certonly \
  -m ${EMAIL} \
  --standalone \
  --agree-tos \
  -d "${THESE_DOMAINS}"

  start_httpd_process
}
