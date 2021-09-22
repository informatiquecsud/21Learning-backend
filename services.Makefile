
services.config:
	$(COMPOSE) config
	@echo "$(COMPOSE)" | $(CLIP)

services.ps:
	docker ps -a --format "{{.ID}}: {{.Names}}"

service.up.service:
service.up.db:
service.up.runestone:
service.up.pgadmin:
service.up.hasura:
service.up.new:
service.up.%:
	$(COMPOSE) --compatibility up -d $*

service.build.service-name:
service.build.db:
service.build.runestone:
service.build.pgadmin:
service.build.hasura:
service.build.new:
service.build.%:
	$(COMPOSE) build $*

service.shell.service-name:
service.shell.%:
	$(COMPOSE) exec $* bash


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
service.logs.runestone:
service.logs.%:
	$(COMPOSE) logs -f --tail 30  $*
service.full-restart.service-name:
service.full-restart.%: 
	make service.stop.$* 
	make service.rm.$*
	make service.up.$*
	make service.logs.$*
service.restart.service-name:
service.restart.%: 
	make service.stop.$* 
	make service.up.$*




proxy.up:
	cd nginx-letsencrypt && docker-compose build && docker-compose up -d
proxy.start:
	cd nginx-letsencrypt && docker-compose build && docker-compose start
proxy.stop:
	cd nginx-letsencrypt && docker-compose build && docker-compose stop
proxy.restart:
	cd nginx-letsencrypt && docker-compose build && docker-compose restart
proxy.down:
	cd nginx-letsencrypt && docker-compose down
proxy.rm: proxy.down
	cd nginx-letsencrypt && docker-compose rm
proxy.logs:
	cd nginx-letsencrypt && docker-compose logs
proxy.logsf:
	cd nginx-letsencrypt && docker-compose logs -f
proxy.bash:
	cd nginx-letsencrypt && docker-compose exec nginx-proxy.bash
proxy.ps:
	cd nginx-letsencrypt && docker-compose ps
proxy.conf:
	cd nginx-letsencrypt && docker-compose exec -T nginx-proxy cat /etc/nginx/conf.d/default.conf
