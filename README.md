## The layout(s)

### americano-qwlm (multilingual)

qwlmf yéik[]' <br/>
arstg huep' <br/>
zxcvb nj,./ <br/>

QLWMF YÉIKOK{} <br/>
ARSTG HUPEDP" <br/>
ZXCVB NJ,.? <br/>

### americano-code

qwlmf y:ik[]' <br/>
arstg huep' <br/>
zxcvb nj,./ <br/>

QLWMF YUIKOK{} <br/>
ARSTG HNPEDP" <br/>
ZXCVB ÉJ,.? <br/>

* no Level3(ralt_switch)
* no deadgrave

## Supported platforms

* linux
* windows
* MacOS (using Ukelele app)

## Installation

## Linux

Run `make install`. This will install the layout in `~/.config/xkb` (symlinks)

Then add keyboard to your Desktop Environment.

For gnome-desktop: `make de-gnome`
For mate-desktop: `make de-mate`

And restart your session or logout-login to make it available to your desktop
environnement.

See `make help` for more.

### MacOS

Run `make osx`.

This will:
    - install the layout
    - install DefaultKeyBinding.Dict config
    - install karabiner configuration

## Gnome related configuration

```bash
> gsettings list-recursively org.gnome.desktop.input-sources
org.gnome.desktop.input-sources current uint32 0
org.gnome.desktop.input-sources mru-sources [('xkb', 'code'), ('xkb', 'qwlm'), ('xkb', 'us'), ('xkb', 'ca')]
org.gnome.desktop.input-sources per-window false
org.gnome.desktop.input-sources show-all-sources false
org.gnome.desktop.input-sources sources [('xkb', 'qwlm'), ('xkb', 'code'), ('xkb', 'us'), ('xkb', 'ca')]
org.gnome.desktop.input-sources xkb-model 'pc105+inet'
org.gnome.desktop.input-sources xkb-options @as []
```

### Windows installation

Simply run the installer. You can edit the klc file and recompile if you wish.
You will need microsoft keyboad layout creator though.

## XKB and libcommon guide

- NoSymbol → acts as a placeholder if you want to define a later symbol
- VoidSymbol → like a /dev/null symbol : it produces no actions

Useful articles:

- ()[]

## Et voilà!

Feel free to improve!
