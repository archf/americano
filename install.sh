#!/bin/sh

TARGET=/usr/share/X11/xkb/rules/evdev.xml
echo "'backing up '/usr/share/X11/xkb/rules/evdev.xml'"

/bin/cp ${TARGET} ${TARGET}.$(date +%Y%m%d)

echo 'replacing current evdev.xml'
/bin/cp evdev.xml ${TARGET}
/bin/chown root:root ${TARGET}

echo 'create a symlink in /usr/share/X11/xkb/symbols/qwlm pointing to local qwlm symbol file'
ln -s ~/dotfiles/americano/qwlm /usr/share/X11/xkb/symbols/qwlm

echo 'All done! Enjoy !!!'
