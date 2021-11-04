#!/bin/bash

PATH_PRIVATE=/root/strongswan/private
PATH_CACERTS=/root/strongswan/cacerts
PATH_CERTS=/root/strongswan/certs



if [ $1 ];	then
	CN=$1
	echo "generating keys for $CN ..."
else
	echo "usage:\n sh server_key.sh YOUR EXACT HOST NAME or SERVER IP\n Run this script in directory to store your keys"
	exit 1
fi

mkdir -p $PATH_PRIVATE && mkdir -p $PATH_CACERTS && mkdir -p $PATH_CERTS

strongswan pki --gen --type rsa --size 4096 --outform pem > $PATH_PRIVATE/strongswanKey.pem
strongswan pki --self --ca --lifetime 5000 --in $PATH_PRIVATE/strongswanKey.pem --type rsa --dn "C=CH, O=Pentaloop, CN=$CN" --outform pem > $PATH_CACERTS/strongswanCert.pem
echo 'CA certs at $PATH_CACERTS/strongswanCert.pem\n'
strongswan pki --print --in $PATH_CACERTS/strongswanCert.pem


sleep 1
echo "\ngenerating server keys ..."
strongswan pki --gen --type rsa --size 2048 --outform pem > $PATH_PRIVATE/vpnHostKey.pem
strongswan pki --pub --in $PATH_PRIVATE/vpnHostKey.pem --type rsa | \
	strongswan pki --issue --lifetime 5000 \
	--cacert $PATH_CACERTS/strongswanCert.pem \
	--cakey $PATH_PRIVATE/strongswanKey.pem \
	--dn "C=CH, O=Pentaloop, CN=$CN" \
	--san $CN \
	--flag serverAuth --flag ikeIntermediate \
	--outform pem > $PATH_CERTS/vpnHostCert.pem
echo "vpn server cert at certs/vpnHostCert.pem\n"
strongswan pki --print --in $PATH_CERTS/vpnHostCert.pem
