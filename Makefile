XKB_CONFIG_PATH = ~/.config/xkb
LAYOUTS = $(XKBPATH)/symbols/codes $(XKBPATH)/symbols/qwlm

.PHONY: install

install: de-gnome ## Install layout(s) to ~/.config/xkb
	@ln -sv $(CURDIR)/xkb $(XKB_CONFIG_PATH)
	@echo 'Restart your shell for changes to be effective (logout/login)'

# add it to your Desktop environment
.PHONY: de-mate de-gnome

de-mate: ## Install layout in Mate desktop environment.
	gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['code', 'qwlm', 'us', 'ca']"

de-gnome: ## Install layout in Gnome desktop environment.
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'us'), ('xkb', 'ca')]"

# TODO: ceck if we could replace `cp` with `install` on OSX
.PHONY: osx
osx: ## Install layout and karabiner configuration in OSX desktop environment
	mkdir -p ~/Library/KeyBindings/
	cp osx/DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
	cp -r osx/karabiner ~/.config/
	sudo rsync -r osx/americano.bundle ~/Library/Keyboard\ Layouts
