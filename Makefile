XKBPATH=/usr/share/X11/xkb

LAYOUTS = $(XKBPATH)/symbols/code $(XKBPATH)/symbols/qwlm

.PHONY: install
	@echo 'All done! Enjoy !!!'
install: $(LAYOUTS)
	@echo "backing up '$(XKBPATH)/rules/evdev.xml' to '$(XKBPATH)/rules/evdev.xml.$(date +%Y%m%d)'"
	/bin/cp $(XKBPATH)/rules/evdev.xml $(XKBPATH)/rules/evdev.xml.$(date +%Y%m%d)

	@echo 'replacing current evdev.xml'
	/usr/bin/install -o root -g root evdev.xml $(XKBPATH)/rules/evdev.xml

	@echo 'All done! Enjoy !!!'

# add it to your Desktop environment
.PHONY: de-mate de-gnome

de-mate:
	gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['code', 'qwlm', 'us', 'ca']"
	gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:shifts_toggle']"

de-gnome:
	# ubuntu 20.04+
	gsettings set org.gnome.desktop.input-sources xkb-options "['grp:shifts_toggle']"
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'ca+eng'), ('xkb', 'ca')]"

$(LAYOUTS):
	ln -s $(CURDIR)/$(@F) $@
