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
COMPONENTS_DIR=~/runestone-components/
RSYNC_BASE_OPTIONS= -e 'ssh -o StrictHostKeyChecking=no -p $(SSH_PORT)' --progress
RSYNC_OPTIONS= $(RSYNC_BASE_OPTIONS) --exclude=.git --exclude=venv --exclude=ubuntu --exclude=stats --exclude=__pycache__ --exclude=junk --exclude=errors
RSYNC_KEEP=rsync $(RSYNC_OPTIONS)
RSYNC=rsync $(RSYNC_OPTIONS) --delete
TIME = $(shell date +%Y-%m-%d_%Hh%M)
DOTENV_FILE = .env.$(ENV_NAME)

DB_GIT_BACKUP_DIR = backup/db/git
DB_BACKUP_GIT_REPO = git@bitbucket.org:donnerc/21learning-db-backups.git
DB_BACKUP_GIT = cd $(DB_GIT_BACKUP_DIR) && git

RUNESTONE_CONTAINER_ID = $(shell docker ps -qf "name=_runestone")
DB_CONTAINER_ID = $(shell docker ps -qf "name=_db")
PGADMIN_CONTAINER_ID = $(shell docker ps -qf "name=_pgadmin")
HASURA_CONTAINER_ID = $(shell docker ps -qf "name=_hasura")
REMOTE_DB_CONTAINER_ID = $(shell $(SSH) 'docker ps -qf "name=_db"')
REMOTE_RUNESTONE_CONTAINER_ID = $(shell $(SSH) 'docker ps -qf "name=_runestone"')

DATE_FMT = "%Y-%m-%d_%H:%M:%S"
DATETIME = $(shell date +$(DATE_FMT))

RSMANAGE = docker exec -it $(RUNESTONE_CONTAINER_ID) rsmanage
RSMANAGE_T = docker exec -t $(RUNESTONE_CONTAINER_ID) rsmanage
RSMANAGE_I = docker exec -t $(RUNESTONE_CONTAINER_ID) rsmanage

RUN_SQL = docker exec -i $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
REMOTE_RUN_SQL = $(SSH) 'docker exec -i $(REMOTE_DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)'
RUN_SQL_T = docker exec -it $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
PG_DUMP = docker exec -i $(DB_CONTAINER_ID) pg_dump -U $(POSTGRES_USER) -d $(POSTGRES_DB)
PG_RESTORE = docker exec -i $(DB_CONTAINER_ID) pg_restore $(POSTGRES_DB)  -U $(POSTGRES_USER) 
PSQL = docker exec -i $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
DROPDB = docker exec -i $(DB_CONTAINER_ID) dropdb $(POSTGRES_DB) -U $(POSTGRES_USER)
CREATEDB = docker exec -i $(DB_CONTAINER_ID) createdb -T template0 $(POSTGRES_DB) -U $(POSTGRES_USER)

COMPOSE_PGADMIN = -f docker-compose-pgadmin.yml

RUNESTONE_DIR = /srv/web2py/applications/runestone
WEB2PY_BOOKS = $(RUNESTONE_DIR)/books

# need to run the server-init rule for this to work
COMPOSE_OPTIONS = -f docker-compose-local.yml -f api/hasura/docker-compose.yaml
ifdef RUNESTONE_REMOTE
	COMPOSE_OPTIONS = -f docker-compose-production.yml -f api/hasura/docker-compose-prod.yaml
endif

ifdef
	COMPOSE_OPTIONS =  -f docker-compose-production.yml -f docker-compose-production-hidora.yml
endif


COMPOSE = docker-compose -f docker-compose.yml $(COMPOSE_PGADMIN) $(COMPOSE_OPTIONS)

# shows hot to load the env vars defined in .env
howto-load-dotenv:
	@echo 'set -a; source $(DOTENV_FILE); set +a' | clip.exe
howto-load-dotenv.ovh:
	@echo 'set -a; source .env.ovh set +a' | clip.exe

