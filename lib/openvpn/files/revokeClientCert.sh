#!/bin/bash
EASY_RSA_LOC="/etc/openvpn/certs"
cd $EASY_RSA_LOC
./easyrsa revoke $1
./easyrsa gen-crl
cp ${EASY_RSA_LOC}/pki/crl.pem ${EASY_RSA_LOC}
chmod 644 ${EASY_RSA_LOC}/crl.pem
