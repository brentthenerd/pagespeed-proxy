VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/zesty64"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "80"]
  end

  config.vm.provision :shell do |s|
    s.path = "setup-proxy.sh"
    s.privileged = false
  end

  config.vm.network :forwarded_port, guest: 8000, host: 8000
end
