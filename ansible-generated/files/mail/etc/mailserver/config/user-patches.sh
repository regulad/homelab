#!/bin/bash
# Copy CA cert to system trust store
cp /tmp/docker-mailserver/ipa-ca.crt /usr/local/share/ca-certificates/ipa-ca.crt
# Update CA certificates
update-ca-certificates
