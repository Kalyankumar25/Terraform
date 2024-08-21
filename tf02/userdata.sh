#! /bin/bash
sudo useradd ansible-user
sudo echo "ansible" | passwd --stdin ansible-user
sudo echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo systemctl restart sshd