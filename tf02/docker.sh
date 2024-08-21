#! /bin/bash
sudo useradd ansible-user
sudo echo "ansible" | passwd --stdin ansible-user
sudo echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo systemctl restart sshd
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker