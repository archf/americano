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

# add it to your Desktop environment
.PHONY: de-mate de-gnome

de-mate:
	gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['code', 'qwlm', 'us', 'ca']"
	gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:shifts_toggle']"

de-gnome:
	# gsettings set org.gnome.desktop.input-sources mru-sources "[('xkb', 'code'), ('xkb', 'ca'), ('xkb', 'us'), ('xkb', 'qwlm')]"
	gsettings set org.gnome.desktop.input-sources xkb-options "['grp:shifts_toggle']"
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'us'), ('xkb', 'ca')]"

$(LAYOUTS):
	ln -s $(CURDIR)/$(@F) $@
