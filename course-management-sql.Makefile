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


