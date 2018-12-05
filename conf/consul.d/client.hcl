{
  "server": false,
  "ui": false,
  "advertise_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "bind_addr": "0.0.0.0",
  "data_dir": "/usr/local/consul",
  "retry_join": [
    "10.170.13.11",
    "10.170.13.12",
    "10.170.13.13"
  ]
}
