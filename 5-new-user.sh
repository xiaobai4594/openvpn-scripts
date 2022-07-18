#!/bin/sh
if [ -n "$1" ]; then
    USERNAME=$1
else
    echo "username is empty!"
    exit
fi

if [ -n "$2" ]; then
    IP=$2
else
    echo "ip is empty!"
    exit
fi

# Configuration parameters
export EASYRSA_PKI="/etc/easy-rsa/pki"

# Add one more client
easyrsa --batch build-client-full $USERNAME nopass

echo "# ${USERNAME} ${IP}">/etc/openvpn/client-config-dir/$USERNAME
echo ifconfig-push $IP 255.255.255.0 >>/etc/openvpn/client-config-dir/$USERNAME

# Add to Host List In http://10.251.251.251/cgi-bin/luci/admin/network/hosts
echo "config domain" >>/etc/config/dhcp
echo "        option name 'VPN-${USERNAME}'" >>/etc/config/dhcp
echo "        option ip '${IP}'" >>/etc/config/dhcp
echo "" >>/etc/config/dhcp


/etc/init.d/openvpn restart
