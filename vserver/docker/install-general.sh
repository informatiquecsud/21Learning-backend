#!/bin/sh

# apt-get -y purge lxc-docker*
# apt-get -y purge docker.io*

apt-get -y update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg2 bash-completion
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"


apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io
systemctl status docker
docker -v