
runestone.init.branch-name: 
runestone.init.%: 
	make runestone.clone.branch.$*

runestone.clone.branch.:
runestone.clone.branch.%:
	$(SSH) 'git clone --single-branch --branch $* https://github.com/informatiquecsud/21Learning-backend.git $(SERVER_DIR)'

runestone.update:
	$(SSH) 'cd $(SERVER_DIR) && git pull'

runestone.setup:
	@echo "Installing NGINX HTTPS proxy"
	@make remote.proxy-start
	@echo "Waiting for Proxy ..."
	@sleep 10s
	@echo "Launching Runestone stack ..."
	@make remote.up
	@sleep 10s
	@echo "Setting up SSL certificates..."
	@sleep 10s
	@echo "Done. The site should be accessible at https://$(RUNESTONE_HOST)"



