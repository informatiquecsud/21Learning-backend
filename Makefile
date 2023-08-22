# load active environment
include .env
export $(shell sed 's/=.*//' .env)

SSH_USER=root
SSH_PORT=22
SSH_HOST=$(RUNESTONE_HOST)

ifdef CUSTOM_SSH
	SSH_USER=$(CUSTOM_SSH_USER)
	SSH_PORT=$(CUSTOM_SSH_PORT)
	SSH_HOST=$(CUSTOM_SSH_HOST)
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

CLIP = clip.exe


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
REMOTE_PG_DUMP = docker exec -i $(REMOTE_DB_CONTAINER_ID) pg_dump -U $(POSTGRES_USER) -d $(POSTGRES_DB)
PG_RESTORE = docker exec -i $(DB_CONTAINER_ID) pg_restore $(POSTGRES_DB)  -U $(POSTGRES_USER) 
PSQL = docker exec -i $(DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
REMOTE_PSQL = docker exec -i $(REMOTE_DB_CONTAINER_ID) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)
DROPDB = docker exec -i $(DB_CONTAINER_ID) dropdb $(POSTGRES_DB) -U $(POSTGRES_USER)
CREATEDB = docker exec -i $(DB_CONTAINER_ID) createdb -T template0 $(POSTGRES_DB) -U $(POSTGRES_USER)

REMOTE_DROPDB = docker exec -i $(REMOTE_DB_CONTAINER_ID) dropdb $(POSTGRES_DB) -U $(POSTGRES_USER)
REMOTE_CREATEDB = docker exec -i $(REMOTE_DB_CONTAINER_ID) createdb -T template0 $(POSTGRES_DB) -U $(POSTGRES_USER)

COMPOSE_PGADMIN = -f docker-compose-pgadmin.yml

RUNESTONE_DIR = /srv/web2py/applications/runestone
WEB2PY_BOOKS = $(RUNESTONE_DIR)/books

# need to run the server-init rule for this to work
ifeq ($(ENV_NAME), local)
COMPOSE_OPTIONS = -f docker-compose-local.yml
else
COMPOSE_OPTIONS = -f docker-compose-production.yml
endif


COMPOSE = docker-compose -f docker-compose.yml $(COMPOSE_PGADMIN) $(COMPOSE_OPTIONS)


DB_GIT_BACKUP_DIR = backup/db/git
DB_BACKUP_GIT_REPO = git@bitbucket.org:donnerc/21learning-db-backups.git
DB_BACKUP_GIT = cd $(DB_GIT_BACKUP_DIR) && git


###########################################
## Docker management
###########################################
include docker.Makefile

###########################################
## Runestone setup
###########################################
include runestone-setup.Makefile

###########################################
## Service management
###########################################
include services.Makefile

###########################################
## Makefile rules specific to this context 
###########################################
ifdef ENV_NAME 
include $(ENV_NAME).context.Makefile
endif

clock-sync:
	sudo hwclock -s

git.install-config:
	curl https://gist.githubusercontent.com/donnerc/fc0312cc3431d9b3e675/raw/821a897e08e8e983a8fdf8add57e6b8cded5ed40/git-config.sh | sh


# switch active environment
env.use.contextname:
env.use.local:
env.use.new:
env.use.%:
	@echo "Using environment '$*'"
	@ln -sf .env.$* .env
env.active:
	@ls -al .env

# shows hot to load the env vars defined in .env
howto-load-dotenv:
	@echo 'set -a; source $(DOTENV_FILE); set +a' | $(CLIP)
howto-load-dotenv.envname:
howto-load-dotenv.%:
	@echo 'set -a; source .env.$* set +a' | $(CLIP)

echo-compose-options:
	@echo 'Compose options is: ' $(COMPOSE_OPTIONS)

.PHONY: no_targets__ list
no_targets__:
list:
    sh -c "$(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | sort"

push-old:
	$(RSYNC) -raz . $(REMOTE):$(SERVER_DIR) \
		--progress \
		--exclude=.git* \
		--exclude=venv \
		--exclude=ubuntu \
		--exclude=__pycache__ \
		--exclude=backup \
		--exclude=databases \
		--exclude=dashboard \
		--exclude=webtj \
		--exclude=data/pass* \
		--exclude=books \
		--exclude=.env*