echo-compose-options:
	@echo 'Compose options is: ' $(COMPOSE_OPTIONS)

.PHONY: no_targets__ list
no_targets__:
list:
    sh -c "$(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | sort"

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
	@echo "USE_OVH=$(USE_OVH)" >> $(DOTENV_FILE)
	@echo "HASURA_ADMIN_SECRET_KEY=$(HASURA_ADMIN_SECRET_KEY)" >> $(DOTENV_FILE)
	@echo 'HASURA_GRAPHQL_JWT_SECRET=$(HASURA_GRAPHQL_JWT_SECRET)' >> $(DOTENV_FILE)
	echo '$(HASURA_GRAPHQL_JWT_SECRET)'
	#$(shell echo 'HASURA_GRAPHQL_JWT_SECRET=\'(cat auth/key.json)\'' >> $(DOTENV_FILE)) 

push: .env.build
	$(RSYNC) -raz . $(REMOTE):$(SERVER_DIR) \
		--progress \
		--exclude=.git \
		--exclude=venv \
		--exclude=ubuntu \
		--exclude=__pycache__ \
		--exclude=backup \
		--exclude=databases \
		--exclude=data/pass* \
		--exclude=books
	$(SSH) 'cd $(SERVER_DIR) && echo "RUNESTONE_REMOTE=true" >> $(DOTENV_FILE)'
	$(SSH) 'cd $(SERVER_DIR) && cp -f $(DOTENV_FILE) .env'


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
service.full-start.service-name:
service.restart.%: 
	make service.stop.$* 
	make service.start.$*

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
	cd nginx-letsencrypt && docker-compose build && docker-compose up -d
proxy-down:
	cd nginx-letsencrypt && docker-compose down
proxy-logs:
	cd nginx-letsencrypt && docker-compose logs
proxy-logsf:
	cd nginx-letsencrypt && docker-compose logs -f
proxy-bash:
	cd nginx-letsencrypt && docker-compose exec nginx-proxy bash
proxy-ps:
	cd nginx-letsencrypt && docker-compose ps
proxy-conf:
	cd nginx-letsencrypt && docker-compose exec -T nginx-proxy cat /etc/nginx/conf.d/default.conf

	
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
	$(SSH) 'cd $(SERVER_DIR) && make $* '
remote.%:
	$(SSH) 'cd $(SERVER_DIR) && make args.$* ARGS="$(REMOTE_ARGS)"'


# Course management
course.build.coursename:
course.build.oxocard101:
course.build.overview:
course.build.doi:
course.build.%:
	@echo $(RUNESTONE_CONTAINER_ID)
	@docker exec -i -w $(WEB2PY_BOOKS)/$* $(RUNESTONE_CONTAINER_ID) runestone build deploy
	@cp -f webtj.tar.gz books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar -xf webtj.tar.gz
	
# Course management
course.build-all.coursename:
course.build-all.oxocard101:
course.build-all.overview:
course.build-all.doi:
course.build-all.%:
	@docker exec -i -w $(WEB2PY_BOOKS)/$* $(RUNESTONE_CONTAINER_ID) runestone build --all deploy
	# @docker exec -i -w $(SERVER_DIR) cp webtj.tar.gz books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar -xf webtj.tar.gz
	@cp -f webtj.tar.gz books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar -xf webtj.tar.gz
	
	
course.add_instructor.oxocard101:
course.add_instructor.overview:
course.add_instructor.doi:
course.add_instructor.concepts-programmation:
course.add_instructor.coursename:
course.add_instructor.%:
	@read -p "Username to add: " user_name; \
	echo "INSERT INTO course_instructor (course, instructor) \
				SELECT courses.id, auth_user.id FROM courses, auth_user \
				WHERE username = '$(USER)' AND courses.course_name = '$*';" \
					| $(RUN_SQL)

course.show_instructors.coursename:
course.show_instructors.%:


