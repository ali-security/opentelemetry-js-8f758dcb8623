#!/usr/bin/env sh
#
# Usage: regenerate.sh
#
# regenerate.sh regenerates certificates that are used to test gRPC with TLS
# Make sure you run it in test/certs directory.
# It also serves as a documentation on how existing certificates were generated.
#
# Notes:
#  * Certificates are issued for 36500 days (~100 years) so they never expire
#    and turn into a CI time bomb the way the original 365-day ones did.
#  * Keys are generated unencrypted (no -des3 / no `openssl rsa` post-pass):
#    OpenSSL 3.x would otherwise prompt for a passphrase and wedge CI.
#  * subjectAltName is supplied at *signing* time via -extfile, because
#    `openssl x509 -req` does not copy extensions from the CSR and modern
#    Node.js no longer falls back to matching CN=localhost.

set -e

rm -f ca.crt ca.key client.crt client.csr client.key server.crt server.csr server.key

# Extensions applied when signing the leaf certificates.
EXTFILE="$(mktemp)"
trap 'rm -f "$EXTFILE"' EXIT
echo "subjectAltName=DNS:localhost,IP:127.0.0.1" > "$EXTFILE"

openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/C=CL/ST=RM/L=OpenTelemetryTest/O=Root/OU=Test/CN=ca"

openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/C=CL/ST=RM/L=OpenTelemetryTest/O=Test/OU=Server/CN=localhost"
openssl x509 -req -days 36500 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -extfile "$EXTFILE" -out server.crt

openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/C=CL/ST=RM/L=OpenTelemetryTest/O=Test/OU=Client/CN=localhost"
openssl x509 -req -days 36500 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -extfile "$EXTFILE" -out client.crt