# $(SSH) 'cd $(SERVER_DIR) && echo "RUNESTONE_REMOTE=true" >> $(DOTENV_FILE)'
# $(SSH) 'cd $(SERVER_DIR) && cp -f $(DOTENV_FILE) .env && chmod 600 .env'

push.dotenv:
	$(RSYNC) -r .env $(REMOTE):$(SERVER_DIR)/.env

push-env:
	$(RSYNC) -r $(DOTENV_FILE) $(REMOTE):$(SERVER_DIR)/$(DOTENV_FILE) 
	$(RSYNC) -r *.Makefile $(REMOTE):$(SERVER_DIR) 
	$(SSH) 'cd $(SERVER_DIR) && cp -f $(DOTENV_FILE) .env && chmod 600 .env && rm -f $(DOTENV_FILE)'
	


ssh.noconfig:	
	$(SSH)
ssh:	
	$(SSH) -F ./.ssh.config


dashboard.push:
	@$(RSYNC) -raz ~/dev/21learning/runestonedashboard/dist/spa/ $(SSH_USER)@$(SSH_HOST):$(SERVER_DIR)/dashboard/dist/spa/ --progress --delete
	@$(RSYNC) -raz webtj/ $(SSH_USER)@$(SSH_HOST):$(SERVER_DIR)/dashboard/dist/spa/statics/webtj/ --progress --delete


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

runestone.build-image:
	docker build -t runestone/server .
runestone.restart:
	$(COMPOSE) stop runestone
	$(COMPOSE) rm -f runestone
	$(COMPOSE) up -d runestone
runestone.exec-bash:
	docker exec -it $(RUNESTONE_CONTAINER_ID) bash
runestone.ps:
	$(COMPOSE) ps
runestone.update-components:
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
	docker cp $(RUNESTONE_CONTAINER_ID):/srv/web2py/applications/runestone/errors .
	
runestone-inspect-error.filename:
runestone-inspect-error.%:
	docker exec $(RUNESTONE_CONTAINER_ID) cat /srv/web2py/applications/runestone/errors/$*

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
	$(COMPOSE) up -d pgadmin


	
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
course.build.doi-2gy-2223-donc:
course.build.doi-1gy-2223-donc:
course.build.oci-2123-donc:
course.build.soi:
course.build.%:
	echo $(RUNESTONE_CONTAINER_ID)
	docker exec -i -w $(WEB2PY_BOOKS)/$* $(RUNESTONE_CONTAINER_ID) runestone build deploy
	cp -f webtj.tar.gz books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar -xf webtj.tar.gz
	
# Course management
course.build-all.coursename:
course.build-all.oxocard101:
course.build-all.overview:
course.build-all.doi-2gy-2223-donc:
course.build-all.doi-1gy-2223-donc:
course.build-all.oci-2123-donc:
course.build-all.doi:
course.build-all.soi:
course.build-all.%:
	@echo $(RUNESTONE_CONTAINER_ID)
	docker exec -i -w $(WEB2PY_BOOKS)/$* $(RUNESTONE_CONTAINER_ID) runestone build --all deploy
	# @docker exec -i -w $(SERVER_DIR) cp webtj.tar.gz
	# books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar
	# -xf webtj.tar.gz
	make copy.webtj.$*	
	
course.add_instructor.oxocard101:
course.add_instructor.overview:
course.add_instructor.doi:
course.add_instructor.concepts-programmation:
course.add_instructor.coursename:
course.add_instructor.%:
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

course.vuepress.push.einfach-informatik-zusatz-material:
course.vuepress.push.%:
	$(SSH) 'mkdir -p $(SERVER_DIR)/books/$*/published/$*'
	$(RSYNC) -raz books/$*/build/html/* $(REMOTE):$(SERVER_DIR)/books/$*/published/$*

course.live.doi-1gy-2021-donc:
course.live.doi-2gy-20-21:
course.live.%:
	watchmedo shell-command --debug-force-polling -p  "*.rst" -R -c 'make course.push.$*'
	