course.ins.new-course-name:
course.ins.%:
	echo "INSERT INTO courses (course_name, base_course, term_start_date, login_required, python3) VALUES ('$*', '$*', '$(shell date -I)', 'T', 'T');" | $(RUN_SQL)
course.del.course-to-delete:
course.del.%:
	echo "DELETE FROM courses WHERE course_name='$*';" | $(RUN_SQL)


	
course.push.oxocard101:
course.push.overview:
course.push.doi:
course.push.concepts-programmation:
course.push.coursename:
course.push.%:
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz books/$* $(REMOTE):$(SERVER_DIR)/books/ \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build.$* KEEP_EXAMS=$(KEEP_EXAMS)
	#@"$(KEEP_EXAMS)" = "true" || (echo "deleting exams" && $(SSH) 'cd $(SERVER_DIR)/books/$*/published/$*/examens && rm -rf *')

course.push-all.oxocard101:
course.push-all.overview:
course.push-all.doi:
course.push-all.concepts-programmation:
course.push-all.coursename:
course.push-all.%:
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz books/$* $(REMOTE):$(SERVER_DIR)/books/ \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build-all.$* KEEP_EXAMS=$(KEEP_EXAMS)
	#@"$(KEEP_EXAMS)" = "true" || (echo "deleting exams" && $(SSH) 'cd $(SERVER_DIR)/books/$*/published/$*/examens && rm -rf *')

# TODO: use a better strategy => webhooks from gitlab ... requires a special api
# on the server
course.push-all.einfachinformatik-prog.gym:
course.push-all.einfachinformatik-prog.7-9:
course.push-all.einfachinformatik-prog.%:
	echo "Pushing branch $* of einfachinformatik-prog to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz books/einfachinformatik-prog/* $(REMOTE):$(SERVER_DIR)/books/einfachinformatik-prog-$* \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/einfachinformatik-prog-$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build-all.einfachinformatik-prog-$*

	
# another way of doing that kind of thing is with the -c flag of bash
# runestone-rebuild-oxocard101:
# runestone-rebuild-overview:
# $(COMPOSE) exec runestone bash -c "cd $(WEB2PY_BOOKS)/oxocard101 && runestone build deploy"
# $(COMPOSE) exec runestone bash -c "cd $(WEB2PY_BOOKS)/overview && runestone build deploy"


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


init-21learning-tables: auth_group_validity.sql.run
init-21learning-courses: course.ins.oxocard101 course.ins.overview course.ins.doi
init-21learning-instructors: data/instructors.csv
	$(RSMANAGE_T) inituser --fromfile $(RUNESTONE_DIR)/$<
	cut -d, -f1,6 $< | tr ',' ' ' | while read username course; do echo adding $$username as an instructor to $$course; $(RSMANAGE_T) addinstructor --username $$username --course $$course; done
init-21learning-classes:
	make 1gy5.class.csv.load
	make 1gy7.class.csv.load
	make 1gy8.class.csv.load
	make 1gy11.class.csv.load


init-21learning: init-21learning-tables init-21learning-courses init-21learning-instructors init-21learning-classes


%.user.delete:
	echo "DELETE FROM auth_user WHERE id = $*;" | $(RUN_SQL)
students.delete:
	echo "DELETE FROM auth_user WHERE email LIKE '%student%';" | $(RUN_SQL)
students.orphans.delete:
	echo "DELETE FROM auth_user  ;" | $(RUN_SQL)

user.add_to.group.user_id:
user.add_to.group.%:
	@read -p "Role name: " group_name; \
	echo "INSERT INTO auth_membership (user_id, group_id) SELECT $$user_id as "user_id", auth_group.id as "group_id" FROM auth_group WHERE role = '$$group_name';" | $(RUN_SQL)
	
user.clean_activity.username:
user.clean_activity.%:
	@echo "Deleting all activity data of user $*"
	@echo "DELETE FROM useinfo where sid = '$*';" | $(RUN_SQL)
	@echo "DELETE FROM user_sub_chapter_progress WHERE user_id IN (SELECT id FROM auth_user WHERE username = '$*')" | $(RUN_SQL)
	
