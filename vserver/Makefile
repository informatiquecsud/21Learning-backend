HOST=$(RUNESTONE_HOST)
SSH_OPTIONS=-o 'StrictHostKeyChecking no'
SSH_ROOT = ssh $(SSH_OPTIONS) root@$(HOST)
RSYNC_OPTIONS= -e 'ssh -o StrictHostKeyChecking=no'
RSYNC=rsync $(RSYNC_OPTIONS)
SSH = $(SSH_ROOT) 
ROOT = root@$(HOST)
SYNC = rsync -raz --delete --progress $(ROOT)

### Docker stuff
DOCKER_COMPOSE_VERSION=1.27.4
DOCKER_MACHINE_VERSION=v0.16.0

upgrade:
	$(SSH) apt-get update -y
	$(SSH) apt-get upgrade -y --fix-missing

init: upgrade 
	$(SSH) apt-get -y install python3 python-is-python3 curl rsync git build-essential htop bash-completion --fix-missing
	rsync .bashrc.template root@$(HOST):~/.bashrc
	
# This provisions the remote machine with docker using docker-machine
docker.setup-machine:
	docker-machine create \
		--driver generic \
		--generic-ip-address=$(shell dig $$SITE_DOMAIN +short) \
		--generic-ssh-key ~/.ssh/id_rsa \
		$(ENV_NAME)

docker-compose.setup:
	$(SSH) 'curl -L https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/docker-compose-`uname -s`-`uname -m` > /usr/bin/docker-compose && chmod +x /usr/bin/docker-compose'	


# This provisions the remote machine with docker using custom scripts
docker.setup: init
	cat docker/install.sh | $(SSH) sh
	make docker-compose.setup


docker.start:
	$(SSH) '/etc/init.d/docker start'
	
docker.test:
	$(SSH) 'docker ps'	

ssh-root:
	$(SSH)

ssh: ssh-root

ssh-register-public-key:
	cat ~/.ssh/id_rsa.pub | $(SSH) 'cat >> .ssh/authorized_keys'

setup-ssh:
	$(SSH) 'mkdir -p .ssh && touch .ssh/authorized_keys'

clean-ssh:
	rm -f ~/.ssh/known_hosts


halt:
	$(SSH) 'halt && sleep 5s && ping $(HOST)'

reboot:
	$(SSH) reboot
	sleep 2s && ping $(HOST)
	sleep 20s && ping $(HOST)

# usefull to update entry, especially on HyperV
update-dns:
	$(SSH) 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf && service networking restart'

disk.free:
	$(SSH) 'df -h | grep sda1'