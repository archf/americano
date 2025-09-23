## The layout

### multilingual

qwlmf yéik[]' <br/>
arstg huep' <br/>
zxcvb nj,./ <br/>

QLWMF YÉIKOK{} <br/>
ARSTG HUPEDP" <br/>
ZXCVB NJ,.? <br/>

### english only (CODE)

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

## Supported platforms

* linux
* windows
* OSX (using Ukelele app)

## Installation

### Linux installation

#### Automated method

Run `make install`. This will overwrite the `/usr/shareX11/xkb/rules/evdev.xml`
provided by your OS and/or any change you previously made to it.

Then you should be able to add keyboard to you Desktop Environment.

For mate-desktop: `make de-mate`
For gnome-desktop: `make de-gnome`

#### Install manually

You must add the keyboard layout in the  `/usr/share/X11/xkb/rules/evdev.xml`

Open `/usr/share/X11/xkb/rules/evdev.xml` in your favorite editor.

Go to the end of the `<layoutList>` section (search for `</layoutList>`). Add the
following after the last </layout> tag, where:

layout_name is the file name of your keyboard layout in X11/xkb/symbols (in my case qwlm)
small_description a suitable short name (in my case am)
description an appropriate long name in one or more languages (in my case “americano-qwlm”)
eng a legal three letter (ISO 639-2) language code (e.g. eng for English)

template:
```xml
       <layout>
         <configItem>
           <name> layout_name </name>
           <shortDescription> small-description </shortDescription>
           <description> description </description>
           <languageList>
              <iso639Id> eng </iso639Id>
           </languageList>
         </configItem>
         <variantList/>
       </layout>
```

which in our case gives:

```xml
    <layout>
      <configItem>
        <name>qwlm</name>
        <shortDescription>am</shortDescription>
        <description>americano-qwlm</description>
        <languageList>
          <iso639Id>eng</iso639Id>
        </languageList>
      </configItem>
    </layout>
```

Quick commands

```bash
# edit the /usr/shareX11/xkb/rules/evdev.xml file
sudo vim /usr/share/X11/xkb/rules/evdev.xml

# add a symlink
sudo ln -s ~/dotfiles/americano/qwlm /usr/share/X11/xkb/symbols/qwlm
```

You might need to restart your session (logout-login) to make it available to your desktop environnement.

Gnome related configuration

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

Simply run the installer. You can edit the klc file and recompile if you wish. You will need microsoft keyboad layout creator though.

## XKB and libcommon guide

Useful articles:

- ()[]

## Et voilà!

Feel free to improve!
