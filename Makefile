XKBPATH=/usr/share/X11/xkb

LAYOUTS = $(XKBPATH)/symbols/code $(XKBPATH)/symbols/qwlm

.PHONY: install
	@echo 'All done! Enjoy !!!'
install: $(LAYOUTS)
	ln -s /home/archf/dotfiles/americano/code /usr/share/X11/xkb/symbols/code
	ln -s /home/archf/dotfiles/americano/qwlm /usr/share/X11/xkb/symbols/qwlm
	@echo "backing up '$(XKBPATH)/rules/evdev.xml' to '$(XKBPATH)/rules/evdev.xml.$$(date +%Y%m%d)'"
	/bin/cp $(XKBPATH)/rules/evdev.xml $(XKBPATH)/rules/evdev.xml.$(date +%Y%m%d)
	@echo 'replacing $(XKBPATH)/rules/evdev.xml'
	/usr/bin/install -o root -g root evdev.xml $(XKBPATH)/rules/evdev.xml
	@apt install -y libxkbregistry-dev
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

.PHONY: osx
osx:
	mkdir -p ~/Library/KeyBindings/
	cp osx/DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
	cp -r osx/karabiner ~/.config/
	sudo rsync -r osx/americano.bundle ~/Library/Keyboard\ Layouts
