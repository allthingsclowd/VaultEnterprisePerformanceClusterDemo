# Vault DC to DC Performance Cluster How-to

## description

This projects uses LXD to create containers.
To virtual boxes are created each with the one of following configurations to represent a DC

DC01
```
# lxc list
+---------+---------+---------------------+------+------------+-----------+
|  NAME   |  STATE  |        IPV4         | IPV6 |    TYPE    | SNAPSHOTS |
+---------+---------+---------------------+------+------------+-----------+
| base    | STOPPED |                     |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul1 | RUNNING | 10.170.13.11 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul2 | RUNNING | 10.170.13.12 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul3 | RUNNING | 10.170.13.13 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault1  | RUNNING | 10.170.13.21 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault2  | RUNNING | 10.170.13.22 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault3  | RUNNING | 10.170.13.23 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
# 
```

DC02
``` bash
lxc list
+---------+---------+---------------------+------+------------+-----------+
|  NAME   |  STATE  |        IPV4         | IPV6 |    TYPE    | SNAPSHOTS |
+---------+---------+---------------------+------+------------+-----------+
| base    | STOPPED |                     |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul1 | RUNNING | 172.16.13.11 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul2 | RUNNING | 172.16.13.12 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| consul3 | RUNNING | 172.16.13.13 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault1  | RUNNING | 172.16.13.21 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault2  | RUNNING | 172.16.13.22 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
| vault3  | RUNNING | 172.16.13.23 (eth0) |      | PERSISTENT | 0         |
+---------+---------+---------------------+------+------------+-----------+
```

__Networking__
The host nodes DC01 and DC02 have static routes applied to route the traffic between to two vault networks
DC01
`ip route add 172.16.13.0/24 via 192.168.2.17 src 192.168.2.10`

DC02
`ip route add 10.170.13.0/24 via 192.168.2.10 src 192.168.2.17`

__ Vault Server.HCL __

``` hcl
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
 address     = "127.0.0.1:8200"
 tls_disable = 1
}

listener "tcp" {
 address     = "EXTERNALIP:8200"
 tls_disable = 1
}

default_lease_ttl = "168h"
max_lease_ttl = "720h"
plugin_directory = "/usr/local/vault/plugins"
disable_mlock = true
api_addr = "http://EXTERNALIP:8200"
cluster_addr = "http://EXTERNALIP:8201"
ui = true
```

_Note_: SSL disabled - this should be enabled in a production environment

# how to use

## local development on your laptop
```bash
grahams-mbp:vault-cluster grazzer$
```
`vagrant up`

## Build DC01 Vault Cluster

`vagrant ssh dc01`

```bash 
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc01:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator init -t 1 -n 1`

``` bash
Unseal Key 1: PONh5OxceWj6rRguNg6kKnRaYtv57bkfRv/JEciiDYs=

Initial Root Token: 5IvSBvJWqgNuZb9wllT4v6cL

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.

```
`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-8bfd6f91
Cluster ID             58d0be74-3910-89f1-e702-d71e8e249c28
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
```

`exit`

## Build DC02 Vault Cluster

```bash
vagrant@dc01:~$
```

`lxc exec vault2 bash`

``` bash
root@vault2:~#
```

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-8bfd6f91
Cluster ID             58d0be74-3910-89f1-e702-d71e8e249c28
HA Enabled             true
HA Cluster             https://10.170.13.21:8201
HA Mode                standby
Active Node Address    http://10.170.13.21:8200
```

`exit`

```bash
vagrant@dc01:~$
```

`lxc exec vault3 bash`

``` bash
root@vault3:~#
```

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-8bfd6f91
Cluster ID             58d0be74-3910-89f1-e702-d71e8e249c28
HA Enabled             true
HA Cluster             https://10.170.13.21:8201
HA Mode                standby
Active Node Address    http://10.170.13.21:8200
```

`exit`
`exit`
`vagrant ssh dc02`

``` bash
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc02:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator init -n 1 -t 1`

