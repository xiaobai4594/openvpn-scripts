#!/bin/sh
if [ -n "$1" ]; then
    USERNAME=$1
else
    echo "username is empty!"
    exit
fi

# Configuration parameters
export EASYRSA_PKI="/etc/easy-rsa/pki"

# Add one more client
easyrsa revoke $USERNAME

easyrsa gen-crl
