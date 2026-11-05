#!/bin/sh
# webhookd's hook, through its sudo rule: restarts docker-mailserver when its
# monitor reports it down.
exec /usr/bin/systemctl restart mailserver.service
