#!/bin/sh

SERVER=$1
PORT=443
DELAY=1
client_ciphers=$(openssl ciphers ALL | tr ':' '\n')
client_cipher_count=$(echo "$client_ciphers" | wc -l | sed 's/ //g')
server_ciphers=""
openssl_bin=$(which openssl)

if [ -z "$SERVER" ]; then
    echo "First parameter needs to be server name!"
    exit 1
fi

echo Using: $openssl_bin

echo Testing the following ciphers:
echo "$client_ciphers"

i=1
for cipher in $client_ciphers; do
    echo Testing $i of $client_cipher_count
    i=$(echo $i + 1 | bc)
    result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER:$PORT 2>&1 | egrep '^ *Cipher *: *' | grep $cipher)
    if [ -n "$result" ]; then
        server_ciphers="$server_ciphers\n$cipher"
    fi
    sleep $DELAY
done

echo The following ciphers are supported:
echo "$server_ciphers"
