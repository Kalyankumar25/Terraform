#! /bin/bash
sudo useradd ansible-user
sudo echo "ansible" | passwd --stdin ansible-user
sudo echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd