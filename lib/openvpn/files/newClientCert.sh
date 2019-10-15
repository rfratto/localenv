#!/bin/bash
EASY_RSA_LOC="/etc/openvpn/certs"
cd $EASY_RSA_LOC
MY_IP_ADDR="$2"
./easyrsa build-client-full $1 nopass

cat >${EASY_RSA_LOC}/pki/$1.ovpn <<EOF
client
nobind
dev tun
remote ${MY_IP_ADDR} 443 tcp
<key>
`cat ${EASY_RSA_LOC}/pki/private/$1.key`
</key>
<cert>
`cat ${EASY_RSA_LOC}/pki/issued/$1.crt`
</cert>
<ca>
`cat ${EASY_RSA_LOC}/pki/ca.crt`
</ca>
EOF

cat pki/$1.ovpn
