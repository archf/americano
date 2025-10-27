XKB_CONFIG_PATH = ~/.config/xkb

.PHONY: help
help: ## Show this help menu.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"; section = "default"} /^##@/ {n = asort(targets, sorted); for (i = 1; i <= n; i++) {target = sorted[i]; printf "\t\033[36m%-15s\033[0m %s\n", target, descriptions[target]}; section = substr($$0, 5); printf "\n\033[1m%s\033[0m\n", section; delete targets; delete descriptions; count = 0} /^[a-zA-Z_0-9-]+:.*?##/ {targets[count] = $$1; descriptions[$$1] = $$2; count++} END {n = asort(targets, sorted); for (i = 1; i <= n; i++) {target = sorted[i]; printf "\t\033[36m%-15s\033[0m %s\n", target, descriptions[target]}}' $(MAKEFILE_LIST)

.PHONY: install
install: de-gnome ## Install xkb layout(s) to ~/.config/xkb
	@ln -sv $(CURDIR)/xkb $(XKB_CONFIG_PATH)
	@echo 'Restart your shell for changes to be effective (logout/login)'

# add it to your Desktop environment
.PHONY: de-mate de-gnome

de-mate: ## Add layout to Mate desktop environment.
	gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['code', 'qwlm', 'us', 'ca']"

# NOTE: When updating layout in Gnome remove and re-add it in the keyboard
# settings after a logout/login to make it effective. From my testing there
# are no way to acheive the same results with `gsettings`
de-gnome: ## Install layout in Gnome desktop environment.
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'us'), ('xkb', 'ca')]"

##@ Interception

.PHONY: interception-deps
interception-deps:
	sudo add-apt-repository ppa:deafmute/interception
	sudo apt install interception-tools interception-caps2esc
	# sudo apt install cmake libevdev-dev libudev-dev libyaml-cpp-dev libboost-dev

.PHONY: interception-dual-function-keys
interception-dual-function-keys: interception-deps
	git clone --detph 1 https://gitlab.com/interception/linux/plugins/dual-function-keys.git
	cd interception/dual-function-keys \; make && sudo make install

# FIXME: caps2esc breaks <C-BS> keymap somehow
# https://gitlab.com/interception/linux/plugins/caps2esc/-/blob/master/caps2esc.c?ref_type=heads
.PHONY: install-interception
install-interception: interception-deps ## Install interception and plugins: caps2esc, ...
	sudo install interception/caps2esc.yaml /etc/interception/udevmon.yaml
	sudo systemctl enable --now udevmon.service
	sudo systemctl status udevmon.service

##@ MacOS

.PHONY: osx
osx: karabiner ## Install layout and karabiner configuration in osx desktop environment.
	mkdir -p ~/Library/KeyBindings
	cp osx/DefaultKeyBinding.Dict ~/Library/KeyBindings/DefaultKeyBinding.Dict
	sudo rsync -r osx/americano.bundle ~/Library/Keyboard\ Layouts

# Karabiner-Elements will fail to detect configuration file changes and reload
# the configuration if karabiner.json is a symbolic link
# 	=> Ensure you create a symbolic link to the ~/.config/karabiner
# NOTE: on installation of Karabiner, ~/.config/karabiner will exist
.PHONY: karabiner
karabiner: | ~/.config/karabiner.bak ~/.config/karabiner ## Install Karabiner configuration.

~/.config/karabiner.bak:
	@mv $(basename $@) $@

~/.config/karabiner:
	@ln -sf $(CURDIR)/osx/$(@F) $@

# cp -r osx/karabiner ~/.config/
# @mkdir -p ~/.config/karabiner/assets/complex_modifications
# cp karabiner.d/* ~/.config/karabiner/assets/complex_modifications/

# sudo install udevmon.yaml /etc/interception/udevmon.yaml
# sudo install -D leftctrl.yaml /etc/interception/dual-function-keys/leftctrl.yaml
# sudo install keyboard.yaml /etc/interception/keyboard.yaml
# sudo install mouse.yaml /etc/interception/mouse.yaml
# sudo install hybrid-keyboard.yaml /etc/interception/hybrid-keyboard.yaml
# Generate device for a hybrid configuration
# s uinput -p -d  /dev/input/by-path/platform-i8042-serio-0-event-kbd| tee keyboard.yaml
# s uinput -p -d  /dev/input/by-path/platform-i8042-serio-1-event-mouse | tee mouse.yaml
