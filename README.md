WARNING: these scripts were created for use by the freeIPA demo server. They no longer work. Continued use is not recommended.

These two scripts try to automatically obtain and install Let's Encrypt certs
to FreeIPA web interface.

To use it, do this:
* BACKUP /var/lib/ipa/certs/ and /var/lib/ipa/private/ to some safe place (it contains private keys!)
* clone/unpack all scripts somewhere
* cp example.env .env
* set EMAIL variable in .env
* set other variables in .env
* run grab-cert-le.sh script once to grab the certificate from LE 
* run setup-le.sh script once to prepare the machine. These two scripts will:
  * install Let's Encrypt client package
  * install Let's Encrypt CA certificates into FreeIPA certificate store
  * requests new certificate for FreeIPA web interface
* run renew-le.sh script once a day: it will renew the cert as necessary


If you have any problem, feel free to contact FreeIPA team:
http://www.freeipa.org/page/Contribute#Communication
