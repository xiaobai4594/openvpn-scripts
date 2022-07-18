#!/bin/sh

OVPN_SERV="cyintranet.chiyi.tech"

# Configuration parameters
OUT_DIR="/mnt/sdb1/openvpn-clients"
OVPN_PKI="/etc/easy-rsa/pki"
OVPN_DEV="$(uci get firewall.lan.device | sed -e "s/^.*\s//")"
OVPN_PORT="$(uci get firewall.ovpn.dest_port)"
OVPN_PROTO="$(uci get firewall.ovpn.proto)"
OVPN_TC="$(sed -e "/^#/d;/^\w/N;s/\n//" ${OVPN_PKI}/tc.pem)"
OVPN_CA="$(openssl x509 -in ${OVPN_PKI}/ca.crt)"
NL=$'\n'

# Generate ca & crl chain
cat ${OVPN_PKI}/ca.crt > ${OVPN_PKI}/ca-crl.pem
cat ${OVPN_PKI}/crl.pem >> ${OVPN_PKI}/ca-crl.pem

# Generate VPN client profiles
umask u=rw,g=,o=
grep -l -r -e "TLS Web Client Auth" "${OVPN_PKI}/issued" \
| sed -e "s/^.*\///;s/\.\w*$//" \
| while read -r OVPN_ID
do
openssl verify -crl_check -CAfile ${OVPN_PKI}/ca-crl.pem ${OVPN_PKI}/issued/${OVPN_ID}.crt
if [ $? -ne 0 ]; then
    continue
fi
OVPN_CERT="$(openssl x509 -in ${OVPN_PKI}/issued/${OVPN_ID}.crt)"
OVPN_KEY="$(cat ${OVPN_PKI}/private/${OVPN_ID}.key)"
cat << EOF > ${OUT_DIR}/${OVPN_ID}.ovpn
verb 3
dev ${OVPN_DEV%%[0-9]*}
nobind
client
remote ${OVPN_SERV} ${OVPN_PORT} ${OVPN_PROTO}
auth-nocache
remote-cert-tls server
<tls-crypt>${NL}${OVPN_TC}${NL}</tls-crypt>
<ca>${NL}${OVPN_CA}${NL}</ca>
<cert>${NL}${OVPN_CERT}${NL}</cert>
<key>${NL}${OVPN_KEY}${NL}</key>
EOF
done
echo ---
ls -liah ${OUT_DIR}/*.ovpn