course.push.oxocard101:
course.push.overview:
course.push.doi:
course.push.concepts-programmation:
course.push.workshop-short:
course.push.doi-2gy-2324-donc:
course.push.doi-1gy-2324-donc:
course.push.oci-2123-donc:
course.push.oci-2224-donc:
course.push.fopp:
course.push.coursename:
course.push.soi:
course.push.%:
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz books/$* $(REMOTE):$(SERVER_DIR)/books/ \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build.$* KEEP_EXAMS=$(KEEP_EXAMS)
	#@"$(KEEP_EXAMS)" = "true" || (echo "deleting exams" && $(SSH) 'cd $(SERVER_DIR)/books/$*/published/$*/examens && rm -rf *')
	make update-skulpt.$*

course.push-all.oxocard101:
course.push-all.overview:
course.push-all.doi:
course.push-all.concepts-programmation:
course.push-all.doi-2gy-2223-donc:
course.push-all.doi-1gy-2223-donc:
course.push-all.oci-2123-donc:
course.push-all.oci-2224-donc:
course.push-all.fopp:
course.push-all.coursename:
course.push-all.soi:
course.push-all.%: 
	echo "Pushing course $* to $(RUNESTONE_HOST) ..."
	$(RSYNC) -raz books/$* $(REMOTE):$(SERVER_DIR)/books/ \
		--exclude=build \
		--exclude=published
	$(SSH) 'cd $(SERVER_DIR)/books/$* && cp -f pavement-dockerserver.py pavement.py'
	make remote.course.build-all.$* KEEP_EXAMS=$(KEEP_EXAMS)
	#@"$(KEEP_EXAMS)" = "true" || (echo "deleting exams" && $(SSH) 'cd
	#$(SERVER_DIR)/books/$*/published/$*/examens && rm -rf *')
	# make update-components.$*
	make update-skulpt.$*
	
course.push-all.all:
	@for course in $(COURSES); do make course.push-all.$$course; done

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
class.csv.load.classname:
class.csv.load.%: data/%.csv
	# créer le groupe dans la base de données
	# make class.create.$*
	$(RSMANAGE_T) add-class --csvfile $(RUNESTONE_DIR)/$< --course $(COURSE) --class-name '$(shell echo $* | tr "[:lower:]" "[:upper:]")'
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

class.add_to_course.classname:	
remote.class.add_to_course.classname:	
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

db.backup:
	mkdir -p backup/db
	$(PG_DUMP) | gzip > backup/db/runestone-backup-$(DATETIME).sql.gz
	du -sh backup/db/runestone-backup-$(DATETIME).sql.gz

remote.db.backup.physical:
	@mkdir -p backup/db/physical
	#$(SSH) 'docker exec $(REMOTE_DB_CONTAINER_ID) tar Ccf /var/lib/postgresql - data | gzip > backup/db/runestone-backup-copy-$(DATETIME).tar.gz'
	$(SSH) 'docker cp $(REMOTE_DB_CONTAINER_ID):/var/lib/postgresql/data $(SERVER_DIR)/backup/db/data'


remote.db.backup.dump:
	@mkdir -p backup/db
	@$(SSH) '$(REMOTE_PG_DUMP) | gzip' | pv > backup/db/runestone-backup-$(DATETIME).sql.gz
	@du -sh backup/db/runestone-backup-$(DATETIME).sql.gz
	@cp -rf backup/db/runestone-backup-$(DATETIME).sql.gz ~/cedon/OneDrive/runestone-db-backups

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

remote.db.restore.last:
	make db.backup.push.last
	make remote.service.stop.runestone
	make remote.service.stop.pgadmin
	make remote.service.stop.hasura

	$(REMOTE_DROPDB)
	$(REMOTE_CREATEDB)

	make remote.service.start.runestone
	$(SSH) 'gunzip -c $(SERVER_DIR)/backup/db/$(shell ls backup/db -1t | head -1) | $(REMOTE_PSQL)'
	make remote.service.start.pgadmin
	make remote.service.start.hasura



# remote.db.restore.last:
# 	remote.db.restore.$(shell ls backup/db -1t | head -1)

db.backup.push.last:
	$(SSH) 'mkdir -p $(SERVER_DIR)/backup/db'
	$(RSYNC) -raz backup/db/$(shell ls backup/db -1t | head -1) $(REMOTE):$(SERVER_DIR)/backup/db/ --progress


db.backup.from-remote: remote.db.backup.dump

deprecated.db.backup.from-remote: remote.db.backup db.get-backup

db.restore.from-remote: db.backup.from-remote db.restore.last

