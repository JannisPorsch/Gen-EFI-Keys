#!/bin/bash

PKG_EFITOOLS=$(pacman -Q | grep efitools)
if [ "" = "$PKG_EFITOOLS" ]; then
  sudo pacman -Sy efitools
fi

sudo mkdir -p /etc/efi-keys/
sudo chmod 777 /etc/efi-keys/
cd /etc/efi-keys
sudo uuidgen --random > GUID

# Platform Key:
sudo openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=Platform Key/" -out PK.crt
sudo openssl x509 -outform DER -in PK.crt -out PK.cer
sudo cert-to-efi-sig-list -g "$(< GUID)" PK.crt PK.esl
sudo sign-efi-sig-list -g "$(< GUID)" -k PK.key -c PK.crt PK PK.esl PK.auth
sudo sign-efi-sig-list -g "$(< GUID)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

# Key Exchange Key:
sudo openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=Key Exchange Key/" -out KEK.crt
sudo openssl x509 -outform DER -in KEK.crt -out KEK.cer
sudo cert-to-efi-sig-list -g "$(< GUID)" KEK.crt KEK.esl
sudo sign-efi-sig-list -g "$(< GUID)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

# Signature Database Key:
sudo openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=my Signature Database key/" -out db.crt
sudo openssl x509 -outform DER -in db.crt -out db.cer
sudo cert-to-efi-sig-list -g "$(< GUID)" db.crt db.esl
sudo sign-efi-sig-list -g "$(< GUID)" -k KEK.key -c KEK.crt db db.esl db.auth

sudo chmod 400 /etc/efi-keys/
sudo shred -fu GUID
echo "[*] generated efi keys in /etc/efi-keys/"
