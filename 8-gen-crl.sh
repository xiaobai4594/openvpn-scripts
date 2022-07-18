#!/bin/sh

# Configuration parameters
export EASYRSA_PKI="/etc/easy-rsa/pki"
easyrsa gen-crl
