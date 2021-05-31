# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.ssh.insert_key = false
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "2048"]
        vb.linked_clone = true
    end

    # DNS server.
    config.vm.define "dns" do |app|
        app.vm.hostname = "dns1.lab.local"
        app.vm.box = "geerlingguy/centos7"
        app.vm.network "public_network", ip: "192.168.1.17"
        app.vm.network :private_network, ip: "172.16.10.219"
        
        # Installing DNS server (BIND)
        app.vm.provision "shell", path: "./dns_install.sh"
        
    end

    # Web server.
    config.vm.define "web" do |app|
        app.vm.hostname = "www.lab.local"
        app.vm.box = "geerlingguy/centos7"
        app.vm.network :private_network, ip: "172.16.10.220"
    end

    # Mail server.
    config.vm.define "mail" do |db|
        db.vm.hostname = "mail.lab.local"
        db.vm.box = "geerlingguy/centos7"
        db.vm.network :private_network, ip: "172.16.10.221"
    end
    # Client Tester.
    config.vm.define "client" do |db|
        db.vm.hostname = "client.lab.local"
        db.vm.box = "geerlingguy/centos7"
        db.vm.network "public_network", ip: "192.168.1.217"
        db.vm.provision "shell", path: "./client.sh"
    end
end