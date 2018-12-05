#!/usr/bin/env bash

## BEGIN of customization

# versions
CONSUL=1.4.0
CONSUL_TEMPLATE=0.19.5
VAULT=0.11.5
NOMAD=0.8.6
HTTPECHO=0.2.3

## END of customization

# if we are in a vagrant box, lets cd into /vagrant
[ -d /vagrant ] && pushd /vagrant

# install and configure lxd
which lxd &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  cat conf/selection.conf | debconf-set-selections
  apt-get install --no-install-recommends -y vim lxd
  DEBCONF_DB_OVERRIDE='File {conf/config.dat}' dpkg-reconfigure -fnoninteractive -pmedium lxd
  cp conf/lxd-bridge /etc/default/lxd-bridge
  cp conf/dns.conf /etc/default/dns.conf
  service lxd restart
  service lxd-bridge restart
}

# create base container
lxc info base &>/dev/null || {
  lxc launch ubuntu:16.04 base -c security.nesting=true
  echo sleeping so base get an IP
  sleep 8
  mkdir -p /var/lib/lxd/containers/base/rootfs/etc/dpkg/dpkg.cfg.d/
  cp conf/01_nodoc /var/lib/lxd/containers/base/rootfs/etc/dpkg/dpkg.cfg.d/01_nodoc
  # copy in vault enterprise binary
  cp hsm/vault-enterprise_0.11.5+prem_linux_amd64.zip /var/lib/lxd/containers/base/rootfs/tmp/vault.zip
  lxc exec base -- apt-get update
  lxc exec base -- apt-get install --no-install-recommends -y wget unzip libltdl7 
  lxc exec base -- apt-get clean

  # /tmp cleans on each boot
  lxc exec base -- wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_amd64.zip
  lxc exec base -- unzip -d /usr/local/bin /tmp/consul.zip

  #lxc exec base -- wget -O /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT}/vault_${VAULT}_linux_amd64.zip
  lxc exec base -- unzip -d /usr/local/bin /tmp/vault.zip

  lxc exec base -- wget -O /tmp/nomad.zip https://releases.hashicorp.com/nomad/${NOMAD}/nomad_${NOMAD}_linux_amd64.zip
  lxc exec base -- unzip -d /usr/local/bin /tmp/nomad.zip

  lxc exec base -- wget -O /tmp/http-echo.zip https://github.com/hashicorp/http-echo/releases/download/v${HTTPECHO}/http-echo_${HTTPECHO}_linux_amd64.zip
  lxc exec base -- unzip -d /usr/local/bin /tmp/http-echo.zip

  lxc stop base
  lxc config set base security.privileged true
}