user.init:
	$(RSMANAGE) inituser

passwd:
	docker exec -i $(RUNESTONE_CONTAINER_ID) rsmanage resetpw



class.csv.ls:
%.class.csv.ls: data/%.csv
	cat $<
class.csv.load:
%.class.csv.load: data/%.csv
class.csv.load.%: data/%.csv
	# créer le groupe dans la base de données
	# make class.create.$*
	$(RSMANAGE_T) add-class --csvfile $(RUNESTONE_DIR)/$< --course $(COURSE) --class-name $(shell echo $* | tr "[:lower:]" "[:upper:]")
	docker cp $(RUNESTONE_CONTAINER_ID):/srv/web2py/tmp-passwords.csv data/passwords-$*.csv

class.empty:
%.class.empty:
	# créer le groupe dans la base de données
	# make class.create.$*
	$(RSMANAGE_T) empty-class --class-name $(shell echo $* | tr "[:lower:]" "[:upper:]")
	
class.passwd.show.class_name:	
class.passwd.show.%:
	@echo "Passwords of students of class $*"
	@cat data/passwords-$*.csv

class.ls.classname:
remote.class.ls.classname:
class.ls.%:
	echo "SELECT \
			auth_user.username, \
			auth_user.first_name, \
			auth_user.last_name, \
			auth_user.email, \
			role, \
			auth_user.course_name \
		FROM \
			auth_user \
			LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id \
			LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id \
		WHERE \
			ROLE = upper('$*')" \
		| $(RUN_SQL)


roles.ls:
	make ls-groups.sql.run
	

class.delete.id:
class.delete.%:
	echo "DELETE FROM auth_group_validity WHERE auth_group_id = $*;" | $(RUN_SQL) && \
	echo "DELETE FROM auth_group WHERE id = $*;" | $(RUN_SQL)

class.add_to_course.class:	
remote.class.add_to_course.class:	
class.add_to_course.%:
	make courses.ls
	@read -p "Course id: " course_id; \
	for student_id in $(shell echo "select user_id from auth_membership WHERE group_id IN (SELECT id FROM auth_group WHERE role LIKE '%$*%' LIMIT 1);" | $(RUN_SQL) -t); \
	do \
		echo adding student ID: $$student_id to course ID: $$course_id ; \
		echo "INSERT INTO user_courses (user_id, course_id) VALUES ($$student_id, $$course_id);" | $(RUN_SQL) ; \
	done;

class.switch_to.doi.class_name:
remote.class.switch_to.doi.class_name:
class.switch_to.doi.%:
	echo "UPDATE auth_user SET course_name = 'doi-1920-$*' \
		WHERE auth_user.id IN ( \
			SELECT \
			auth_user.id \
		FROM \
			auth_user \
			LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id \
			LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id \
		WHERE \
			ROLE = upper('$*') \
		)" | $(RUN_SQL)



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



db.git.init:
	git clone $(DB_BACKUP_GIT_REPO) $(DB_GIT_BACKUP_DIR)
	$(DB_BACKUP_GIT) checkout master

db.git.checkout.master:
db.git.checkout.branchname:
db.git.checkout.%:
	$(DB_BACKUP_GIT) checkout $%

db.git.diff:
	$(DB_BACKUP_GIT) diff HEAD HEAD^

	

db.git.backup:
	@$(PG_DUMP) > $(DB_GIT_BACKUP_DIR)/runestone-backup.sql
	cd $(DB_GIT_BACKUP_DIR)/ && git add . && git commit -m "backup $(DATETIME)" && git push



test.pipe:
	echo "salut" | docker exec -i $(DB_CONTAINER_ID) 'cat - > /home/message'
