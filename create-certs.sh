#!/usr/bin/env bash

export MSYS_NO_PATHCONV=1

set -o nounset \
    -o errexit
#    -o verbose
#    -o xtrace

echo -e "\n=> Generating Certificates, KeyStore and TrustStore..."

currentPath=$(dirname "$0")

[ -d ${currentPath}/secrets ] && rm -rf ${currentPath}/secrets
[ ! -d ${currentPath}/secrets ] && mkdir ${currentPath}/secrets
cd ${currentPath}/secrets

# Generate CA key
openssl req -new -x509 -keyout ca.key -out ca.crt -days 365 -subj "/CN=sample/OU=TEST/O=TEST/L=TEST/C=FR" -passin pass:confluent -passout pass:confluent

for i in kafka client schema-registry connect rest-proxy; do
    echo "------------------------------- ${i} -------------------------------"
    # Create host keystore
    keytool -genkey -noprompt \
        -alias ${i} \
        -dname "CN=${i},OU=TEST,O=TEST,L=TEST,C=FR" \
        -keystore kafka.${i}.keystore.jks \
        -keyalg RSA \
        -storepass confluent \
        -keypass confluent \

    # Create the certificate signing request (CSR)
    keytool -keystore kafka.${i}.keystore.jks -alias ${i} -certreq -file ${i}.csr -storepass confluent -keypass confluent

    echo "[SAN]" >> ${i}-extension.txt
    echo "subjectAltName=DNS:${i}" >> ${i}-extension.txt

    # Sign the host certificate with the certificate authority (CA)
    openssl x509 -req -CA ca.crt -CAkey ca.key -in ${i}.csr -out ${i}-ca1-signed.crt \
        -days 9999 -CAcreateserial -passin pass:confluent \
        -extensions SAN -extfile ${i}-extension.txt

    # Sign and import the CA cert into the keystore
    keytool -noprompt -keystore kafka.${i}.keystore.jks -alias CARoot -import -file ca.crt -storepass confluent -keypass confluent

    # Sign and import the host certificate into the keystore
    keytool -noprompt -keystore kafka.${i}.keystore.jks -alias ${i} -import -file ${i}-ca1-signed.crt -storepass confluent -keypass confluent

    # Create truststore and import the CA cert
    keytool -noprompt -keystore kafka.${i}.truststore.jks -alias CARoot -import -file ca.crt -storepass confluent -keypass confluent

        # Save creds
    # echo "confluent" >${i}_keystore_creds
    # echo "confluent" >${i}_truststore_creds

    rm ${i}.csr
    rm ${i}*.crt
    rm ${i}-extension.txt
done

rm ca.crt
rm ca.key
rm ca.srl
