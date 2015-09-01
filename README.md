## The layout

qwlmf yuik[]' <br/>
arstg hnep' <br/>
zxcvb éj,./ <br/>

QLWMF YUIKOK{} <br/>
ARSTG HNPEDP" <br/>
ZXCVB ÉJ,.? <br/>

## Supported platforms
* linux
* windows

## Installation

### Linux installation

You must add the keyboard layout in the  `/usr/shareX11/xkb/rules/evdev.xml`

Open `/usr/shareX11/xkb/rules/evdev.xml` in your favorite editor.

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

You might need to restart your session (logout-login) to make it available to 

### Windows installation

Simply run the installer. You can edit the klc file and recompile if you wish. You will need microsoft keyboad layout creator though.

## Et voilà!

Feel free to improve!
