#!/bin/bash
# Run by docker-mailserver as it sets up a new container, never when the same
# container restarts. The Quadlet binds the host's trust store, as
# update-ca-trust extracts it, over the image's: its directory-hash as
# /etc/ssl/certs, and the directory holding it at the host's path. The bundle
# links there, ca-certificates.crt and ca-bundle.crt, point at
# ../tls-ca-bundle.pem, which this link leads to the host's bundle, as the
# host's own /etc/ssl/cert.pem does.
ln -sfn /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/tls-ca-bundle.pem
