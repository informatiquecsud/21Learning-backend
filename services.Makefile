
services.config:
	$(COMPOSE) config


service.up.service:
service.up.db:
service.up.runestone:
service.up.pgadmin:
service.up.hasura:
service.up.%:
	$(COMPOSE) up -d $*

service.build.service-name:
service.build.db:
service.build.runestone:
service.build.pgadmin:
service.build.hasura:
service.build.%:
	$(COMPOSE) build $*


service.down.service-name:
service.down.%:
	$(COMPOSE) down $*
service.stop.service-name:
service.stop.%:
	$(COMPOSE) stop $*
service.start.service-name:
service.start.%:
	$(COMPOSE) start $*
service.rm.service-name:
service.rm.%:
	$(COMPOSE) rm -f  $*
service.logs.service-name:
service.logs.%:
	$(COMPOSE) logs -f  $*
service.full-restart.service-name:
service.full-restart.%: 
	make service.stop.$* 
	make service.rm.$*
	make service.up.$*
	make service.logs.$*
service.restart.service-name:
service.restart.%: 
	make service.stop.$* 
	make service.start.$*