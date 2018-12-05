info = <<-'EOF'


Vault root token is changeme

Then you can reach the services at

consul http://localhost:8500
nomad http://localhost:4646
vault http://localhost:8200

Or you can also use:

consul http://consul.127.0.0.1.xip.io:8000
nomad http://nomad.127.0.0.1.xip.io:8000
vault http://vault.127.0.0.1.xip.io:8000

EOF

Vagrant.configure("2") do |config|
  config.vm.box = "alvaro/xenial64"

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
  end

  config.vm.define "dc01" do |dc01|
      dc01.vm.hostname = "dc01"
      dc01.vm.network "forwarded_port", guest: 8000, host: 8000
      dc01.vm.network "forwarded_port", guest: 8080, host: 8080
      dc01.vm.network "forwarded_port", guest: 4646, host: 4646
      dc01.vm.network "forwarded_port", guest: 8200, host: 8200
      dc01.vm.network "forwarded_port", guest: 8500, host: 8500
      dc01.vm.network "private_network", ip: "192.168.2.10"
      dc01.vm.provision "shell", path: "scripts/provision.sh"
      dc01.vm.provision "shell", path: "scripts/configure_static_routes.sh"
  end

  config.vm.define "dc02" do |dc02|
      dc02.vm.hostname = "dc02"
      dc02.vm.network "forwarded_port", guest: 8000, host: 8007
      dc02.vm.network "forwarded_port", guest: 8080, host: 8087
      dc02.vm.network "forwarded_port", guest: 4646, host: 4647
      dc02.vm.network "forwarded_port", guest: 8200, host: 8207
      dc02.vm.network "forwarded_port", guest: 8500, host: 8507
      dc02.vm.network "private_network", ip: "192.168.2.17"
      dc02.vm.provision "shell", path: "scripts/provision.1.sh"
      dc02.vm.provision "shell", path: "scripts/configure_static_routes.1.sh"
  end

  puts info if ARGV[0] == "status"

end
