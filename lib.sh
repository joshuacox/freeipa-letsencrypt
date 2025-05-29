do_roots () {
for CERT in "${CERTS[@]}"
do
  if command -v wget &> /dev/null
  then
    wget -O "/etc/ssl/$FQDN/$CERT" "https://letsencrypt.org/certs/$CERT"
  elif command -v curl &> /dev/null
  then
    curl -o "/etc/ssl/$FQDN/$CERT" "https://letsencrypt.org/certs/$CERT"
  fi
  ipa-cacert-manage install "/etc/ssl/$FQDN/$CERT"
done
}

do_intermediaries () {
  for CERT2 in "${CERTS2[@]}"
  do
    if command -v wget &> /dev/null
    then
      wget -O "/etc/ssl/$FQDN/$CERT2" "https://letsencrypt.org/certs/2024/$CERT2"
    elif command -v curl &> /dev/null
    then
      curl -o "/etc/ssl/$FQDN/$CERT2" "https://letsencrypt.org/certs/2024/$CERT2"
    fi
    ipa-cacert-manage install "/etc/ssl/$FQDN/$CERT2"
  done
}

check_dirman () {
  DIRMAN_PASSWORD_PATH=.dirman-password
  if [[ -f "${DIRMAN_PASSWORD_PATH}" ]]; then
    DIRMAN_PASSWORD=$(cat "${DIRMAN_PASSWORD_PATH}"|tail -n1)
  else
	  read -p "Enter DIRMAN_PASSWORD: " DIRMAN_PASSWORD
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
