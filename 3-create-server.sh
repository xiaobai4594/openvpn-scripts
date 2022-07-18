#!/bin/ash
# Generate TLS PSK
OVPN_PKI="/etc/easy-rsa/pki"
openvpn --genkey --secret ${OVPN_PKI}/tc.pem

# Configuration parameters
OVPN_DIR="/etc/openvpn"
OVPN_PKI="/etc/easy-rsa/pki"
OVPN_DEV="$(uci get firewall.lan.device | sed -e "s/^.*\s//")"
OVPN_PORT="$(uci get firewall.ovpn.dest_port)"
OVPN_PROTO="$(uci get firewall.ovpn.proto)"
OVPN_POOL="10.10.10.0 255.255.255.0"
OVPN_DNS="${OVPN_POOL%.* *}.1"
OVPN_DOMAIN="$(uci get dhcp.@dnsmasq[0].domain)"
OVPN_DH="$(cat ${OVPN_PKI}/dh.pem)"
OVPN_TC="$(sed -e "/^#/d;/^\w/N;s/\n//" ${OVPN_PKI}/tc.pem)"
OVPN_CA="$(openssl x509 -in ${OVPN_PKI}/ca.crt)"
NL=$'\n'

# Configure VPN server
umask u=rw,g=,o=
grep -l -r -e "TLS Web Server Auth" "${OVPN_PKI}/issued" \
| sed -e "s/^.*\///;s/\.\w*$//" \
| while read -r OVPN_ID
do
OVPN_CERT="$(openssl x509 -in ${OVPN_PKI}/issued/${OVPN_ID}.crt)"
OVPN_KEY="$(cat ${OVPN_PKI}/private/${OVPN_ID}.key)"
cat << EOF > ${OVPN_DIR}/${OVPN_ID}.conf
verb 3
user nobody
group nogroup
dev ${OVPN_DEV}
port ${OVPN_PORT}
proto ${OVPN_PROTO}
server ${OVPN_POOL}
log /var/log/openvpn.log
client-config-dir /etc/openvpn/client-config-dir
crl-verify /etc/easy-rsa/pki/crl.pem
topology subnet
client-to-client
keepalive 10 120
persist-tun
persist-key
push "dhcp-option DNS ${OVPN_DNS}"
push "dhcp-option DOMAIN ${OVPN_DOMAIN}"
push "redirect-gateway def1"
push "persist-tun"
push "persist-key"
<dh>${NL}${OVPN_DH}${NL}</dh>
<tls-crypt>${NL}${OVPN_TC}${NL}</tls-crypt>
<ca>${NL}${OVPN_CA}${NL}</ca>
<cert>${NL}${OVPN_CERT}${NL}</cert>
<key>${NL}${OVPN_KEY}${NL}</key>
EOF
done
mkdir /etc/openvpn/client-config-dir
/etc/init.d/openvpn restart
