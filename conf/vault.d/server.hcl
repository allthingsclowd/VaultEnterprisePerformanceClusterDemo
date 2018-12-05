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