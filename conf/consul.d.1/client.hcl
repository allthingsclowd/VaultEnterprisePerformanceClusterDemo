{
  "server": false,
  "ui": false,
  "advertise_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "bind_addr": "0.0.0.0",
  "data_dir": "/usr/local/consul",
  "retry_join": [
    "172.16.13.11",
    "172.16.13.12",
    "172.16.13.13"
  ]
}
