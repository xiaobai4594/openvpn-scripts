#!/bin/sh
# Configuration parameters
export EASYRSA_PKI="/etc/easy-rsa/pki"
export EASYRSA_REQ_CN="ovpnca"

# Remove and re-initialize the PKI directory
easyrsa --batch init-pki

# Generate DH parameters
# 此步会较久
easyrsa --batch gen-dh

# Create a new CA
easyrsa --batch build-ca nopass

# Generate a keypair and sign locally for a server
easyrsa --batch build-server-full server nopass

# Generate a keypair and sign locally for a client
easyrsa --batch build-client-full client nopass
# Generate a crl list
easyrsa gen-crl
