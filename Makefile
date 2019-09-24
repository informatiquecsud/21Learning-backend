SSH_USER=root
SSH_PORT=22
SSH_HOST=$(RUNESTONE_HOST)

ENV_NAME=local
ifdef USE_HIDORA
	SSH_USER=$(HIDORA_SSH_USER)
	SSH_PORT=$(HIDORA_SSH_PORT)
	SSH_HOST=$(HIDORA_SSH_HOST)
	ENV_NAME=hidora
endif
ifdef USE_OVH
	ENV_NAME=ovh
endif



REMOTE=$(SSH_USER)@$(SSH_HOST)
SSH_OPTIONS=-o 'StrictHostKeyChecking no' -p $(SSH_PORT)
SSH = ssh $(SSH_OPTIONS) $(SSH_USER)@$(SSH_HOST)
SERVER_DIR=~/runestone-server
SERVER_COMPONENTS_DIR=/RunestoneComponents
COMPONENTS_DIR=../RunestoneComponents
RSYNC_BASE_OPTIONS= -e 'ssh -o StrictHostKeyChecking=no -p $(SSH_PORT)' --progress
RSYNC_OPTIONS= $(RSYNC_BASE_OPTIONS) --exclude=.git --exclude=venv --exclude=ubuntu --exclude=__pycache__ --delete
RSYNC=rsync $(RSYNC_OPTIONS)
TIME = $(shell date +%Y-%m-%d_%Hh%M)
DOTENV_FILE = .env.$(ENV_NAME)


RUNESTONE_CONTAINER_ID = $(shell docker ps -qf "name=_runestone")
DB_CONTAINER_ID = $(shell docker ps -qf "name=_db")

DATE_FMT = "%Y-%m-%d_%H:%M:%S"
DATETIME = $(shell date +$(DATE_FMT))

RSMANAGE = docker exec -it $(RUNESTONE_CONTAINER_ID) rsmanage
RSMANAGE_T = docker exec -t $(RUNESTONE_CONTAINER_ID) rsmanage
RUN_SQL = docker exec -i $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
RUN_SQL_T = docker exec -it $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
PG_DUMP = docker exec -i $(DB_CONTAINER_ID) pg_dump -U $(POSTGRES_USER) -d $(POSTGRES_DB)

COMPOSE_PGADMIN = -f docker-compose-pgadmin.yml

RUNESTONE_DIR = /srv/web2py/applications/runestone
WEB2PY_BOOKS = $(RUNESTONE_DIR)/books

# need to run the server-init rule for this to work
COMPOSE_OPTIONS = -f docker-compose-local.yml
ifdef RUNESTONE_REMOTE
	COMPOSE_OPTIONS = -f docker-compose-production.yml
endif

ifdef USE_HIDORA
	COMPOSE_OPTIONS =  -f docker-compose-production.yml -f docker-compose-production-hidora.yml
endif


COMPOSE = docker-compose -f docker-compose.yml $(COMPOSE_PGADMIN) $(COMPOSE_OPTIONS)

# shows hot to load the env vars defined in .env
howto-load-dotenv:
	@echo 'set -a; source $(DOTENV_FILE); set +a' | clip.exe

echo-compose-options:
	@echo 'Compose options is: ' $(COMPOSE_OPTIONS)

