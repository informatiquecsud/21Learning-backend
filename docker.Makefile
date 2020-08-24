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

env.create.new-env-name:
env.create.%:
	echo "ENV_NAME=$*" > .env.$*
	cat .env.template >> .env.$*
	touch $*.context.Makefile

context.create.new-context-name:
context.create.%:
	docker context create $(RUNESTONE_CONTEXT_BASE)-$* \
		--default-stack-orchestrator=swarm \
		--docker host=ssh://root@$(RUNESTONE_HOST)
	
context.use.local:
	docker context use default

context.use.context-name:
context.use.%:
	docker context use $(RUNESTONE_CONTEXT_BASE)-$*
	ln -sf .env.$* .env
	make howto-load-dotenv.$*

context.rm.: 
context.rm.%: context.use.local
	docker context rm $(RUNESTONE_CONTEXT_BASE)-$*
	rm -f .env.$*
	rm -f $*.context.Makefile

docker.stop-all:
	docker stop $(shell docker ps -a -q)
docker.rm-all: docker.stop-all
	docker rm $(shell docker ps -a -q)
docker.rmi-all: docker.rm-all
	docker rmi $(docker images -q)
