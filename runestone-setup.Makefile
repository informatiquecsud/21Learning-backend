
runestone.init.branch-name: 
runestone.init.%: 
	make runestone.clone.branch.$*


runestone.clone.branch.:
runestone.clone.branch.%:
	$(SSH) git clone --single-branch --branch $* https://github.com/informatiquecsud/21Learning-backend.git runestone-server