# TODO: This .env.build stuff has to be eventually wiped off, an other way of doing it
# should be found ...
.env.build:
	@if test -z "$(RUNESTONE_HOST)"; then echo "variable HOST not defined"; exit 1; fi
	@if test -z "$(POSTGRES_PASSWORD)"; then echo "variable POSTGRES_PASSWORD not defined"; exit 1; fi
	@if test -z "$(WEB2PY_PASSWORD)"; then echo "variable WEB2PY_PASSWORD not defined"; exit 1; fi
	@if test -z "$(PGADMIN_PASSWORD)"; then echo "variable PGADMIN_PASSWORD not defined"; exit 1; fi
	@rm -f $(DOTENV_FILE)
	@echo "RUNESTONE_HOST=$(RUNESTONE_HOST)" >> $(DOTENV_FILE)
	@echo "POSTGRES_PASSWORD=$(POSTGRES_PASSWORD)" >> $(DOTENV_FILE)
	@echo "POSTGRES_USER=$(POSTGRES_USER)" >> $(DOTENV_FILE)
	@echo "POSTGRES_DB=$(POSTGRES_DB)" >> $(DOTENV_FILE)
	@echo "WEB2PY_PASSWORD=$(WEB2PY_PASSWORD)" >> $(DOTENV_FILE)
	@echo "PGADMIN_PASSWORD=$(PGADMIN_PASSWORD)" >> $(DOTENV_FILE)
	@echo "HIDORA_SSH_USER=$(HIDORA_SSH_USER)" >> $(DOTENV_FILE)
	@echo "HIDORA_SSH_HOST=$(HIDORA_SSH_HOST)" >> $(DOTENV_FILE)
	@echo "HIDORA_SSH_PORT=$(HIDORA_SSH_PORT)" >> $(DOTENV_FILE)
	@echo "USE_HIDORA=$(USE_HIDORA)" >> $(DOTENV_FILE)

push: .env.build
	$(RSYNC) -raz . $(REMOTE):$(SERVER_DIR) \
		--progress \
		--exclude=.git \
		--exclude=venv \
		--exclude=ubuntu \
		--exclude=build \
		--exclude=published \
		--exclude=__pycache__ \
		--exclude=backup \
		--exclude=databases \
		--exclude=data/pass*
	$(SSH) 'cd $(SERVER_DIR) && echo "RUNESTONE_REMOTE=true" >> $(DOTENV_FILE)'
	$(SSH) 'cd $(SERVER_DIR) && cp -f $(DOTENV_FILE) .env'


ssh:
	$(SSH)  -F ./.ssh.config

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

rm: stop
	$(COMPOSE) rm -f
	rm -rf databases

ps:
	$(COMPOSE) ps


up:
	$(COMPOSE) up -d

top:
	$(COMPOSE) top
dblogs:
	$(COMPOSE) logs db

logs:
	$(COMPOSE) logs runestone
logsf:
	$(COMPOSE) logs -f runestone


db-rm:
	$(COMPOSE) stop db
	$(COMPOSE) rm -f db
db-up:
	$(COMPOSE) up -d db
db-restart: db-rm db-up

runestone-rm:
	$(COMPOSE) stop runestone
	$(COMPOSE) rm -f runestone

runestone-image:
	docker build -t runestone/server .
runestone-restart:
	$(COMPOSE) stop runestone
	$(COMPOSE) rm -f runestone
	$(COMPOSE) up -d runestone
runestone-exec-bash:
	docker exec -it $(RUNESTONE_CONTAINER_ID) bash
runestone-ps:
	$(COMPOSE) ps
runestone-update-components:
	# $(COMPOSE) exec runestone pip install --upgrade
	# git+git://github.com/informatiquecsud/RunestoneComponents.git
	@echo copying runestone components to container $(RUNESTONE_CONTAINER_ID)
	$(COMPOSE) exec runestone rm -rf $(SERVER_COMPONENTS_DIR)
	docker cp $(COMPONENTS_DIR) $(RUNESTONE_CONTAINER_ID):$(SERVER_COMPONENTS_DIR)
	$(COMPOSE) exec runestone pip install --upgrade -e $(SERVER_COMPONENTS_DIR)
rsmanage.update:
	docker exec -i -w /srv/web2py/applications/runestone $(RUNESTONE_CONTAINER_ID) pip install -e rsmanage
rsmanage.help:
	docker exec -i -w /srv/web2py/applications/runestone $(RUNESTONE_CONTAINER_ID) rsmanage --help
	
	
runestone-inspect-errors:
	docker cp $(RUNESONE_SERVER_CONTAINER_ID):/srv/web2py/applications/runestone/errors .

full-restart: stop rm up logsf

psql:
	$(RUN_SQL_T)


config:
	$(COMPOSE) config

pgadmin-bash:
	$(COMPOSE) exec pgadmin sh
