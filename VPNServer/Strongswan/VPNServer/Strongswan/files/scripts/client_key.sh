#!/bin/bash
info="usage:\n sh client_key.sh USER_NAME EMAIL \n Run this script in directory to store your keys"


PATH_PRIVATE=/root/strongswan/private
PATH_CACERTS=/root/strongswan/cacerts
PATH_CERTS=/root/strongswan/certs

if [ $1 ];	then
	if [ $2 ]; then
		NAME=$1
		MAIL=$2
		echo "generating keys for $NAME $MAIL ..."
	else
		echo $info
		exit 1
	fi
else
	echo $info
	exit 1
fi

mkdir -p $PATH_PRIVATE && mkdir -p $PATH_CACERTS && mkdir -p $PATH_CERTS

keyfile="$PATH_PRIVATE/"$NAME"Key.pem"

certfile="$PATH_CERTS/"$NAME"Cert.pem"

p12file=$NAME".p12"

strongswan pki --gen --type rsa --size 2048 \
	--outform pem \
	> $keyfile


strongswan pki --pub --in $keyfile --type rsa | \
	strongswan pki --issue --lifetime 5000 \
	--cacert $PATH_CACERTS/strongswanCert.pem \
	--cakey $PATH_PRIVATE/strongswanKey.pem \
	--dn "C=CH, O=VULTR-VPS-CENTOS, CN=$MAIL" \
	--san $MAIL \
	--outform pem > $certfile

strongswan pki --print --in $certfile

#echo "\nEnter password to protect p12 cert for $NAME"
#openssl pkcs12 -export -inkey $keyfile \
#	-in $certfile -name "$NAME's VPN Certificate" \
#	-certfile $PATH_CACERTS/strongswanCert.pem \
#	-caname "strongSwan Root CA" \
#	-out $p12file


#if [ $? -eq 0 ]; then
#	echo "cert for $NAME at $p12file"
#fi