db.get-backup: 
	rsync -raz $(REMOTE):$(SERVER_DIR)/backup/db/* ./backup/db --progress --exclude git


	
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
# include table-completions.Makefile

# table-completions.update:


#######################################################################
# Auto-completion for sql queries
#######################################################################
# include query-completions.Makefile


# allows to update the query completion file
query-completions.update:
	@rm -f query-completions.Makefile && touch query-completions.Makefile
	@for query in $(shell ls sql); do echo $$query: >> query-completions.Makefile ; done
	@echo "New completion file"
	@cat -n query-completions.Makefile


include course-management-sql.Makefile

#######################################################################
# Update skulpt
#######################################################################
update-skulpt:
	@for course in $(COURSES); do echo "Updating skulpt for course $$course"; make update-skulpt.$$course; echo "done"; done

update-skulpt.%:
	rsync ./skulpt-dist/* $(REMOTE):$(SERVER_DIR)/books/$*/published/$*/_static/


#######################################################################
# Quick update the components from local repo
#######################################################################
update-components.doi:
update-components.concepts-programmation:
update-components.doi-2gy-2223-donc:
update-components.doi-1gy-2223-donc:
update-components.oci-2123-donc:
update-components.course-name:
update-components.%:
	# sync dev components repo to 21learning server
	@rsync -raz  ../components/runestone/ $(REMOTE):$(SERVER_DIR)/tmp-runestone-components/ --progress
	# sync the remote repo with the python site-packages inside runestone container
	$(SSH) 'docker exec $(REMOTE_RUNESTONE_CONTAINER_ID) rsync -raz applications/runestone/tmp-runestone-components/ /usr/local/lib/python3.7/site-packages/runestone --progress'
	# rebuild the course
	$(SSH) 'cd $(SERVER_DIR) && make course.build-all.$*'

update-components:
	@for course in $(COURSES); do echo "Updating course $$course"; make update-components.$$course; echo "done"; done
	@echo "Courses updated: " $(COURSES)

update-webtj:
	wget -r https://webtigerjython.ethz.ch/
	@rm -rf webtj
	@mv webtigerjython.ethz.ch webtj
	@curl https://webtigerjython.ethz.ch/javascripts/ace/theme-crimson_editor.js > webtj/javascripts/ace/theme-crimson_editor.js
	@curl https://webtigerjython.ethz.ch/javascripts/ace/mode-python.js > webtj/javascripts/ace/mode-python.js
	@curl https://webtigerjython.ethz.ch/javascripts/ace/mode-python2.js > webtj/javascripts/ace/mode-python2.js
	@curl https://webtigerjython.ethz.ch/javascripts/ace/mode-python3.js > webtj/javascripts/ace/mode-python3.js
	mkdir -p webtj/html/
	@curl https://webtigerjython.ethz.ch/html/debugger-pane.html > webtj/html/debugger-pane.html
	@curl https://webtigerjython.ethz.ch/html/info.html > webtj/html/info.html
	@curl https://webtigerjython.ethz.ch/stylesheets/info.css > webtj/stylesheets/info.css
	tar -czf webtj.tar.gz webtj
	rsync  webtj.tar.gz $(REMOTE):$(SERVER_DIR) --progress
	@for course in $(COURSES); do echo "copying new WebTJ to course $$course ..."; make remote.copy.webtj.$$course; done
	#@make update-components
	@echo "##################################################################"
	@echo "##  Updating WebTJ can cause problems : manually test WebTJ save functionality"
	@echo "##  Some files may have to be manually upgraded"
	@echo "##################################################################"

copy.webtj.coursename:
copy.webtj.%:
	cd $(SERVER_DIR) && rm -rf books/$*/published/$*/_static/webtj && cp -f webtj.tar.gz books/$*/published/$*/_static/ && cd books/$*/published/$*/_static/ && tar -xf webtj.tar.gz

update.21learning-components:
	for course in $(COURSES); do echo "copying new 21learning-components to course $$course ..."; make copy.21learning-components.$$course; done

copy.21learning-components.coursename:
copy.21learning-components.%:
	rsync -raz 21learning-components $(REMOTE):$(SERVER_DIR)/books/$*/published/$*/_static/ --progress --delete

push.file.filename:
push.file.%:
	rsync $* $(REMOTE):$(SERVER_DIR)


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