pgadmin-restart:
	$(COMPOSE) restart pgadmin
pgadmin-rm:
	$(COMPOSE) rm pgadmin
pgadmin-up:
	$(COMPOSE) up pgadmin


server-init:
	$(SSH) 'echo "export RUNESTONE_REMOTE=true" >> ~/.bashrc'
	$(SSH) 'echo "export USE_HIDORA=$(USE_HIDORA)" >> ~/.bashrc'
	$(SSH) 'echo "export POSTGRES_DB=$(POSTGRES_DB)" >> ~/.bashrc'
	$(SSH) 'echo "export POSTGRES_USER=$(POSTGRES_USER)" >> ~/.bashrc'

proxy-start:
	cd nginx-letsencrypt && docker-compose build && docker-compose up -d'
proxy-down:
	cd nginx-letsencrypt && docker-compose down'
proxy-logs:
	cd nginx-letsencrypt && docker-compose logs'
proxy-logsf:
	cd nginx-letsencrypt && docker-compose logs -f'
proxy-bash:
	cd nginx-letsencrypt && docker-compose exec nginx-proxy bash'
proxy-ps:
	cd nginx-letsencrypt && docker-compose ps'
proxy-conf:
	cd nginx-letsencrypt && docker-compose exec -T nginx-proxy cat /etc/nginx/conf.d/default.conf'

	
remote.runestone-sync-errors:
	$(RSYNC) -raz $(REMOTE):$(SERVER_DIR)/errors ./runestone-errors --progress

remote.backup:
	$(SSH) 'tar -cjf backup.tar.bz2 $(SERVER_DIR)'
	rsync $(RSYNC_BASE_OTIONS) $(REMOTE):backup.tar.bz2 ./backup/backup-$(TIME).tar.bz2 --progress

download-docker-images:
	$(RSYNC) -raz $(REMOTE):*.tar ./backup-images --progress



##############################################################
## Any rule beginning with remote. will be executed in the $(SERVER_DIR)
## directory on the remote host $(SSH_HOST)
##############################################################
%.remote:
	$(SSH) 'cd $(SERVER_DIR) && make $*'
remote.%:
	$(SSH) 'cd $(SERVER_DIR) && make $*'


# Course management
course.build.coursename:
course.build.oxocard101:
course.build.doi:
course.build.%:
	@docker exec -i -w $(WEB2PY_BOOKS)/$* $(RUNESTONE_CONTAINER_ID) runestone build --all deploy
	
push.course.build.oxocard101:
push.course.build.doi:
push.course.build.coursename:
push.course.build.%:
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	make push
	$(SSH) 'cd $(SERVER_DIR)/books/$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build.$*
	
	
	
# another way of doing that kind of thing is with the -c flag of bash
# runestone-rebuild-oxocard101:
# $(COMPOSE) exec runestone bash -c "cd $(WEB2PY_BOOKS)/oxocard101 && runestone build deploy"


##############################################################
## Run SQL Queries directly in the db container
##############################################################


# run complex queries stored in sql/ folder
# example : make show-my-students will run sql/show-my-students.sql file in the
# db container
%.sql.run: sql/%.sql
	cat $< | $(RUN_SQL)

%.table.desc:
	echo "SELECT column_name, data_type, column_default, is_nullable FROM information_schema.COLUMNS WHERE TABLE_NAME = '$*';" | $(RUN_SQL)
%.table.ls:
	echo "SELECT * FROM $*;" | $(RUN_SQL)
%.table.delete.id:
	@read -p "ID to delete: " id; \
	echo "DELETE FROM $* WHERE id = $$id;" | $(RUN_SQL)
show-queries:
	ls sql
show-tables:
	echo "SELECT table_name, table_type FROM information_schema.TABLES WHERE table_schema = 'public';" | $(RUN_SQL)


%.course.ins:
	echo "INSERT INTO courses (course_name, base_course, term_start_date) VALUES ('$*', '$*', '$(shell date -I)');" | $(RUN_SQL)
