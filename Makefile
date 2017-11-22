XKBPATH=/usr/share/X11/xkb
TARGET=$(XKBPATH)/rules/evdev.xml

LAYOUTS = $(XKBPATH)/symbols/code $(XKBPATH)/symbols/qwlm

.PHONY: install
	@echo 'All done! Enjoy !!!'
install: $(LAYOUTS)
	@echo "backing up '$(XKBPATH)/rules/evdev.xml'"
	/bin/cp ${TARGET} ${TARGET}.$(date +%Y%m%d)

	@echo 'replacing current evdev.xml'
	install -o root -g root evdev.xml ${TARGET}

	@echo 'All done! Enjoy !!!'

$(LAYOUTS):
	ln -s $(CURDIR)/$(@F) $@