db.restore.targz-name:
db.restore.%:
	@echo Restoring SQL dump $* ...
	cp backup/db/$* backup/tmp.sql.gz
	# docker cp backup/tmp.sql.gz $(DB_CONTAINER_ID):/home
	docker stop $(RUNESTONE_CONTAINER_ID)
	docker stop $(PGADMIN_CONTAINER_ID)
	docker stop $(HASURA_CONTAINER_ID)
	$(DROPDB)
	$(CREATEDB)
	gunzip -c backup/db/$* | $(PSQL)
	docker start $(RUNESTONE_CONTAINER_ID)
	docker start $(PGADMIN_CONTAINER_ID)
	docker start $(HASURA_CONTAINER_ID)

db.restore.last:
	make db.restore.$(shell ls backup/db -1t | head -1)


db.backup.from-remote: remote.db.backup db.get-backup

db.restore.from-remote: db.backup.from-remote db.restore.last

db.get-backup: 
	rsync -raz $(REMOTE):$(SERVER_DIR)/backup/db/* ./backup/db --progress


	
db.backup.insert:
	@$(PG_DUMP) | gzip > backup/db/runestone-backup-$(DATETIME).sql.gz
	@du -sh backup/db/runestone-backup-$(DATETIME).sql.gz


# TODO: to be developped, use the pg_restore utility. Still have to decide (or
# distinguish) if we want te recreate the DB from scratch (delete and restore)
# or if an other solution would be better under certain circumstances.
db.restore:
	@echo "DB restore: not implemented yet"



#######################################################################
### gestion des questions
#######################################################################

shortanswer.divid:
shortanswer.%:
	echo "select u.username, u.first_name, u.last_name, answer from shortanswer_answers left join auth_user as u on sid = u.username where div_id = '$*';" | $(RUN_SQL)
	

questions.clean.coursename:
questions.clean.%:
	echo "delete from questions WHERE base_course = '$*';" | $(RUN_SQL)

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


#######################################################################
# Queries for managing the course Live
#######################################################################
useinfo.question.div_id:
remote.useinfo.question.div_id:
useinfo.question.%:
	@echo "SELECT DISTINCT question from questions WHERE name LIKE '$*';" | $(RUN_SQL)
	@echo "SELECT DISTINCT \
		auth_user.last_name AS \"Nom\", \
		auth_user.first_name AS \"Prénom\", \
		useinfo.act AS \"Réponse\", \
		useinfo.timestamp AS \"quand ?\" \
	FROM \
		useinfo \
		INNER JOIN ( \
			SELECT sid, div_id, MAX(timestamp) AS timestamp \
			FROM useinfo \
			GROUP BY sid, div_id \
		) AS max_useinfo ON useinfo.sid = max_useinfo.sid AND useinfo.div_id = max_useinfo.div_id \
			AND useinfo.timestamp = max_useinfo.timestamp \
		LEFT JOIN auth_user ON useinfo.sid = auth_user.username \
		LEFT JOIN questions ON useinfo.div_id = questions.name \
	WHERE \
		useinfo.div_id LIKE '$*' \
		AND useinfo.course_id LIKE '$(COURSE)' \
	ORDER BY auth_user.last_name, auth_user.first_name, useinfo.timestamp desc;" | $(RUN_SQL)

subchapter.ls.questions.subchapter_label:
subchapter.ls.questions.%:
	@echo "SELECT \
		name AS \"div_id\", \
		question, \
		question_type AS \"Donnée\" \
	FROM \
		questions \
	WHERE \
		subchapter = '$*' \
	ORDER BY \
		timestamp;" | $(RUN_SQL)
subchapter.ls.questions.short.subchapter_label:
subchapter.ls.questions.short.%:
	for machin in $(shell echo "SELECT \
		name AS \"div_id\" \
	FROM \
		questions \
	WHERE \
		subchapter = '$*' AND question IS NOT NULL \
	ORDER BY \
		timestamp;" | $(RUN_SQL) -qtAX); do make useinfo.question.$$machin COURSE=$(COURSE); done

args.%:
	make $* $(ARGS)

stats.save:
	make remote.subchapter.ls.questions.short.$(SUBSECTION) REMOTE_ARGS="COURSE=$(COURSE)" | grep -vE 'make\[.+\].+directory' > stats/$(SUBSECTION)-$(COURSE).txt
	
stats.view:
	code stats/$(SUBSECTION)-$(COURSE).txt

exams.clean.course_name:
exams.clean.doi:
exams.clean.%:
	@echo "removing HTML pages for examens in $(SERVER_DIR)/books/$*/published/$*/examens/*"
	$(SSH) 'cd runestone-server/books/$*/published/$*/examens/ && rm -f $(EXAM_CODE).html'