%.course.del:
	echo "DELETE FROM courses WHERE course_name='$*';" | $(RUN_SQL)

init-21learning-tables: query.auth_group_validity
init-21learning-courses: oxocard101.course.ins doi.course.ins
init-21learning-instructors: data/instructors.csv
	$(RSMANAGE_T) inituser --fromfile $(RUNESTONE_DIR)/$<
	cut -d, -f1,6 $< | tr ',' ' ' | while read username course; do echo adding $$username as an instructor to $$course; $(RSMANAGE_T) addinstructor --username $$username --course $$course; done

init-21learning: init-21learning-tables init-21learning-courses init-21learning-instructors


%.user.delete:
	echo "DELETE FROM auth_user WHERE id = $*;" | $(RUN_SQL)
students.delete:
	echo "DELETE FROM auth_user WHERE email LIKE '%student%';" | $(RUN_SQL)
students.orphans.delete:
	echo "DELETE FROM auth_user  ;" | $(RUN_SQL)




class.csv.ls:
%.class.csv.ls: data/%.csv
	cat $<
class.csv.load:
%.class.csv.load: data/%.csv
	# créer le groupe dans la base de données
	# make class.create.$*
	$(RSMANAGE_T) add-class --csvfile $(RUNESTONE_DIR)/$< --class-name $(shell echo $* | tr "[:lower:]" "[:upper:]")
	docker cp $(RUNESTONE_CONTAINER_ID):/srv/web2py/tmp-passwords.csv data/passwords-$*.csv

class.empty:
%.class.empty:
	# créer le groupe dans la base de données
	# make class.create.$*
	$(RSMANAGE_T) empty-class --class-name $(shell echo $* | tr "[:lower:]" "[:upper:]")
	
class.passwd.show:	
%.class.passwd.show:
	@echo "Passwords of students of class $*"
	@cat data/passwords-$*.csv

roles.ls:
	make ls-groups.sql.run
	

class.delete.id:
class.delete.%:
	echo "DELETE FROM auth_group_validity WHERE auth_group_id = $*;" | $(RUN_SQL) && \
	echo "DELETE FROM auth_group WHERE id = $*;" | $(RUN_SQL)

class.add_to_course.class_name:	
class.add_to_course.%:
	make courses.ls
	@read -p "Course id: " course_id; \
	for student_id in $(shell echo "select user_id from auth_membership WHERE group_id IN (SELECT id FROM auth_group WHERE role LIKE '%$*%' LIMIT 1);" | $(RUN_SQL) -t); \
	do \
		echo adding student ID: $$student_id to course ID: $$course_id ; \
		echo "INSERT INTO user_courses (user_id, course_id) VALUES ($$student_id, $$course_id);" | $(RUN_SQL) ; \
	done;

query.run.%:
	echo "$*" | $(RUN_SQL)


queries.ls:
	ls sql

# short predefined queries (with autocompletion)
courses.ls: 
	echo "SELECT * FROM courses;" | $(RUN_SQL)
users.ls: 
	echo "SELECT id, username, first_name, last_name, email FROM auth_user;" | $(RUN_SQL)
	

env.show:
	env | grep RUNESTONE

db.backup:
	@$(PG_DUMP) | gzip > backup/db/runestone-backup-$(DATETIME).sql.gz
	@du -sh backup/db/runestone-backup-$(DATETIME).sql.gz


# TODO: to be developped, use the pg_restore utility. Still have to decide (or
# distinguish) if we want te recreate the DB from scratch (delete and restore)
# or if an other solution would be better under certain circumstances.
db.restore:
	@echo "DB restore: not implemented yet"



#######################################################################
### auto-completion for table operations
#######################################################################
include table-completions.Makefile

table-completions.update:



#######################################################################
# Auto-completion for sql queries
#######################################################################
include query-completions.Makefile


# allows to update the query completion file
query-completions.update:
	@rm -f query-completions.Makefile && touch query-completions.Makefile
	@for query in $(shell ls sql); do echo $$query: >> query-completions.Makefile ; done
	@echo "New completion file"
	@cat -n query-completions.Makefile