
runestone.init:
	make runestone.init.$(shell git branch --show-current)

runestone.build-image.tagname:
runestone.build-image.%:
	cd docker && docker build -t donnerc/runestone-server:$* -f short.Dockerfile .
	docker tag donnerc/runestone-server:$* donnerc/runestone-server:latest
	docker push donnerc/runestone-server:latest

runestone.init.branch-name: 
runestone.init.%: 
	make runestone.clone.branch.$*

runestone.clone.branch.:
runestone.clone.branch.%:
	$(SSH) 'git clone --single-branch --branch $* https://github.com/informatiquecsud/21Learning-backend.git $(SERVER_DIR)'

runestone.update:
	$(SSH) 'cd $(SERVER_DIR) && git pull'

runestone.setup:
	
	@echo "Cloning repo https://github.com/informatiquecsud/21Learning-backend"
	@make runestone.init
	@echo "Installing NGINX HTTPS proxy"
	@make proxy.up
	@echo "Waiting for Proxy ..."
	@sleep 10s
	@echo "Launching Runestone stack ..."
	@make up
	@sleep 10s
	@echo "Setting up SSL certificates..."
	@sleep 10s
	@echo "Done. The site should be accessible at https://$(RUNESTONE_HOST)"