# exams.setup-code.course_name:
# exams.setup-code.%:
# 	cd $(SERVER_DIR)/books/$*/published/$*/examens/ && mv exa-$(EXAM).html $(EXAM_CODE).html

exams.push.course_name:
exams.push.doi:
exams.push.%:
	make course.push-all.$* KEEP_EXAMS=true
	$(SSH) 'cd $(SERVER_DIR)/books/$*/published/$*/examens/ && mv exa-$(EXAM).html $(EXAM_CODE).html'
	# make remote.exams.setup-code.$* REMOTE_ARGS="EXAM_CODE=$(EXAM_CODE)
	# EXAM=$(EXAM)"
	# must be done to prevent other exams to be visible
	#$(SSH) rm -f runestone-server/books/$*/published/$*/examens/exa*.html
	
doc.exams.push:
	@echo "make exams.push.doi EXAM=1-A EXAM_CODE=HKJHGZ"
doc.exams.clean:
	@echo "make exams.clean.doi EXAM=1-A EXAM_CODE=HKJHGZ"

# before doing that, generate the scores.sql file with something like
# 	xlsx2csv data/exams/exa1/exa1C-1gy8.xlsx -s 2 --ignoreempty | python scores2sql.py > data/exams/scores.tmp.sql
# 		the -s 2 takes the scores out of the sheet #2
exams.push.scores:
	cat data/exams/scores.tmp.sql | $(REMOTE_RUN_SQL)


course.time_spent:
	@echo " \
	SELECT \
		sid, \
		first_name, \
		last_name, \
		course_id, \
		max(timestamp) - min(timestamp) AS time_spent \
	FROM \
		useinfo_course_user_grades \
	WHERE \
		div_id LIKE '$(SECTION)' \
		AND course_id LIKE '$(COURSE)' \
	GROUP BY \
		sid, \
		course_id, \
		first_name, \
		last_name \
	HAVING \
		max(timestamp) - min(timestamp) > '00:00:00' \
	ORDER BY \
		time_spent ASC;" | $(REMOTE_RUN_SQL)



#######################################################################
# Quick update the components from local repo
#######################################################################
update-components.doi:
update-components.course-name:
update-components.%:
	# sync dev components repo to 21learning server
	@rsync -raz  ~/runestone-components/runestone/ $(REMOTE):$(SERVER_DIR)/tmp-runestone-components/ --progress
	# sync the remote repo with the python site-packages inside runestone container
	$(SSH) 'docker exec $(REMOTE_RUNESTONE_CONTAINER_ID) rsync -raz applications/runestone/tmp-runestone-components/ /usr/local/lib/python3.7/site-packages/runestone --progress'
	# rebuild the course
	$(SSH) 'cd $(SERVER_DIR) && make course.build-all.$*'


#######################################################################
# Pull remote dir into local dir
#######################################################################
pull.remote-dir:
pull.data:
pull.%:
	$(RSYNC) -raz $(REMOTE):$(SERVER_DIR)/$*/* ./$* --progress


update-activecode-js-local:
	# docker cp  ~/runestone-components/runestone/activecode/js/activecode.js
	# server2_runestone_1:/srv/web2py/applications/runestone/books/doi/published/doi/_static/activecode.js
	cp -f ~/runestone-components/runestone/activecode/js/activecode.js books/doi/published/doi/_static/


crontab.save:
	$(SSH) crontab -l > backup/crontab.txt