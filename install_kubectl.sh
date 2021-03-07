#!/bin/bash
#!/bin/bash
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl
sudo yum install -y mysql
cd /home/ec2-user && wget https://raw.githubusercontent.com/etologic/aws-eks-wordpress/main/1.8.tar.gz && tar -xvf 1.8.tar.gz && rm 1.8.tar.gz 