# copy scripts to all existing nodes
for d in /var/lib/lxd/containers/*/rootfs/var/tmp; do
  cp scripts/consul.sh ${d}
  cp scripts/nomad.sh ${d}
  cp scripts/vault.sh ${d}
done

# # base-client
# s=base-client
# lxc info ${s} &>/dev/null || {
#   echo "copying base into ${s}"
#   lxc copy base ${s}
#   lxc start ${s}
#   echo sleeping so ${s} get an IP
#   sleep 8
#   lxc exec ${s} -- apt-get update
#   lxc exec ${s} -- apt-get install --no-install-recommends -y docker.io
#   lxc exec ${s} -- apt-get install --no-install-recommends -y default-jre
#   lxc exec ${s} -- apt-get clean
#   lxc exec ${s} -- docker run hello-world &>/dev/null && echo docker hello-world works
#   lxc stop base-client
# } & #background

# create consul
for s in consul{1..3}; do
  lxc info ${s} &>/dev/null || {
    echo "copying base into ${s}"
    lxc copy base ${s}
    lxc start ${s}
    echo sleeping so ${s} get an IP
    sleep 8

    # create dir and copy server.hcl for consul
    mkdir -p /var/lib/lxd/containers/${s}/rootfs/etc/consul.d
    cp conf/consul.d/server.hcl /var/lib/lxd/containers/${s}/rootfs/etc/consul.d
    cp conf/consul.service /var/lib/lxd/containers/${s}/rootfs/etc/systemd/system
    lxc exec ${s} -- bash /var/tmp/consul.sh
  } & # background
done

consul_client(){
  # create dir and copy client.hcl for consul
  mkdir -p /var/lib/lxd/containers/${s}/rootfs/etc/consul.d
  cp conf/consul.d/client.hcl /var/lib/lxd/containers/${s}/rootfs/etc/consul.d
  cp conf/consul.service /var/lib/lxd/containers/${s}/rootfs/etc/systemd/system
  lxc exec ${s} -- bash /var/tmp/consul.sh
}

# create vault cluster - wip
for s in vault{1..3}; do
  lxc info ${s} &>/dev/null || {
    echo "copying base into ${s}"
    lxc copy base ${s}
    lxc start ${s}
    echo sleeping so ${s} get an IP
    sleep 8

    consul_client

    # create dir and copy server.hcl for vault
    mkdir -p /var/lib/lxd/containers/${s}/rootfs/etc/vault.d
    cp conf/vault.d/server.hcl /var/lib/lxd/containers/${s}/rootfs/etc/vault.d
    cp conf/vault.service /var/lib/lxd/containers/${s}/rootfs/etc/systemd/system
    lxc exec ${s} -- bash /var/tmp/vault.sh
  }
done

# # create nomad
# for s in nomad{1..3}; do
#   lxc info ${s} &>/dev/null || {
#     echo "copying base into ${s}"
#     lxc copy base ${s}
#     lxc start ${s}
#     echo sleeping so ${s} get an IP
#     sleep 8

#     consul_client

#     # create dir and copy server.hcl for nomad
#     mkdir -p /var/lib/lxd/containers/${s}/rootfs/etc/nomad.d
#     cp conf/nomad.d/server.hcl /var/lib/lxd/containers/${s}/rootfs/etc/nomad.d
#     cp conf/nomad.service /var/lib/lxd/containers/${s}/rootfs/etc/systemd/system

#     lxc exec ${s} -- bash /var/tmp/nomad.sh
#   } & # background
# done

# install packages needed on the host
which haproxy nginx unzip wget &>/dev/null || {
  apt-get update
  apt-get install --no-install-recommends -y haproxy nginx unzip wget
}

# configure nginx to expose services
[ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default
service nginx restart

# configure haproxy to expose ui
cp conf/haproxy.cfg /etc/haproxy/haproxy.cfg
service haproxy restart

[ -f /usr/local/bin/consul-template ] || {
  wget -O /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE}/consul-template_${CONSUL_TEMPLATE}_linux_amd64.zip
  unzip -d /usr/local/bin /tmp/consul-template.zip
}

cp -ap conf/consul-template /etc/
cp conf/consul-template.service /etc/systemd/system/consul-template.service
systemctl enable consul-template.service
systemctl restart consul-template.service

wait  # wait for background processes to finish

# # clients
# for s in client{1..4}; do
#   lxc info ${s} &>/dev/null || {
#     echo "copying base-client into ${s}"
#     lxc copy base-client ${s}
#     lxc start ${s}
#     echo sleeping so ${s} get an IP
#     sleep 8

#     consul_client
       
#     # create dir and copy client.hcl for nomad
#     mkdir -p /var/lib/lxd/containers/${s}/rootfs/etc/nomad.d
#     cp conf/nomad.d/client.hcl /var/lib/lxd/containers/${s}/rootfs/etc/nomad.d
#     cp conf/nomad.service /var/lib/lxd/containers/${s}/rootfs/etc/systemd/system

#     lxc exec ${s} -- bash /var/tmp/nomad.sh
#   } & # background
# done
wait  # wait for background processes to finish
