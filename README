## The layout

qwlmf yuik[]
arstg hnep'
zxcvb éj,./

QLWMF YUIKOK{}
ARSTG HNPEDP"
ZXCVB ÉJ,.?


## Supported platform
- linux
- windows

## Linux installation

To add a keyboard layout to X11/xkb/rules/evdev.xml

Open X11/xkb/rules/evdev.xml in an editor

Go to the end of the <layoutList> section (search for </layoutList>). Add the
following after the last </layout> tag, where:

layout_name is the file name of your keyboard layout in X11/xkb/symbols (in my case qwlm)
small_description a suitable short name (in my case am)
description an appropriate long name in one or more languages (in my case “americano-qwlm”)
eng a legal three letter (ISO 639-2) language code (e.g. eng for English)

template:

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

which in our case gives:

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

important directories

cd /usr/share/X11/xkb/rules/
cd /usr/share/X11/xkb/symbols

symlink which points to your new keyboard mapping

ln -s ~/dotfiles/keyboard/qwlm /usr/share/X11/xkb/symbols/qwlm

## Windows installation

Simply run the installer

## Et voilà!