``` bash
Unseal Key 1: 6BCuMCJgLMcRZSDyQ9UANrtqDk050TPcMe9MBUsYsTI=

Initial Root Token: 6mjYifwzvZtUiAFFZLTqWAgF

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-1372b7c1
Cluster ID             ec4787f9-9e29-e90e-dd93-84e98d2457ec
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>
```

`exit`

`lxc exec vault2 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-1372b7c1
Cluster ID             ec4787f9-9e29-e90e-dd93-84e98d2457ec
HA Enabled             true
HA Cluster             https://172.16.13.21:8201
HA Mode                standby
Active Node Address    http://172.16.13.21:8200
```

`exit`

`lxc exec vault3 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`vault operator unseal`

``` bash
Unseal Key (will be hidden):
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                0.11.5+prem
Cluster Name           vault-cluster-1372b7c1
Cluster ID             ec4787f9-9e29-e90e-dd93-84e98d2457ec
HA Enabled             true
HA Cluster             https://172.16.13.21:8201
HA Mode                standby
Active Node Address    http://172.16.13.21:8200
```

## Verify connectivity between clusters

From Vault1 in DC01

``` bash
root@vault1:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:a7:e3:9c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.170.13.21/24 brd 10.170.13.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::216:3eff:fea7:e39c/64 scope link
       valid_lft forever preferred_lft forever
root@vault1:~# ping 172.16.13.21
PING 172.16.13.21 (172.16.13.21) 56(84) bytes of data.
64 bytes from 172.16.13.21: icmp_seq=1 ttl=62 time=0.524 ms
64 bytes from 172.16.13.21: icmp_seq=2 ttl=62 time=0.839 ms
64 bytes from 172.16.13.21: icmp_seq=3 ttl=62 time=0.751 ms
64 bytes from 172.16.13.21: icmp_seq=4 ttl=62 time=0.566 ms
```

From Vault1 in DC02

``` bash
root@vault1:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
12: eth0@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:48:c8:68 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.16.13.21/24 brd 172.16.13.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::216:3eff:fe48:c868/64 scope link
       valid_lft forever preferred_lft forever
root@vault1:~# ping 10.170.13.21
PING 10.170.13.21 (10.170.13.21) 56(84) bytes of data.
64 bytes from 10.170.13.21: icmp_seq=1 ttl=62 time=0.942 ms
64 bytes from 10.170.13.21: icmp_seq=2 ttl=62 time=0.632 ms
64 bytes from 10.170.13.21: icmp_seq=3 ttl=62 time=0.453 ms
64 bytes from 10.170.13.21: icmp_seq=4 ttl=62 time=0.856 ms
```

## Configure DC01 as the Primary Performance Replication Cluster

`vagrant ssh dc01`

```bash 
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc01:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`export VAULT_TOKEN=5IvSBvJWqgNuZb9wllT4v6cL`

`vault write -f sys/replication/performance/primary/enable`

``` bash
WARNING! The following warnings were returned from Vault:

  * This cluster is being enabled as a primary for replication. Vault will be
  unavailable for a brief period and will resume service shortly.
```
`vault write sys/replication/performance/primary/secondary-token id=mySpecialBootStrappingToken`

``` bash
Key                              Value
---                              -----
wrapping_token:                  eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJhZGRyIjoiaHR0cDovLzEwLjE3MC4xMy4yMTo4MjAwIiwiZXhwIjoxNTQ0MDExMDAwLCJpYXQiOjE1NDQwMDkyMDAsImp0aSI6IjNYenExOXQzb1Eyd1VRd1JWTlBNaXcxTSIsInR5cGUiOiJ3cmFwcGluZyJ9.MIGHAkIBISpHLw8aIhp-VqMrYQkkSdaJRpZV1kuMyhZeRRjjVUCvRW_prC4OpdZa2SK6cVU4rAAP2CkuYFSnBNiFloxJ_IQCQRnrt-WgDAm185y21CbalQl-3gdMj7D1qzJ12mwNFpyNEYgJbRd-JHF9ifovrCjUjBCcL9jxjdEi_amP7jpV7qxB
wrapping_accessor:               4VmMvWejiThuTwv05TyEMTRP
wrapping_token_ttl:              30m
wrapping_token_creation_time:    2018-12-05 11:26:40.060333161 +0000 UTC
wrapping_token_creation_path:    sys/replication/performance/primary/secondary-token
```

