# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant config
Vagrant.configure("2") do |config|

  # testing configuration
  config.vm.define "testing" do |testing|
    testing.vm.box = "chef/debian-7.4"
    testing.vm.provision :shell, path: ".vagrant/bootstrap/testing.sh"
    testing.vm.network :forwarded_port, guest: 9091, host: 19091
    testing.vm.network :private_network, ip: "10.1.1.2"
    testing.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "256"]
    end
  end

end