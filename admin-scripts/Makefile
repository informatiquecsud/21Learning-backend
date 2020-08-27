generate-completions.shell:
generate-completions.bash:
generate-completions.zsh:
generate-completions.%:
	@# $(shell _DBMANAGE_COMPLETE=source_$* dbmanage > dbmanage_$*_completions.sh)
	@echo 'eval "$$(_DBMANAGE_COMPLETE=source_$* dbmanage)"' | clip.exe
	@echo "paste into your Terminal with Ctrl+V or Maj+Insert"