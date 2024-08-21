#! /bin/bash
sudo useradd ansible-user
sudo echo "ansible" | passwd --stdin ansible-user
sudo echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo systemctl restart sshd
sudo yum install -y httpd.x86_64
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo echo "Web Page from $(hostname -f) Server">/var/www/html/index.html