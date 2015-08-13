# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vbguest.auto_update = false

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
     sudo apt-get update -qq
     sudo apt-get install -y build-essential git curl pkg-config libmagickwand-dev
   SHELL
end
