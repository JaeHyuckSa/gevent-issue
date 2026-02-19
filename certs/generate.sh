#!/bin/bash
set -e

CERTS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Generating self-signed TLS certificates..."

# CA
openssl genrsa -out "$CERTS_DIR/ca.key" 2048 2>/dev/null
openssl req -new -x509 -days 365 -key "$CERTS_DIR/ca.key" -out "$CERTS_DIR/ca.crt" \
  -subj "/CN=LocalCA" 2>/dev/null

# Server (RabbitMQ)
openssl genrsa -out "$CERTS_DIR/server.key" 2048 2>/dev/null
openssl req -new -key "$CERTS_DIR/server.key" -out "$CERTS_DIR/server.csr" \
  -subj "/CN=rabbitmq" 2>/dev/null
openssl x509 -req -in "$CERTS_DIR/server.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial -out "$CERTS_DIR/server.crt" -days 365 2>/dev/null

chmod 644 "$CERTS_DIR"/*.crt "$CERTS_DIR"/*.key
rm -f "$CERTS_DIR/server.csr" "$CERTS_DIR/ca.srl"

echo "Done. Files in $CERTS_DIR:"
ls -la "$CERTS_DIR"/*.{crt,key}
