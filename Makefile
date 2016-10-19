XKBPATH=/usr/share/X11/xkb
TARGET=$(XKBPATH)/rules/evdev.xml

.PHONY: install
	@echo 'All done! Enjoy !!!'
install:
	@echo "backing up '$(XKBPATH)/rules/evdev.xml'"
	/bin/cp ${TARGET} ${TARGET}.$(date +%Y%m%d)

	@echo 'replacing current evdev.xml'
	/bin/cp evdev.xml ${TARGET}
	/bin/chown root:root ${TARGET}

	@echo 'create a symlink in $(XKBPATH)/symbols/qwlm versionned code symbol file'
	test -L $(XKBPATH)/symbols/qwlm || ln -s $(PWD)/code $(XKBPATH)/symbols/code

	@echo 'create a symlink in $(XKBPATH)/symbols/qwlm versionned qwlm symbol file'
	test -L $(XKBPATH)/symbols/qwlm || ln -s $(PWD)/qwlm $(XKBPATH)/symbols/qwlm

	@echo 'All done! Enjoy !!!'
