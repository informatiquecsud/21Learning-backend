docker.default: docker.context.use.default
docker.context.use.default:
docker.context.use.%:
	docker context use $*

context:
	docker context ls

envname:
	@echo "Env name is '$(ENV_NAME)'"
	
docker.env: docker.context.use.env
docker.context.use.env:
	docker context use runestone-$(ENV_NAME)

context.create.:
context.create.%:
	echo "ENV_NAME=$*" > .env.$*
	cat .env.template >> .env.$*
	docker context create $(RUNESTONE_CONTEXT_BASE)-$* --default-stack-orchestrator=swarm --docker "host=ssh://root@$(RUNESTONE_HOST)"
	

context.use.local:
	docker context use default

context.use.:
context.use.%:
	docker context use $(RUNESTONE_CONTEXT_BASE)-$*
	ln -sf .env.$* .env

context.rm.: 
context.rm.%: context.use.local
	docker context rm $(RUNESTONE_CONTEXT_BASE)-$*
	rm -f .env.$*