#!/usr/bin/env bash

# adjust interfce if not named eth0
[ -f /etc/vault.d/server.hcl ] && {
  IFACE=`route -n | awk '$1 ~ "0.0.0.0" {print $8}'`
  CIDR=`ip addr show ${IFACE} | awk '$2 ~ "172.16.13" {print $2}'`
  IP=${CIDR%%/24}
  sed -i "s/EXTERNALIP/${IP}/g" /etc/vault.d/server.hcl
}

systemctl enable vault.service
systemctl start vault.service 2>/dev/null
