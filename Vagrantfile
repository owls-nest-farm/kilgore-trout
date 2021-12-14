# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"

    config.vm.network :forwarded_port, host: 4141, guest: 4141

    config.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.name = "kilgore-trout"
    end

    config.vm.provision :shell do |s|
        s.path = "scripts/vagrant/root.sh"
        s.env = {
            USER:ENV["USER"],
            GITHUB_TOKEN:ENV["GITHUB_TOKEN"],
            WEBHOOK_URL:ENV["WEBHOOK_URL"],
            WEBHOOK_DOMAIN:ENV["WEBHOOK_DOMAIN"],
            WEBHOOK_PORT:ENV["WEBHOOK_PORT"],
        }
    end
end