## Configure DC02 as the Secondary Performance Replication Cluster

`vagrant ssh dc02`

```bash 
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc02:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`export VAULT_TOKEN=6mjYifwzvZtUiAFFZLTqWAgF`

`vault write sys/replication/performance/secondary/enable token=eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9.eyJhZGRyIjoiaHR0cDovLzEwLjE3MC4xMy4yMTo4MjAwIiwiZXhwIjoxNTQ0MDExMDAwLCJpYXQiOjE1NDQwMDkyMDAsImp0aSI6IjNYenExOXQzb1Eyd1VRd1JWTlBNaXcxTSIsInR5cGUiOiJ3cmFwcGluZyJ9.MIGHAkIBISpHLw8aIhp-VqMrYQkkSdaJRpZV1kuMyhZeRRjjVUCvRW_prC4OpdZa2SK6cVU4rAAP2CkuYFSnBNiFloxJ_IQCQRnrt-WgDAm185y21CbalQl-3gdMj7D1qzJ12mwNFpyNEYgJbRd-JHF9ifovrCjUjBCcL9jxjdEi_amP7jpV7qxB`

``` bash 
WARNING! The following warnings were returned from Vault:

  * Vault has succesfully found secondary information; it may take a while to
  perform setup tasks. Vault will be unavailable until these tasks and initial
  sync complete.

```

## DC01 - add test data to cluster in DC01

`vagrant ssh dc01`

``` bash
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc01:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`export VAULT_TOKEN=5IvSBvJWqgNuZb9wllT4v6cL`

`vault secrets enable -address=http://127.0.0.1:8200 -version=1 kv`

``` bash
Success! Enabled the kv secrets engine at: kv/
```

`vault kv put secret/hello foo=world`

``` bash
Success! Data written to: secret/hello
```

## DC02 - read test data from local cluster

`vagrant ssh dc02`

``` bash
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

vagrant@dc02:~$
```

`lxc exec vault1 bash`

`export VAULT_ADDR=http://127.0.0.1:8200`

`export VAULT_TOKEN=6mjYifwzvZtUiAFFZLTqWAgF`

`vault kv get secret/hello`

``` bash
Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret/hello
Code: 403. Errors:

* permission denied
```

_NOTE_: When you activate a secondary for replication, its storage is wiped clear including its unseal key and recovery keys. During bootstrapping, it auto-unseals using the primary cluster’s original unseal key.

If you want to generate a root token on a secondary replication cluster, you need to use the generate-root command:

https://www.vaultproject.io/guides/generate-root.html


### Generate Root

`vault operator generate-root -generate-otp`

``` bash
L6Lzzq45n9vXnl2PN94Wo4Ne
```

`vault operator generate-root -init -otp=L6Lzzq45n9vXnl2PN94Wo4Ne`

``` bash
Nonce         1e8eacb1-e027-28f9-c096-062aae3bf31d
Started       true
Progress      0/1
Complete      false
OTP Length    24
```

`vault operator generate-root`

_Note_: Ensure to use the unseal key that belongs to the primary cluster

``` bash
Operation nonce: 1e8eacb1-e027-28f9-c096-062aae3bf31d
Unseal Key (will be hidden):
Nonce            1e8eacb1-e027-28f9-c096-062aae3bf31d
Started          true
Progress         1/1
Complete         true
Encoded Token    emQoTygLX3w4SSERBA1naHxKXTg3BiMP
```

`vault operator generate-root \
    -decode=emQoTygLX3w4SSERBA1naHxKXTg3BiMP \
    -otp=L6Lzzq45n9vXnl2PN94Wo4Ne`

``` bash
6Rd5RzkIVpWIjaU82sioX2mj
```

Now using this new root token the data should be accessable

`export VAULT_ADDR=6Rd5RzkIVpWIjaU82sioX2mj`

`vault kv get secret/hello`

``` bash
=== Data ===
Key    Value
---    -----
foo    world
```


