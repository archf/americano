XKBPATH = /usr/share/X11/xkb
LAYOUTS = $(XKBPATH)/symbols/codes $(XKBPATH)/symbols/qwlms

.PHONY: install

install: $(LAYOUTS)
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

de-gnome:
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'us'), ('xkb', 'ca')]"

$(LAYOUTS):
	ln -s $(CURDIR)/$(@F) $@

.PHONY: osx
osx:
	mkdir -p ~/Library/KeyBindings/
	cp osx/DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
	cp -r osx/karabiner ~/.config/
	sudo rsync -r osx/americano.bundle ~/Library/Keyboard\ Layouts
