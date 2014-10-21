#!/bin/bash
#-Metadata----------------------------------------------#
#  Filename: kali.sh         (Last update: 2014-10-10)  #
#-Info--------------------------------------------------#
#  Personal post install script for Kali Linux.         #
#-Author(s)---------------------------------------------#
#  g0tmilk ~ http://blog.g0tmi1k.com                    #
#-Modified----------------------------------------------#
#  milports                                             #
#-Operating System--------------------------------------#
#  Designed for: Kali Linux 1.0.9 [x64] (VM - VMware)   #
#     Tested on: Kali Linux 1.0.0 - 1.0.9 [x64 & x84]   #
#-Notes-------------------------------------------------#
#  Run as root, after a fresh/clean install of Kali.    #
#                          ---                          #
#  Will set time zone & keyboard layout to UK & GB.     #
#                                                       #
#  Will check for if VM guest and install addons tools. #
#                                                       #
#  Skips installing Nessus, MSF Community & OpenVAS.    #
#                                                       #
#  Skips making the NIC MAC & hostname random on boot.  #
#                          ---                          #
#  Incomplete stuff/buggy search for '***'.             #
#                          ---                          #
#         ** This script is meant for _ME_. **          #
#  ** Wasn't designed with customization in mind. **    #
#      ** EDIT this to meet _YOUR_ requirements! **     #
#-------------------------------------------------------#

if [ 1 -eq 0 ]; then        # This is never true, thus it acts as block comments ;)
############ One liner - Pull the latest version and execute! ###########
wget -qO- https://raw.github.com/milports/os-scripts/master/kali.sh | bash
#########################################################################
fi

keyboardlayout="us"
timezone="Australia/Sydney"

##### (Optional) Setup remote connection via SSH
#services ssh start          # Start SSH to allow for remote connection
#ifconfig eth0               # Get the IP of the network interface
#--- Use the local computer (non Kali Linux) from here on out via SSH (copy/paste selected commands into prompt. Tip: Do only a few lines at once)
#ssh root@<ip>               # Replace '<ip>' with the value from before (ifconfig)


##### (Optional) Fixing display output for GUI programs.
export DISPLAY=:0.0         # Only required when executing via a SSH session


##### Fixing network manager
echo -e "\e[01;32m[+]\e[00m Fixing network manager"
service network-manager stop
#--- Fix 'device not managed' issue
file=/etc/network/interfaces; [ -e $file ] && cp -n $file{,.bkup}      # ...or: /etc/NetworkManager/NetworkManager.conf
sed  -i '/iface lo inet loopback/q' $file                              # ...or: sed -i 's/managed=.*/managed=true/' $file
#service network-manager restart
#--- Fix 'network disabled' issue
rm -f /var/lib/NetworkManager/NetworkManager.state
#--- Wait a little while before trying to connect out again (just to make sure)
service network-manager start
sleep 10


##### Fixing repositories (enable network repositories if it wasn't selected during install).
echo -e "\e[01;32m[+]\e[00m Fixing repositories"
file=/etc/apt/sources.list; [ -e $file ] && cp -n $file{,.bkup}
grep -q 'kali main non-free contrib' $file 2>/dev/null || echo "deb http://http.kali.org/kali kali main non-free contrib" >> $file
grep -q 'kali/updates main contrib non-free' $file 2>/dev/null || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >> $file
apt-get update


##### (Optional) Installing kernel headers
echo -e "\e[01;32m[+]\e[00m (Optional) Installing kernel headers"
apt-get -y -qq install gcc make linux-headers-$(uname -r)


##### (Optional) Checking to see if Kali is in a VM. If so, install "Virtual Machine Addons/Tools"  for a "better" virtual experiment
if $(dmidecode | grep -iq vmware); then
  ##### Installing Virtual Machines tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  echo -e "\e[01;32m[+]\e[00m Installing Virtual Machines tools"
  #--- VM -> Install VMware Tools.    Note: you may need to apply a patch: https://github.com/offensive-security/kali-vmware-tools-patches
  mkdir -p /mnt/cdrom/
  umount -f /mnt/cdrom 2>/dev/null
  sleep 1
  mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # Only checking first CD drive (if multiple)
  file=$(find /mnt/cdrom/ -maxdepth 1 -type f -name 'VMwareTools-*.tar.gz')
  if [[ $_mount == 0 ]] && [[ -z $file ]]; then
    echo -e "\e[01;31m[!]\e[00m Incorrect CD/ISO mounted. Skipping..."
    #read -p "Press the [enter] key to once the disk/iso has been manually mounted"    # Virtualbox loops. This would be a 'one time' notice.
  #fi
  elif [[ $_mount == 0 ]]; then                         # If there is a CD in (and its right!), try to install native Guest Additions
    apt-get -y -qq install gcc make linux-headers-$(uname -r)
    # Kernel 3.14+ - so it doesn't need patching any more
    #file=/usr/sbin/update-rc.d; [ -e $file ] && cp -n $file{,.bkup}
    #grep -q '^cups enabled' $file 2>/dev/null || echo "cups enabled" >> $file
    #grep -q '^vmware-tools enabled' $file 2>/dev/null || echo "vmware-tools enabled" >> $file
    #ln -sf /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
    cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/
    tar -zxf /tmp/VMwareTools-* -C /tmp/
    cd /tmp/vmware-tools-distrib/
    echo -e '\n' | perl vmware-install.pl
    cd - &>/dev/null
    umount -f /mnt/cdrom 2>/dev/null
  else                                             # The fallback is 'open vm tools'. ~ http://open-vm-tools.sourceforge.net/about.php
    echo -e "\e[01;31m[!]\e[00m VMware Tools CD/ISO isn't mounted. Skipping 'native' VMware tools, switching to 'Open VM Tools' instead"
    apt-get -y -qq install open-vm-toolbox
  fi
elif $(dmidecode | grep -iq virtualbox); then
  ##### (Optional) Installing Guest Additions. Note: Need VirtualBox 4.2.xx+ (http://docs.kali.org/general-use/kali-linux-virtual-box-guest)
  echo -e "\e[01;32m[+]\e[00m (Optional) Installing Guest Additions"
  #--- Devices -> Install Guest Additions CD image...
  mkdir -p /mnt/cdrom/
  while [[ ! -e /mnt/cdrom/VBoxLinuxAdditions.run ]]; do       # Let's force them to have the correct CD in... (WARNING: breaks unattended install!)
    umount -f /mnt/cdrom 2>/dev/null
    sleep 1
    mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null;             # Only checking first CD drive (if multiple)
    if [[ ! -e /mnt/cdrom/VBoxLinuxAdditions.run ]]; then
      echo -e "\e[01;31m[!]\e[00m Incorrect CD/ISO mounted"
      echo -e "\e[01;33m[i]\e[00m   To Mount: 'Devices -> Install Guest Additions CD image'"
      echo -ne "\e[01;33m[i]\e[00m "; read -p "Press the [enter] key to once the CD/ISO has been manually mounted"
    fi
  done
  apt-get -y -qq install gcc make linux-headers-$(uname -r)
  cp -f /mnt/cdrom/VBoxLinuxAdditions.run /tmp/
  chmod 0755 /tmp/VBoxLinuxAdditions.run
  /tmp/VBoxLinuxAdditions.run --nox11
  umount -f /mnt/cdrom 2>/dev/null
fi
#--- Install parallel tools
#Virtual Machine -> Install Parallels Tools
#cd /media/Parallel\ Tools/
#./install
# <***insert bash fu here***>
#--- Slow mouse?
#apt-get -y -qq install xserver-xorg-input-vmmouse


##### Checking to see if there is a second ethernet card
ifconfig eth1 &>/devnull
if [[ $? == 0 ]]; then
  ##### Setting up static IP address on eth1
  echo -e "\e[01;32m[+]\e[00m Setting up static IP (192.168.155.175/24) address on eth1"
  ifconfig eth1 192.168.155.175/24
  file=/etc/network/interfaces; [ -e $file ] && cp -n $file{,.bkup}
  grep -q '^iface eth1 inet static' $file 2>/dev/null || echo -e '\nauto eth1\niface eth1 inet static\n    address 192.168.155.175\n    netmask 255.255.255.0\n    gateway 192.168.155.1' >> $file
fi


##### Setting static + protecting DNS name servers. Note: May cause issues with forced values (e.g. captive portals etc)
echo -e "\e[01;32m[+]\e[00m Setting static + protecting DNS name servers"
file=/etc/resolv.conf; [ -e $file ] && cp -n $file{,.bkup}
chattr -i $file 2>/dev/null
#--- Remove duplicate results
#uniq $file > $file.new
#mv $file{.new,}
#--- Use OpenDNS DNS
#echo -e 'nameserver 208.67.222.222\nnameserver 208.67.220.220' > $file
#--- Use Google DNS
echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > $file
#--- Protect it
chattr +i $file 2>/dev/null


if [ 1 -eq 0 ]; then        # This is never true, thus it acts as block comments ;)
##### Updating hostname (but not domain name)
echo -e "\e[01;32m[+]\e[00m Updating hostname"
hostname="kali"
#--- Change it now
hostname "$hostname"
#--- Make sure it sticks after reboot
file=/etc/hostname; [ -e $file ] && cp -n $file{,.bkup}
echo "$(hostname)" > $file
#--- Set host file
file=/etc/hosts; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/127.0.1.1.*/127.0.1.1  '$hostname'/' $file    #echo -e "127.0.0.1  localhost.localdomain localhost\n127.0.1.1  $hostname" > $file    #$hostname.$domainname
#--- Check
#hostname; hostname -f
fi


##### Updating location information (keyboard layout & time zone) - set either value to "" to skip.
echo -e "\e[01;32m[+]\e[00m Updating location information (keyboard layout & time zone)"
#--- Configure keyboard layout
if [ ! -z "$keyboardlayout" ]; then
  file=/etc/default/keyboard; [ -e $file ] && cp -n $file{,.bkup}
  sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'$keyboardlayout'"/' $file   #; dpkg-reconfigure keyboard-configuration -u       #<--- May automate (need to restart xserver for effect)
  #dpkg-reconfigure keyboard-configuration   #dpkg-reconfigure console-setup                                           #<--- Doesn't automate
fi
#--- Changing time zone
[[ -z "$timezone" ]] || ln -sf /usr/share/zoneinfo/$timezone /etc/localtime   #ln -sf /usr/share/zoneinfo/Etc/GMT
#--- Installing ntp to help keep time in sync (helpful when resuming VMs)
apt-get -y -qq install ntp
#--- Start service
service ntp restart
#--- Add to start up
update-rc.d ntp enable 2>/dev/null
#--- Check
#date
#--- Only used for stats at the end
start_time=$(date +%s)


##### Updating software from repositories
echo -e "\e[01;32m[+]\e[00m Updating OS from repositories"
for ITEM in clean autoremove autoclean; do apt-get -y -qq $ITEM; done
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get -y -q dist-upgrade --fix-missing
#--- Enable bleeding edge ~ http://www.kali.org/kali-monday/bleeding-edge-kali-repositories/
#file=/etc/apt/sources.list; [ -e $file ] && cp -n $file{,.bkup}
#grep -q 'kali-bleeding-edge' $file 2>/dev/null || echo -e "\n\n## Bleeding edge\ndeb http://repo.kali.org/kali kali-bleeding-edge main" >> $file
#apt-get update && apt-get -y -qq upgrade


##### Fixing audio issues
#echo -e "\e[01;32m[+]\e[00m Fixing audio issues"
#--- PulseAudio warnings
#file=/etc/default/pulseaudio; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/^PULSEAUDIO_SYSTEM_START=.*/PULSEAUDIO_SYSTEM_START=1/' $file
#--- Unmute on startup
#apt-get -y -qq install alsa-utils
#--- Set volume now
#amixer set Master unmute >/dev/null
#amixer set Master 50% >/dev/null


##### Configuring grub
echo -e "\e[01;32m[+]\e[00m Configuring grub"
file=/etc/default/grub; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' $file                                # Time out
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' $file   # TTY resolution    #GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318 quiet"   (crashes VM/vmwgfx)
update-grub


##### Disabling login manager (console login - non GUI)
#echo -e "\e[01;32m[+]\e[00m Disabling login (console login - non GUI)"
#--- Disable GUI login screen
#apt-get -y -qq install chkconfig
#chkconfig gdm3 off                                 # ...or: mv -f /etc/rc2.d/S19gdm3 /etc/rc2.d/K17gdm           #file=/etc/X11/default-display-manager; [ -e $file ] && cp -n $file{,.bkup}   #echo /bin/true > $file
#--- Enable auto (gui) login
#file=/etc/gdm3/daemon.conf; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' $file
#sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' $file
#--- Shortcut for when you want to start GUI
#ln -sf /usr/sbin/gdm3 /usr/bin/startx


##### Configuring startup (randomize the hostname, eth0 & wlan0s MAC address)
echo -e "\e[01;32m[+]\e[00m Configuring startup (randomize the hostname, eth0 & wlan0s MAC address)"
#--- Start up
file=/etc/rc.local; [ -e $file ] && cp -n $file{,.bkup}
grep -q "macchanger" $file 2>/dev/null || sed -i 's#^exit 0#for INT in eth0 wlan0; do\n  ifconfig $INT down\n  '$(whereis macchanger)' -r $INT \&\& sleep 3\n  ifconfig $INT up\ndone\n\n\nexit 0#' $file
grep -q "hostname" $file 2>/dev/null || sed -i 's#^exit 0#'$(whereis hostname)' $(cat /dev/urandom | tr -dc "A-Za-z" | head -c8)\nexit 0#' $file
#--- On demand (kinda broken)
##file=/etc/init.d/macchanger; [ -e $file ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\nfor INT in eth0 wlan0; do\n  echo "Randomizing: $INT"\n  ifconfig $INT down\n  macchanger -r $INT\n  sleep 3\n  ifconfig $INT up\n  echo "--------------------"\ndone\nexit 0' > $file
##chmod 0500 $file
#--- Auto on interface change state (untested)
##file=/etc/network/if-pre-up.d/macchanger; [ -e $file ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > $file
##chmod 0500 $file


##### Configuring GNOME 3
echo -e "\e[01;32m[+]\e[00m Configuring GNOME 3"
#--- Move bottom panel to top panel
gsettings set org.gnome.gnome-panel.layout toplevel-id-list "['top-panel']"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/toplevel-id "'top-panel'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/toplevel-id "'top-panel'"
#--- Panel position
dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/orientation "'top'"    #"'right'"   # Issue with window-list
#--- Panel ordering
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-type "'start'"
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-type "'start'"   # "'center'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-index 5          #0
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-index 1
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-index 2
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-index 3
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-index 4
#--- Enable auto hide
#dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/auto-hide true
#--- Add top 10 tools to toolbar
dconf load /org/gnome/gnome-panel/layout/objects/object-10-top/ << EOT
[instance-config]
menu-path='applications:/Kali/Top 10 Security Tools/'
tooltip='Top 10 Security Tools'

[/]
object-iid='PanelInternalFactory::MenuButton'
toplevel-id='top-panel'
pack-type='start'
pack-index=4
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-10-top']/")"
#--- Show desktop
dconf load /org/gnome/gnome-panel/layout/objects/object-show-desktop/ << EOT
[/]
object-iid='WnckletFactory::ShowDesktopApplet'
toplevel-id='top-panel'
pack-type='end'
pack-index=0
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-show-desktop']/")"
#--- Fix icon top 10 shortcut icon
#convert /usr/share/icons/hicolor/48x48/apps/k.png -negate /usr/share/icons/hicolor/48x48/apps/k-invert.png
#/usr/share/icons/gnome/48x48/status/security-medium.png
#--- Enable only two workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 2   #gconftool-2 --type int --set /apps/metacity/general/num_workspaces 2 #dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/instance-config/num-rows 4
gsettings set org.gnome.shell.overrides dynamic-workspaces false
#--- Smaller title bar
#sed -i "/title_vertical_pad/s/value=\"[0-9]\{1,2\}\"/value=\"0\"/g" /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
#sed -i 's/title_scale=".*"/title_scale="small"/g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Droid Bold 10'   # 'Cantarell Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
#--- Hide desktop icon
dconf write /org/gnome/nautilus/desktop/computer-icon-visible false
#--- Add "open with terminal" on right click menu
apt-get -y -qq install nautilus-open-terminal
#--- Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?))
apt-get -y -qq install numlockx
file=/etc/gdm3/Init/Default; [ -e $file ] && cp -n $file{,.bkup}     #/etc/rc.local
grep -q '^/usr/bin/numlockx' $file 2>/dev/null || sed -i 's#exit 0#if [ -x /usr/bin/numlockx ]; then\n /usr/bin/numlockx on\nfi\nexit 0#' $file   # GNOME
#--- Change wallpaper & login (happens later)
#wget http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png -P /usr/share/wallpapers/
#gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png'
#cp -f /usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png /usr/share/images/desktop-base/login-background.png
#--- Restart GNOME panel to apply/take effect (need to restart xserver for effect)
#killall -q -w gnome-panel >/dev/null && gnome-panel&   # Still need to logoff!


##### Installing & configuring xfce4 ~ desktop environment
echo -e "\e[01;32m[+]\e[00m Installing & configuring xfce4"
apt-get -y -qq install wget
apt-get -y -qq install xfce4 xfce4-places-plugin
#apt-get -y -qq install shiki-colors-xfwm-theme    # theme
#--- Configuring XFCE4
mv -f /usr/bin/startx{,-gnome}
ln -sf /usr/bin/startx{fce4,}
mkdir -p /root/.config/xfce4/{desktop,menu,panel,xfconf,xfwm4}/
mkdir -p /root/.config/xfce4/panel/launcher-1{5,6,7,9}
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/
mkdir -p /root/.themes/
echo -e "[Wastebasket]\nrow=2\ncol=0\n\n[File System]\nrow=1\ncol=0\n\n[Home]\nrow=0\ncol=0" > /root/.config/xfce4/desktop/icons.screen0.rc
echo -e "show_button_icon=true\nshow_button_label=false\nlabel=Places\nshow_icons=true\nshow_volumes=true\nmount_open_volumes=false\nshow_bookmarks=true\nshow_recent=true\nshow_recent_clear=true\nshow_recent_number=10\nsearch_cmd=" > /root/.config/xfce4/panel/places-23.rc
echo -e "card=PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer\ntrack=Master\ncommand=xfce4-mixer" > /root/.config/xfce4/panel/xfce4-mixer-plugin-24.rc
echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Iceweasel\nComment=Browse the World Wide Web\nGenericName=Web Browser\nX-GNOME-FullName=Iceweasel Web Browser\nExec=iceweasel %u\nTerminal=false\nX-MultipleArgs=false\nType=Application\nIcon=iceweasel\nCategories=Network;WebBrowser;\nMimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;\nStartupWMClass=Iceweasel\nStartupNotify=true\nX-XFCE-Source=file:///usr/share/applications/iceweasel.desktop" > /root/.config/xfce4/panel/launcher-15/13684522587.desktop
echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nExec=exo-open --launch TerminalEmulator\nIcon=utilities-terminal\nStartupNotify=false\nTerminal=false\nCategories=Utility;X-XFCE;X-Xfce-Toplevel;\nOnlyShowIn=XFCE;\nName=Terminal Emulator\nName[en_GB]=Terminal Emulator\nComment=Use the command line\nComment[en_GB]=Use the command line\nX-XFCE-Source=file:///usr/share/applications/exo-terminal-emulator.desktop" > /root/.config/xfce4/panel/launcher-16/13684522758.desktop
echo -e "[Desktop Entry]\nType=Application\nVersion=1.0\nName=Geany\nName[en_GB]=Geany\nGenericName=Integrated Development Environment\nGenericName[en_GB]=Integrated Development Environment\nComment=A fast and lightweight IDE using GTK2\nComment[en_GB]=A fast and lightweight IDE using GTK2\nExec=geany %F\nIcon=geany\nTerminal=false\nCategories=GTK;Development;IDE;\nMimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;\nStartupNotify=true\nX-XFCE-Source=file:///usr/share/applications/geany.desktop" > /root/.config/xfce4/panel/launcher-17/13684522859.desktop
echo -e "[Desktop Entry]\nVersion=1.0\nName=Application Finder\nName[en_GB]=Application Finder\nComment=Find and launch applications installed on your system\nComment[en_GB]=Find and launch applications installed on your system\nExec=xfce4-appfinder\nIcon=xfce4-appfinder\nStartupNotify=true\nTerminal=false\nType=Application\nCategories=X-XFCE;Utility;\nX-XFCE-Source=file:///usr/share/applications/xfce4-appfinder.desktop" > /root/.config/xfce4/panel/launcher-19/136845425410.desktop
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-appfinder" version="1.0">\n  <property name="category" type="string" value="All"/>\n  <property name="window-width" type="int" value="640"/>\n  <property name="window-height" type="int" value="480"/>\n  <property name="close-after-execute" type="bool" value="true"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-appfinder.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-desktop" version="1.0">\n  <property name="backdrop" type="empty">\n    <property name="screen0" type="empty">\n      <property name="monitor0" type="empty">\n        <property name="brightness" type="empty"/>\n        <property name="color1" type="empty"/>\n        <property name="color2" type="empty"/>\n        <property name="color-style" type="empty"/>\n        <property name="image-path" type="empty"/>\n        <property name="image-show" type="empty"/>\n        <property name="last-image" type="empty"/>\n        <property name="last-single-image" type="empty"/>\n      </property>\n    </property>\n  </property>\n  <property name="desktop-icons" type="empty">\n    <property name="file-icons" type="empty">\n      <property name="show-removable" type="bool" value="true"/>\n      <property name="show-trash" type="bool" value="false"/>\n      <property name="show-filesystem" type="bool" value="false"/>\n      <property name="show-home" type="bool" value="false"/>\n    </property>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-keyboard-shortcuts" version="1.0">\n  <property name="commands" type="empty">\n    <property name="default" type="empty">\n      <property name="&lt;Alt&gt;F2" type="empty"/>\n      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="empty"/>\n      <property name="XF86Display" type="empty"/>\n      <property name="&lt;Super&gt;p" type="empty"/>\n      <property name="&lt;Primary&gt;Escape" type="empty"/>\n    </property>\n    <property name="custom" type="empty">\n      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>\n      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>\n      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>\n      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>\n      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>\n      <property name="override" type="bool" value="true"/>\n    </property>\n  </property>\n  <property name="xfwm4" type="empty">\n    <property name="default" type="empty">\n      <property name="&lt;Alt&gt;Insert" type="empty"/>\n      <property name="Escape" type="empty"/>\n      <property name="Left" type="empty"/>\n      <property name="Right" type="empty"/>\n      <property name="Up" type="empty"/>\n      <property name="Down" type="empty"/>\n      <property name="&lt;Alt&gt;Tab" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="empty"/>\n      <property name="&lt;Alt&gt;Delete" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="empty"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="empty"/>\n      <property name="&lt;Alt&gt;F4" type="empty"/>\n      <property name="&lt;Alt&gt;F6" type="empty"/>\n      <property name="&lt;Alt&gt;F7" type="empty"/>\n      <property name="&lt;Alt&gt;F8" type="empty"/>\n      <property name="&lt;Alt&gt;F9" type="empty"/>\n      <property name="&lt;Alt&gt;F10" type="empty"/>\n      <property name="&lt;Alt&gt;F11" type="empty"/>\n      <property name="&lt;Alt&gt;F12" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="empty"/>\n      <property name="&lt;Alt&gt;space" type="empty"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="empty"/>\n      <property name="&lt;Super&gt;Tab" type="empty"/>\n      <property name="&lt;Control&gt;F1" type="empty"/>\n      <property name="&lt;Control&gt;F2" type="empty"/>\n      <property name="&lt;Control&gt;F3" type="empty"/>\n      <property name="&lt;Control&gt;F4" type="empty"/>\n      <property name="&lt;Control&gt;F5" type="empty"/>\n      <property name="&lt;Control&gt;F6" type="empty"/>\n      <property name="&lt;Control&gt;F7" type="empty"/>\n      <property name="&lt;Control&gt;F8" type="empty"/>\n      <property name="&lt;Control&gt;F9" type="empty"/>\n      <property name="&lt;Control&gt;F10" type="empty"/>\n      <property name="&lt;Control&gt;F11" type="empty"/>\n      <property name="&lt;Control&gt;F12" type="empty"/>\n    </property>' >> /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
echo -e '    <property name="custom" type="empty">\n      <property name="&lt;Control&gt;F3" type="string" value="workspace_3_key"/>\n      <property name="&lt;Control&gt;F4" type="string" value="workspace_4_key"/>\n      <property name="&lt;Control&gt;F5" type="string" value="workspace_5_key"/>\n      <property name="&lt;Control&gt;F6" type="string" value="workspace_6_key"/>\n      <property name="&lt;Control&gt;F7" type="string" value="workspace_7_key"/>\n      <property name="&lt;Control&gt;F8" type="string" value="workspace_8_key"/>\n      <property name="&lt;Control&gt;F9" type="string" value="workspace_9_key"/>\n      <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="string" value="right_workspace_key"/>\n      <property name="Left" type="string" value="left_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>\n      <property name="Up" type="string" value="up_key"/>\n      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>\n      <property name="&lt;Alt&gt;F6" type="string" value="stick_window_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="string" value="down_workspace_key"/>\n      <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>\n      <property name="&lt;Alt&gt;F9" type="string" value="hide_window_key"/>\n      <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>\n      <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>\n      <property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>\n      <property name="Escape" type="string" value="cancel_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="string" value="move_window_workspace_1_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="string" value="move_window_workspace_2_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="string" value="move_window_workspace_3_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="string" value="move_window_workspace_4_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="string" value="move_window_workspace_5_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="string" value="move_window_workspace_6_key"/>\n      <property name="Down" type="string" value="down_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="string" value="lower_window_key"/>\n      <property name="&lt;Alt&gt;F12" type="string" value="above_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="string" value="move_window_workspace_8_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="string" value="move_window_workspace_9_key"/>\n      <property name="Right" type="string" value="right_key"/>\n      <property name="&lt;Alt&gt;F10" type="string" value="maximize_window_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="string" value="up_workspace_key"/>\n      <property name="&lt;Control&gt;F10" type="string" value="workspace_10_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="string" value="move_window_workspace_7_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="string" value="move_window_next_workspace_key"/>\n      <property name="&lt;Alt&gt;Delete" type="string" value="del_workspace_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="string" value="left_workspace_key"/>\n      <property name="&lt;Control&gt;F12" type="string" value="workspace_12_key"/>\n      <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>\n      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="string" value="raise_window_key"/>\n      <property name="&lt;Alt&gt;Insert" type="string" value="add_workspace_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="string" value="move_window_prev_workspace_key"/>\n      <property name="&lt;Control&gt;F2" type="string" value="workspace_2_key"/>\n      <property name="&lt;Control&gt;F1" type="string" value="workspace_1_key"/>\n      <property name="&lt;Control&gt;F11" type="string" value="workspace_11_key"/>\n      <property name="override" type="bool" value="true"/>\n    </property>\n  </property>\n  <property name="providers" type="array">\n    <value type="string" value="xfwm4"/>\n    <value type="string" value="commands"/>\n  </property>\n</channel>' >> /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-mixer" version="1.0">\n  <property name="active-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>\n  <property name="volume-step-size" type="uint" value="5"/>\n  <property name="sound-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>\n  <property name="sound-cards" type="empty">\n    <property name="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer" type="array">\n      <value type="string" value="Master"/>\n    </property>\n  </property>\n  <property name="window-height" type="int" value="400"/>\n  <property name="window-width" type="int" value="738"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-mixer.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-panel" version="1.0">\n  <property name="panels" type="uint" value="1">\n    <property name="panel-0" type="empty">\n      <property name="position" type="string" value="p=6;x=0;y=0"/>\n      <property name="length" type="uint" value="100"/>\n      <property name="position-locked" type="bool" value="true"/>\n      <property name="plugin-ids" type="array">\n        <value type="int" value="1"/>\n        <value type="int" value="15"/>\n        <value type="int" value="16"/>\n        <value type="int" value="17"/>\n        <value type="int" value="21"/>\n        <value type="int" value="23"/>\n        <value type="int" value="19"/>\n        <value type="int" value="3"/>\n        <value type="int" value="24"/>\n        <value type="int" value="6"/>\n        <value type="int" value="2"/>\n        <value type="int" value="5"/>\n        <value type="int" value="4"/>\n        <value type="int" value="25"/>\n      </property>\n      <property name="background-alpha" type="uint" value="90"/>\n    </property>\n  </property>\n  <property name="plugins" type="empty">\n    <property name="plugin-1" type="string" value="applicationsmenu">\n      <property name="button-icon" type="string" value="kali-menu"/>\n      <property name="show-button-title" type="bool" value="false"/>\n      <property name="show-generic-names" type="bool" value="true"/>\n      <property name="show-tooltips" type="bool" value="true"/>\n    </property>\n    <property name="plugin-2" type="string" value="actions"/>\n    <property name="plugin-3" type="string" value="tasklist"/>\n    <property name="plugin-4" type="string" value="pager">\n      <property name="rows" type="uint" value="1"/>\n    </property>\n    <property name="plugin-5" type="string" value="clock">\n      <property name="digital-format" type="string" value="%R, %A %d %B %Y"/>\n    </property>\n    <property name="plugin-6" type="string" value="systray">\n      <property name="names-visible" type="array">\n        <value type="string" value="networkmanager applet"/>\n      </property>\n    </property>\n    <property name="plugin-15" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522587.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-16" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522758.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-17" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522859.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-21" type="string" value="applicationsmenu">\n      <property name="custom-menu" type="bool" value="true"/>\n      <property name="custom-menu-file" type="string" value="/root/.config/xfce4/menu/top10.menu"/>\n      <property name="button-icon" type="string" value="security-medium"/>\n      <property name="show-button-title" type="bool" value="false"/>\n      <property name="button-title" type="string" value="Top 10"/>\n    </property>\n    <property name="plugin-19" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="136845425410.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-22" type="empty">\n      <property name="base-directory" type="string" value="/root"/>\n      <property name="hidden-files" type="bool" value="false"/>\n    </property>\n    <property name="plugin-23" type="string" value="places"/>\n    <property name="plugin-24" type="string" value="xfce4-mixer-plugin"/>\n    <property name="plugin-25" type="string" value="showdesktop"/>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-settings-editor" version="1.0">\n  <property name="window-width" type="int" value="600"/>\n  <property name="window-height" type="int" value="380"/>\n  <property name="hpaned-position" type="int" value="200"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-settings-editor.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfwm4" version="1.0">\n  <property name="general" type="empty">\n    <property name="activate_action" type="string" value="bring"/>\n    <property name="borderless_maximize" type="bool" value="true"/>\n    <property name="box_move" type="bool" value="false"/>\n    <property name="box_resize" type="bool" value="false"/>\n    <property name="button_layout" type="string" value="O|SHMC"/>\n    <property name="button_offset" type="int" value="0"/>\n    <property name="button_spacing" type="int" value="0"/>\n    <property name="click_to_focus" type="bool" value="true"/>\n    <property name="focus_delay" type="int" value="250"/>\n    <property name="cycle_apps_only" type="bool" value="false"/>\n    <property name="cycle_draw_frame" type="bool" value="true"/>\n    <property name="cycle_hidden" type="bool" value="true"/>\n    <property name="cycle_minimum" type="bool" value="true"/>\n    <property name="cycle_workspaces" type="bool" value="false"/>\n    <property name="double_click_time" type="int" value="250"/>\n    <property name="double_click_distance" type="int" value="5"/>\n    <property name="double_click_action" type="string" value="maximize"/>\n    <property name="easy_click" type="string" value="Alt"/>\n    <property name="focus_hint" type="bool" value="true"/>\n    <property name="focus_new" type="bool" value="true"/>\n    <property name="frame_opacity" type="int" value="100"/>\n    <property name="full_width_title" type="bool" value="true"/>\n    <property name="inactive_opacity" type="int" value="100"/>\n    <property name="maximized_offset" type="int" value="0"/>\n    <property name="move_opacity" type="int" value="100"/>\n    <property name="placement_ratio" type="int" value="20"/>\n    <property name="placement_mode" type="string" value="center"/>\n    <property name="popup_opacity" type="int" value="100"/>\n    <property name="mousewheel_rollup" type="bool" value="true"/>\n    <property name="prevent_focus_stealing" type="bool" value="false"/>\n    <property name="raise_delay" type="int" value="250"/>\n    <property name="raise_on_click" type="bool" value="true"/>\n    <property name="raise_on_focus" type="bool" value="false"/>\n    <property name="raise_with_any_button" type="bool" value="true"/>\n    <property name="repeat_urgent_blink" type="bool" value="false"/>\n    <property name="resize_opacity" type="int" value="100"/>\n    <property name="restore_on_move" type="bool" value="true"/>\n    <property name="scroll_workspaces" type="bool" value="true"/>\n    <property name="shadow_delta_height" type="int" value="0"/>\n    <property name="shadow_delta_width" type="int" value="0"/>\n    <property name="shadow_delta_x" type="int" value="0"/>\n    <property name="shadow_delta_y" type="int" value="-3"/>\n    <property name="shadow_opacity" type="int" value="50"/>\n    <property name="show_app_icon" type="bool" value="false"/>\n    <property name="show_dock_shadow" type="bool" value="true"/>\n    <property name="show_frame_shadow" type="bool" value="false"/>\n    <property name="show_popup_shadow" type="bool" value="false"/>\n    <property name="snap_resist" type="bool" value="false"/>\n    <property name="snap_to_border" type="bool" value="true"/>\n    <property name="snap_to_windows" type="bool" value="false"/>\n    <property name="snap_width" type="int" value="10"/>\n    <property name="theme" type="string" value="Shiki-Colors-Light-Menus"/>\n    <property name="title_alignment" type="string" value="center"/>\n    <property name="title_font" type="string" value="Sans Bold 9"/>\n    <property name="title_horizontal_offset" type="int" value="0"/>\n    <property name="title_shadow_active" type="string" value="false"/>\n    <property name="title_shadow_inactive" type="string" value="false"/>\n    <property name="title_vertical_offset_active" type="int" value="0"/>\n    <property name="title_vertical_offset_inactive" type="int" value="0"/>\n    <property name="toggle_workspaces" type="bool" value="false"/>\n    <property name="unredirect_overlays" type="bool" value="true"/>\n    <property name="urgent_blink" type="bool" value="false"/>\n    <property name="use_compositing" type="bool" value="true"/>\n    <property name="workspace_count" type="int" value="2"/>\n    <property name="wrap_cycle" type="bool" value="true"/>\n    <property name="wrap_layout" type="bool" value="true"/>\n    <property name="wrap_resistance" type="int" value="10"/>\n    <property name="wrap_windows" type="bool" value="true"/>\n    <property name="wrap_workspaces" type="bool" value="false"/>\n    <property name="workspace_names" type="array">\n      <value type="string" value="Workspace 1"/>\n      <value type="string" value="Workspace 2"/>\n      <value type="string" value="Workspace 3"/>\n      <value type="string" value="Workspace 4"/>\n    </property>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xsettings" version="1.0">\n  <property name="Net" type="empty">\n    <property name="ThemeName" type="empty"/>\n    <property name="IconThemeName" type="empty"/>\n    <property name="DoubleClickTime" type="int" value="250"/>\n    <property name="DoubleClickDistance" type="int" value="5"/>\n    <property name="DndDragThreshold" type="int" value="8"/>\n    <property name="CursorBlink" type="bool" value="true"/>\n    <property name="CursorBlinkTime" type="int" value="1200"/>\n    <property name="SoundThemeName" type="string" value="default"/>\n    <property name="EnableEventSounds" type="bool" value="false"/>\n    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>\n  </property>\n  <property name="Xft" type="empty">\n    <property name="DPI" type="empty"/>\n    <property name="Antialias" type="int" value="-1"/>\n    <property name="Hinting" type="int" value="-1"/>\n    <property name="HintStyle" type="string" value="hintnone"/>\n    <property name="RGBA" type="string" value="none"/>\n  </property>\n  <property name="Gtk" type="empty">\n    <property name="CanChangeAccels" type="bool" value="false"/>\n    <property name="ColorPalette" type="string" value="black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90"/>\n    <property name="FontName" type="string" value="Sans 10"/>\n    <property name="IconSizes" type="string" value=""/>\n    <property name="KeyThemeName" type="string" value=""/>\n    <property name="ToolbarStyle" type="string" value="icons"/>\n    <property name="ToolbarIconSize" type="int" value="3"/>\n    <property name="IMPreeditStyle" type="string" value=""/>\n    <property name="IMStatusStyle" type="string" value=""/>\n    <property name="MenuImages" type="bool" value="true"/>\n    <property name="ButtonImages" type="bool" value="true"/>\n    <property name="MenuBarAccel" type="string" value="F10"/>\n    <property name="CursorThemeName" type="string" value=""/>\n    <property name="CursorThemeSize" type="int" value="0"/>\n    <property name="IMModule" type="string" value=""/>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
echo -e '<Menu>\n\t<Name>Top 10</Name>\n\t<DefaultAppDirs/>\n\t<Directory>top10.directory</Directory>\n\t<Include>\n\t\t<Category>top10</Category>\n\t</Include>\n</Menu>' > /root/.config/xfce4/menu/top10.menu
#--- Get shiki-colors-light theme
wget http://xfce-look.org/CONTENT/content-files/142110-Shiki-Colors-Light-Menus.tar.gz -O /tmp/Shiki-Colors-Light-Menus.tar.gz
tar zxf /tmp/Shiki-Colors-Light-Menus.tar.gz -C /root/.themes/
xfconf-query -c xsettings -p /Net/ThemeName -s "Shiki-Colors-Light-Menus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "gnome-brave"
#--- Enable compositing
xfconf-query -c xfwm4 -p /general/use_compositing -s true
#--- Disable user folders
apt-get -y -qq install xdg-user-dirs
xdg-user-dirs-update
file=/etc/xdg/user-dirs.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^enable=.*/enable=False/' $file   #sed -i 's/^XDG_/#XDG_/; s/^#XDG_DESKTOP/XDG_DESKTOP/;' /root/.config/user-dirs.dirs
rm -rf /root/{Documents,Downloads,Music,Pictures,Public,Templates,Videos}/
#--- Get new desktop wallpaper
wget http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png -O /usr/share/wallpapers/kali_blue_3d_a.png
wget http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_B.png -O /usr/share/wallpapers/kali_blue_3d_b.png
wget http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_G.png -O /usr/share/wallpapers/kali_black_honeycomb.png
wget http://imageshack.us/a/img17/4646/vzex.png -O /usr/share/wallpapers/kali_blue_splat.png
wget http://www.n1tr0g3n.com/wp-content/uploads/2013/03/Kali-Linux-faded-no-Dragon-small-text.png -O /usr/share/wallpapers/kali_black_clean.png
wget http://1hdwallpapers.com/wallpapers/kali_linux.jpg -O /usr/share/wallpapers/kali_black_stripes.jpg
#--- Change desktop wallpaper (random each install). Note: For now...
wallpaper=$(shuf -n1 -e /usr/share/wallpapers/kali_*)   #wallpaper=/usr/share/wallpapers/kali_blue_splat.png
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -s true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $wallpaper
#--- Change login wallpaper
cp -f $wallpaper /usr/share/images/desktop-base/login-background.png
#--- Reload XFCE
#/usr/bin/xfdesktop --reload
#--- New wallpaper - add to startup (each login)
file=/usr/local/bin/wallpaper.sh; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\nwallpaper=$(shuf -n1 -e /usr/share/wallpapers/kali_*)\nxfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $wallpaper\ncp -f $wallpaper /usr/share/images/desktop-base/login-background.png\n/usr/bin/xfdesktop --reload' > $file
chmod 0500 $file
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/wallpaper.sh.desktop; [ -e $file ] && cp -n $file{,.bkup}
echo -e '\n[Desktop Entry]\nType=Application\nExec=/usr/local/bin/wallpaper.sh\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=wallpaper\nName=wallpaper\nComment[en_US]=\nComment=' > $file
#--- Configure file browser (need to re-login for effect)
mkdir -p /root/.config/Thunar/
file=/root/.config/Thunar/thunarrc; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' $file 2>/dev/null || echo -e "[Configuration]\nLastShowHidden=TRUE" > /root/.config/Thunar/thunarrc;
#--- Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?)) ~ https://wiki.xfce.org/faq
#xfconf-query -c keyboards -p /Default/Numlock -s true
apt-get -y -qq install numlockx
file=/etc/xdg/xfce4/xinitrc; [ -e $file ] && cp -n $file{,.bkup}     #/etc/rc.local
grep -q '^/usr/bin/numlockx' $file 2>/dev/null || echo "/usr/bin/numlockx on" >> $file
#--- XFCE fixes for default applications
mkdir -p /root/.local/share/applications/
file=/root/.local/share/applications/mimeapps.list; [ -e $file ] && cp -n $file{,.bkup}
[ ! -e $file ] && echo '[Added Associations]' > $file
for VALUE in file trash; do
  sed -i 's#x-scheme-handler/'$VALUE'=.*#x-scheme-handler/'$VALUE'=exo-file-manager.desktop#' $file
  grep -q '^x-scheme-handler/'$VALUE'=' $file 2>/dev/null || echo -e 'x-scheme-handler/'$VALUE'=exo-file-manager.desktop' >> $file
done
for VALUE in http https; do
  sed -i 's#^x-scheme-handler/'$VALUE'=.*#x-scheme-handler/'$VALUE'=exo-web-browser.desktop#' $file
  grep -q '^x-scheme-handler/'$VALUE'=' $file 2>/dev/null || echo -e 'x-scheme-handler/'$VALUE'=exo-web-browser.desktop' >> $file
done
[[ $(tail -n 1 $file) != "" ]] && echo >> $file
file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
sed -i 's#^FileManager=.*#FileManager=Thunar#' $file 2>/dev/null
grep -q '^FileManager=Thunar' $file 2>/dev/null || echo -e 'FileManager=Thunar' >> $file
#--- Remove any old sessions
rm -f /root/.cache/sessions/*
#--- XFCE fixes for terminator (We do this later)
#mkdir -p /root/.local/share/xfce4/helpers/
#file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' $file 2>/dev/null || echo -e '[Desktop Entry]\nNoDisplay=true\nVersion=1.0\nEncoding=UTF-8\nType=X-XFCE-Helper\nX-XFCE-Category=TerminalEmulator\nX-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"\nIcon=terminator\nName=terminator\nX-XFCE-Commands=/usr/bin/terminator' > $file
#file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
#sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' $file
#grep -q '^TerminalEmulator=custom-TerminalEmulator' $file 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> $file
#--- Set XFCE as default desktop manager
file=/root/.xsession; [ -e $file ] && cp -n $file{,.bkup}       #~/.xsession
echo xfce4-session > $file
#--- Add keyboard shortcut (ctrl + alt + t) to start a terminal window
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e $file ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>' $file || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;\&lt;Alt\&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>#' $file
#--- Create Conky refresh script (it gets installed later)
file=/usr/local/bin/conky_refresh.sh; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\nkillall -q conky\nconky &' > $file
chmod 0500 $file
#--- Add keyboard shortcut (ctrl + r) to run the conky refresh script
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e $file ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>' $file || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>#' $file


##### Configuring file browser (need to restart xserver for effect)
echo -e "\e[01;32m[+]\e[00m Configuring file browser (need to restart xserver for effect)"
mkdir -p /root/.config/gtk-2.0/
file=/root/.config/gtk-2.0/gtkfilechooser.ini; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^.*ShowHidden.*/ShowHidden=true/' $file 2>/dev/null || echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending" > $file    #Open/save Window -> Right click -> Show Hidden Files: Enabled
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
file=/root/.gtk-bookmarks; [ -e $file ] && cp -n $file{,.bkup}
grep -q '^file:///var/www www' $file 2>/dev/null || echo -e 'file:///var/www www\nfile:///usr/share apps\nfile:///tmp tmp\nfile:///usr/local/src/ src' >> $file


##### Configuring terminal (need to restart xserver for effect)
echo -e "\e[01;32m[+]\e[00m Configuring terminal (need to restart xserver for effect)"
gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true                   # Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996   # Not working 100%!
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_type transparent


##### Installing terminator ~ multiple terminals in a single window
echo -e "\e[01;32m[+]\e[00m Installing terminator"
apt-get -y -qq install terminator
#--- Configure terminator
mkdir -p /root/.config/terminator/
file=/root/.config/terminator/config; [ -e $file ] && cp -n $file{,.bkup}
echo -e '[global_config]\n  enabled_plugins = TerminalShot, LaunchpadCodeURLHandler, APTURLHandler, LaunchpadBugURLHandler\n[keybindings]\n[profiles]\n  [[default]]\n    background_darkness = 0.9\n    copy_on_selection = True\n    background_type = transparent\n    scrollback_infinite = True\n[layouts]\n  [[default]]\n    [[[child1]]]\n      type = Terminal\n      parent = window0\n    [[[window0]]]\n      type = Window\n      parent = ""\n[plugins]' > $file
#--- XFCE fix for terminator
mkdir -p /root/.local/share/xfce4/helpers/
file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' $file 2>/dev/null || echo -e '[Desktop Entry]\nNoDisplay=true\nVersion=1.0\nEncoding=UTF-8\nType=X-XFCE-Helper\nX-XFCE-Category=TerminalEmulator\nX-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"\nIcon=terminator\nName=terminator\nX-XFCE-Commands=/usr/bin/terminator' > $file
file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' $file
grep -q '^TerminalEmulator=custom-TerminalEmulator' $file 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> $file


##### Installing bash-completion - all users
echo -e "\e[01;32m[+]\e[00m Installing bash-completion"
apt-get -y -qq install bash-completion
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}    #/root/.bashrc
sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' $file
#--- Apply new aliases
#source $file   # If using ZSH, will fail


##### Configuring bash - all users
echo -e "\e[01;32m[+]\e[00m Configuring bash"
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}    #/root/.bashrc
grep -q "cdspell" $file || echo "shopt -sq cdspell" >> $file                  ## Spell check 'cd' commands
grep -q "checkwinsize" $file || echo "shopt -sq checkwinsize" >> $file        ## Wrap lines correctly after resizing
grep -q "nocaseglob" $file || echo "shopt -sq nocaseglob" >> $file            ## Case insensitive pathname expansion
grep -q "HISTSIZE" $file || echo "HISTSIZE=10000" >> $file                    ## Bash history (memory)
grep -q "HISTFILESIZE" $file || echo "HISTFILESIZE=10000" >> $file            ## Bash history (file - .bash_history)


##### Configuring aliases - root user
echo -e "\e[01;32m[+]\e[00m Configuring aliases"
#--- Enable defaults - root user
for FILE in /etc/bash.bashrc /root/.bashrc /root/.bash_aliases; do    #/etc/profile /etc/bashrc /etc/bash_aliases /etc/bash.bash_aliases
  [ ! -e $FILE ] && break
  cp -n $FILE{,.bkup}
  sed -i 's/#alias/alias/g' $FILE
done
#--- Add in ours (programs)
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^alias tmux' $file 2>/dev/null || echo -e '\n## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
grep -q '^alias axel' $file 2>/dev/null || echo -e '\n## axel\nalias axel="axel -a"\n\n' >> $file
grep -q '^alias screen' $file 2>/dev/null || echo -e '\n## screen\nalias screen="screen -xRR"\n\n' >> $file
#--- Add in ours (shortcuts)
grep -q '^## Get external IP address' $file 2>/dev/null || echo -e '\n## Get external IP address\nalias ipx="curl ipinfo.io/ip"\n\n' >> $file
grep -q '^## Grep aliases' $file 2>/dev/null || echo -e '\n## grep aliases\nalias grep="grep --color=always"\nalias ngrep="grep -n"\n\n' >> $file
grep -q '^## Directory navigation aliases' $file 2>/dev/null || echo -e '\n## Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n\n' >> $file
grep -q '^## Add more aliases' $file 2>/dev/null || echo -e '\n## Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n\n' >> $file
grep -q '^## Extract file' $file 2>/dev/null || echo -e '\n## Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}' >> $file
#--- Apply new aliases
#source $file   # If using ZSH, will fail
#--- Check
#alias


##### Configuring bash colour - all users
echo -e "\e[01;32m[+]\e[00m Configuring bash colour"
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}   #/root/.bashrc
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' $file
grep -q '^force_color_prompt' $file 2>/dev/null || echo 'force_color_prompt=yes' >> $file
sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' $file
#--- Apply new aliases
#source $file   # If using ZSH, will fail
#--- All other users that are made afterwards
#file=/etc/skel/.bashrc   #; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' $file


##### Configuring tmux - all users
echo -e "\e[01;32m[+]\e[00m Configuring tmux"
group="sudo"
#apt-get -y -qq remove screen   # Optional: If we're going to have/use tmux, why have screen?
apt-get -y -qq install tmux
#--- Configure tmux
file=/etc/tmux.conf; [ -e $file ] && cp -n $file{,.bkup}   #/root/.tmux.conf
echo -e "#-Settings---------------------------------------------------------------------\n## Make it like screen (use C-a)\nunbind C-b\nset -g prefix C-a\n\n## Pane switching with Alt+arrow\nbind -n M-Left select-pane -L\nbind -n M-Right select-pane -R\nbind -n M-Up select-pane -U\nbind -n M-Down select-pane -D\n\n## Activity Monitoring\nsetw -g monitor-activity on\nset -g visual-activity on\n\n## Reload settings\nunbind R\nbind R source-file ~/.tmux.conf\n\n## Load custom sources\nsource ~/.bashrc\n\n## Set defaults\nset -g default-terminal screen-256color\nset -g history-limit 5000\n\n## Default windows titles\nset -g set-titles on\nset -g set-titles-string '#(whoami)@#H - #I:#W'\n\n## Last window switch\nbind-key C-a last-window\n\n## Use ZSH as default shell\n$( [[ ! -e /bin/zsh ]] && echo "#" )set-option -g default-shell /bin/zsh\n\n## Show tmux messages for longer\nset -g display-time 3000\n\n## Status bar is redrawn every minute\nset -g status-interval 60\n\n\n#-Theme------------------------------------------------------------------------\n## Default colours\nset -g status-bg black\nset -g status-fg white\n\n## Left hand side\nset -g status-left-length '$(($(echo -n $(hostname) | wc -c) + 23))'\nset -g status-left '#[fg=green,bold]#(whoami)#[default]@#[fg=yellow,dim]#H #[fg=green,dim][#[fg=yellow]#(cut -d \" \" -f 1-3 /proc/loadavg)#[fg=green,dim]]'\n\n## Inactive windows in status bar\nset-window-option -g window-status-format '#[fg=red,dim]#I#[fg=grey,dim]:#[default,dim]#W#[fg=grey,dim]'\n\n## Current or active window in status bar\n#set-window-option -g window-status-current-format '#[bg=white,fg=red]#I#[bg=white,fg=grey]:#[bg=white,fg=black]#W#[fg=dim]#F'\nset-window-option -g window-status-current-format '#[fg=red,bold](#[fg=white,bold]#I#[fg=red,dim]:#[fg=white,bold]#W#[fg=red,bold])'\n\n## Right hand side\nset -g status-right '#[fg=green][#[fg=yellow]%Y-%m-%d #[fg=white]%H:%M#[fg=green]]'" > $file
#--- Setup alias
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^alias tmux' $file 2>/dev/null || echo -e '\n## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#--- Apply new aliases
#source $file   # If using ZSH, will fail
#--- Copy it to other user(s) ~
#if [[ -e /home/$username/ ]]; then   # Will do this later on again, if there isn't already a user
#  #cp -f /{root,home/$username}/.tmux.conf
#  cp -f /{etc/,home/$username/.}tmux.conf
#  chown $username\:$group /home/$username/.tmux.conf
#  file=/home/$username/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}
#  grep -q '^alias tmux' $file 2>/dev/null || echo -e '\n## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#fi
#--- Use it ~ bit pointless if used in a post-install script
#tmux   # If ZSH isn't installed, it will not start up


##### Configuring screen ~ if possible, use tmux instead
echo -e "\e[01;32m[+]\e[00m Configuring screen"
#apt-get -y -qq install screen
#--- Configure screen
file=/root/.screenrc; [ -e $file ] && cp -n $file{,.bkup}
echo -e "## Don't display the copyright page\nstartup_message off\n\n## tab-completion flash in heading bar\nvbell off\n\n## Keep scrollback n lines\ndefscrollback 1000\n\n## hardstatus is a bar of text that is visible in all screens\nhardstatus on\nhardstatus alwayslastline\nhardstatus string '%{gk}%{G}%H %{g}[%{Y}%l%{g}] %= %{wk}%?%-w%?%{=b kR}(%{W}%n %t%?(%u)%?%{=b kR})%{= kw}%?%+w%?%?%= %{g} %{Y} %Y-%m-%d %C%a %{W}'\n\n## title bar\ntermcapinfo xterm ti@:te@\n\n## default windows (syntax: screen -t label order command)\nscreen -t bash1 0\nscreen -t bash2 1\n\n## select the default window\nselect 1" > $file


##### Installing ZSH & oh-my-zsh - root user. Note: If you use thurar, 'Open terminal here', will not work.
echo -e "\e[01;32m[+]\e[00m Installing ZSH & oh-my-zsh"
group="sudo"
apt-get -y -qq install zsh git curl
#--- Setup oh-my-zsh
curl -s -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
#--- Configure zsh
file=/root/.zshrc; [ -e $file ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
grep -q 'interactivecomments' $file 2>/dev/null || echo 'setopt interactivecomments' >> $file
grep -q 'ignoreeof' $file 2>/dev/null || echo 'setopt ignoreeof' >> $file
grep -q 'correctall' $file 2>/dev/null || echo 'setopt correctall' >> $file
grep -q 'globdots' $file 2>/dev/null || echo 'setopt globdots' >> $file
grep -q '.bash_aliases' $file 2>/dev/null || echo 'source $HOME/.bash_aliases' >> $file
grep -q '/usr/bin/tmux' $file 2>/dev/null || echo 'if ([[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> $file   # If not already in tmux and via SSH
#--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
sed -i 's/ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' $file   # Other themes: alanpeabody, jreese,   mh,   candy,   terminalparty, kardan,   nicoulaj, sunaku
#--- Configure oh-my-zsh
sed -i 's/.*DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' $file
sed -i 's/plugins=(.*)/plugins=(git tmux last-working-dir)/' $file
#--- Set zsh as default shell (current user)
chsh -s $(which zsh)
#--- Use it ~ Not much point to it being a post-install script
#/usr/bin/env zsh
#source $file
#--- Copy it to other user(s)
#if [[ -e /home/$username/ ]]; then   # Will do this later on again, if there isn't already a user
#  cp -f /{root,home/$username}/.zshrc
#  cp -rf /{root,home/$username}/.oh-my-zsh/
#  chown -R $username\:$group /home/$username/.zshrc /home/$username/.oh-my-zsh/
#  chsh $username -s $(which zsh)
#fi
#--- Remove any leftovers
#apt-get -y -qq remove git curl


##### Configuring vim - all users
echo -e "\e[01;32m[+]\e[00m Configuring vim"
apt-get -y -qq install vim
#--- Configure vim
file=/etc/vim/vimrc; [ -e $file ] && cp -n $file{,.bkup}   #/root/.vimrc
sed -i 's/.*syntax on/syntax on/' $file
sed -i 's/.*set background=dark/set background=dark/' $file
sed -i 's/.*set showcmd/set showcmd/' $file
sed -i 's/.*set showmatch/set showmatch/' $file
sed -i 's/.*set ignorecase/set ignorecase/' $file
sed -i 's/.*set smartcase/set smartcase/' $file
sed -i 's/.*set incsearch/set incsearch/' $file
sed -i 's/.*set autowrite/set autowrite/' $file
sed -i 's/.*set hidden/set hidden/' $file
sed -i 's/.*set mouse=.*/"set mouse=a/' $file
grep -q '^set number' $file 2>/dev/null || echo 'set number' >> $file                                          # Add line numbers
grep -q '^set autoindent' $file 2>/dev/null || echo 'set autoindent' >> $file                                  # Set auto indent
grep -q '^set expandtab' $file 2>/dev/null || echo -e 'set expandtab\nset smarttab' >> $file                   # Set use spaces instead of tabs
grep -q '^set softtabstop' $file 2>/dev/null || echo -e 'set softtabstop=4\nset shiftwidth=4' >> $file         # Set 4 spaces as a 'tab'
grep -q '^set foldmethod=marker' $file 2>/dev/null || echo 'set foldmethod=marker' >> $file                    # Folding
grep -q '^nnoremap <space> za' $file 2>/dev/null || echo 'nnoremap <space> za' >> $file                        # Space toggle folds
grep -q '^set hlsearch' $file 2>/dev/null || echo 'set hlsearch' >> $file                                      # Highlight search results
grep -q '^set laststatus' $file 2>/dev/null || echo -e 'set laststatus=2\nset statusline=%F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]' >> $file   # Status bar
grep -q '^filetype on' $file 2>/dev/null || echo -e 'filetype on\nfiletype plugin on\nsyntax enable\nset grepprg=grep\ -nH\ $*' >> $file     # Syntax highlighting
grep -q '^set wildmenu' $file 2>/dev/null || echo -e 'set wildmenu\nset wildmode=list:longest,full' >> $file   # Tab completion
grep -q '^set pastetoggle=<F11>' $file 2>/dev/null || echo -e 'set pastetoggle=<F11>' >> $file                 # Hotkey - turning off auto indent when pasting
#--- Set as default editor
export EDITOR="vim"    #update-alternatives --config editor
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}
grep -q '^EDITOR' $file 2>/dev/null || echo 'EDITOR="vim"' >> $file
git config --global core.editor "vim"
#--- Set as default mergetool
git config --global merge.tool vimdiff
git config --global merge.conflictstyle diff3
git config --global mergetool.prompt false


##### Setting up iceweasel
echo -e "\e[01;32m[+]\e[00m Setting up iceweasel"
apt-get install -y -qq unzip curl wget
#--- Configure iceweasel
iceweasel & sleep 15; killall -q -w iceweasel >/dev/null   # Start and kill. Files needed for first time run
file=$(find /root/.mozilla/firefox/*.default/ -maxdepth 1 -type f -name 'prefs.js') && [ -e $file ] && cp -n $file{,.bkup}    #/etc/iceweasel/pref/*.js
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' $file 2>/dev/null || echo 'user_pref("browser.startup.page", 0);' >> $file                                              # Iceweasel -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' $file 2>/dev/null || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> $file    # Privacy -> Enable: Tell websites I do not want to be tracked
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' $file 2>/dev/null || echo 'user_pref("browser.showQuitWarning", true);' >> $file                               # Stop Ctrl + Q from quitting without warning
#--- Replace bookmarks
file=$(find /root/.mozilla/firefox/*.default/ -maxdepth 1 -type f -name 'bookmarks.html') && [ -e $file ] && cp -n $file{,.bkup}    #/etc/iceweasel/profile/bookmarks.html
wget http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html -O /tmp/bookmarks_new.html     # ***!!! hardcoded version! Need to manually check for updates
rm -f /root/.mozilla/firefox/*.default/places.sqlite
rm -f /root/.mozilla/firefox/*.default/bookmarkbackups/*
#--- Configure bookmarks
awk '!a[$0]++' /tmp/bookmarks_new.html | egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" | egrep -v "^    </DL><p>" | egrep -v "^<DD>Add" > $file
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n    <DT><A HREF="https://127.0.0.1:8834">Nessus</A>\n    <DT><A HREF="https://127.0.0.1:3790">MSF Community</A>\n    <DT><A HREF="https://127.0.0.1:9392">OpenVAS</A>\n</DL><p>#' $file
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' $file
#--- Download addons
path="$(find /root/.mozilla/firefox/*.default/ -maxdepth 1 -type d -name 'extensions')"
mkdir -p $path/
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary -o $path/SQLiteManager@mrinalkant.blogspot.com.xpi           # SQLite Manager
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary -o $path/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi          # Adblock Plus
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary -o $path/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi        # Cookies Manager+
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary -o $path/firebug@software.joehewitt.com.xpi                  # Firebug - not working 100%
curl -k -L https://addons.mozilla.org/firefox/downloads/file/150692/foxyproxy_basic-2.6.2-fx+tb+sm.xpi?src=search -o /tmp/FoxyProxyBasic.zip && unzip -o /tmp/FoxyProxyBasic.zip -d $path/foxyproxy-basic@eric.h.jung/; rm -f /tmp/FoxyProxyBasic.zip   # FoxyProxy Basic
#curl -k -L https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary -o $path/{6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi     # HTTPS Finder
curl -k -L https://www.eff.org/files/https-everywhere-latest.xpi -o $path/https-everywhere@eff.org.xpi                                                                    # HTTPS Everywhere
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary -o $path/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi          # Live HTTP Headers
curl -k -L https://addons.mozilla.org/firefox/downloads/file/79565/tamper_data-11.0.1-fx.xpi?src=dp-btn-primary -o $path/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi       # Tamper Data  - not working 100%
curl -k -L https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary -o $path/check-compatibility@dactyl.googlecode.com.xpi   # Disable Add-on Compatibility Checks
#--- Install addons
for FILE in $(find $path -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename $FILE .xpi)"
  mkdir -p $d/
  unzip -o $FILE -d $path/$d/ && rm -f $FILE
done
#--- Enable addons
iceweasel & sleep 15; killall -q -w iceweasel >/dev/null
apt-get install -y -qq sqlite3
touch /tmp/iceweasel.sql
#for FILE in $(find /root/.mozilla/firefox/*.default/extensions/ -maxdepth 1 -mindepth 1 -type d); do
#  xpi="$(basename $FILE)"
#  echo "UPDATE 'main'.'addon'  SET 'active' = 1, 'userDisabled' = 0  WHERE 'id' = '"$xpi"';" >> /tmp/iceweasel.sql
#done
echo "UPDATE 'main'.'addon'  SET 'active' = 1, 'userDisabled' = 0;" > /tmp/iceweasel.sql    # Force every addons!
killall -q -w iceweasel >/dev/null     #fuser extensions.sqlite
sqlite3 /root/.mozilla/firefox/n52jqts1.default/extensions.sqlite < /tmp/iceweasel.sql
#--- Wipe session (due to force close)
find /root/.mozilla/firefox/*.default/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Configure foxyproxy
file=$(find /root/.mozilla/firefox/*.default/ -maxdepth 1 -name 'foxyproxy.xml') && [ -e $file ] && cp -n $file{,.bkup}
if [[ -e $file ]]; then
  grep -q 'localhost:8080' $file 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#05FC81" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' $file            # localhost:8080
  grep -q 'localhost:8081' $file 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\##FCCB05" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy><proxy name="Default"#' $file   # localhost:8081 (socket5)
else
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="true" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > $file
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#05FC81" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> $file
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#FCCB05" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> $file
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> $file
  echo -e '</proxies></foxyproxy>' >> $file
fi
#--- Restore to folder
cd - &>/dev/null
#--- Remove any leftovers
rm -f /tmp/iceweasel.sql


##### Installing conky ~ gui desktop monitor
echo -e "\e[01;32m[+]\e[00m Installing conky"
apt-get -y -qq install conky
#--- Configure conky
file=/root/.conkyrc; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html\nbackground yes\n\nfont Monospace:size=8:weight=bold\nuse_xft yes\n\nupdate_interval 2.0\n\nown_window yes\nown_window_type normal\nown_window_transparent yes\nown_window_class conky-semi\nown_window_argb_visual yes  # GNOME & XFCE yes, KDE no\nown_window_colour brown\nown_window_hints undecorated,below,sticky,skip_taskbar,skip_pager\n\ndouble_buffer yes\nmaximum_width 260\n\ndraw_shades yes\ndraw_outline no\ndraw_borders no\n\nstippled_borders 3\n#border_margin 9   # Old command\nborder_inner_margin 9\nborder_width 10\n\ndefault_color grey\n\nalignment bottom_right\n#gap_x 55 # KDE\n#gap_x 0  # GNOME\ngap_x 5\ngap_y 0\n\nuppercase no\nuse_spacer right\n\nTEXT\n${color dodgerblue3}SYSTEM ${hr 2}$color\n#${color white}${time %A},${time %e} ${time %B} ${time %G}${alignr}${time %H:%M:%S}\n${color white}Host$color: $nodename  ${alignr}${color white}Uptime$color: $uptime\n\n${color dodgerblue3}CPU ${hr 2}$color\n#${font Arial:bold:size=8}${execi 99999 grep "model name" -m1 /proc/cpuinfo | cut -d":" -f2 | cut -d" " -f2- | sed "s#Processor ##"}$font$color\n${color white}MHz$color: ${freq} ${alignr}${color white}Load$color: ${exec uptime | awk -F "load average: " '"'"'{print $2}'"'"'}\n${color white}Tasks$color: $running_processes/$processes ${alignr}${color white}CPU0$color: ${cpu cpu0}% ${color white}CPU1$color: ${cpu cpu1}%\n#${color #c0ff3e}${acpitemp}C\n#${execi 20 sensors |grep "Core0 Temp" | cut -d" " -f4}$font$color${alignr}${freq_g 2} ${execi 20 sensors |grep "Core1 Temp" | cut -d" " -f4}\n${cpugraph cpu0 25,120 000000 white} ${alignr}${cpugraph cpu1 25,120 000000 white}\n${color white}${cpubar cpu1 3,120} ${alignr}${color white}${cpubar cpu2 3,120}$color\n\n${color dodgerblue3}PROCESSES ${hr 2}$color\n${color white}NAME             PID     CPU     MEM\n${color white}${top name 1}${top pid 1}  ${top cpu 1}  ${top mem 1}$color\n${top name 2}${top pid 2}  ${top cpu 2}  ${top mem 2}\n${top name 3}${top pid 3}  ${top cpu 3}  ${top mem 3}\n${top name 4}${top pid 4}  ${top cpu 4}  ${top mem 4}\n${top name 5}${top pid 5}  ${top cpu 5}  ${top mem 5}\n\n${color dodgerblue3}MEMORY & SWAP ${hr 2}$color\n${color white}RAM$color   $memperc%  ${membar 6}$color\n${color white}Swap$color  $swapperc%  ${swapbar 6}$color\n\n${color dodgerblue3}FILESYSTEM ${hr 2}$color\n${color white}root$color ${fs_free_perc /}% free${alignr}${fs_free /}/ ${fs_size /}\n${fs_bar 3 /}$color\n#${color white}home$color ${fs_free_perc /home}% free${alignr}${fs_free /home}/ ${fs_size /home}\n#${fs_bar 3 /home}$color\n\n${color dodgerblue3}LAN eth0 (${addr eth0}) ${hr 2}$color\n${color white}Down$color:  ${downspeed eth0} KB/s${alignr}${color white}Up$color: ${upspeed eth0} KB/s\n${color white}Downloaded$color: ${totaldown eth0} ${alignr}${color white}Uploaded$color: ${totalup eth0}\n${downspeedgraph eth0 25,120 000000 00ff00} ${alignr}${upspeedgraph eth0 25,120 000000 ff0000}$color' > $file
ifconfig eth1 &>/devnull && echo -e '${color dodgerblue3}LAN eth1 (${addr eth1}) ${hr 2}$color\n${color white}Down$color:  ${downspeed eth1} KB/s${alignr}${color white}Up$color: ${upspeed eth1} KB/s\n${color white}Downloaded$color: ${totaldown eth1} ${alignr}${color white}Uploaded$color: ${totalup eth1}\n${downspeedgraph eth1 25,120 000000 00ff00} ${alignr}${upspeedgraph eth1 25,120 000000 ff0000}$color' >> $file
echo -e '${color dodgerblue3}WiFi (${addr wlan0}) ${hr 2}$color\n${color white}Down$color:  ${downspeed wlan0} KB/s${alignr}${color white}Up$color: ${upspeed wlan0} KB/s\n${color white}Downloaded$color: ${totaldown wlan0} ${alignr}${color white}Uploaded$color: ${totalup wlan0}\n${downspeedgraph wlan0 25,120 000000 00ff00} ${alignr}${upspeedgraph wlan0 25,120 000000 ff0000}$color\n\n${color dodgerblue3}CONNECTIONS ${hr 2}$color\n${color white}Inbound: $color${tcp_portmon 1 32767 count}  ${alignc}${color white}Outbound: $color${tcp_portmon 32768 61000 count}${alignr}${color white}Total: $color${tcp_portmon 1 65535 count}\n${color white}Inbound ${alignr}Local Service/Port$color\n$color ${tcp_portmon 1 32767 rhost 0} ${alignr}${tcp_portmon 1 32767 lservice 0}\n$color ${tcp_portmon 1 32767 rhost 1} ${alignr}${tcp_portmon 1 32767 lservice 1}\n$color ${tcp_portmon 1 32767 rhost 2} ${alignr}${tcp_portmon 1 32767 lservice 2}\n${color white}Outbound ${alignr}Remote Service/Port$color\n$color ${tcp_portmon 32768 61000 rhost 0} ${alignr}${tcp_portmon 32768 61000 rservice 0}\n$color ${tcp_portmon 32768 61000 rhost 1} ${alignr}${tcp_portmon 32768 61000 rservice 1}\n$color ${tcp_portmon 32768 61000 rhost 2} ${alignr}${tcp_portmon 32768 61000 rservice 2}' >> $file
#--- Add to startup (each login)
file=/usr/local/bin/conky.sh; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\nkillall -q conky\nsleep 15\nconky &' > $file
chmod 0500 $file
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/conkyscript.sh.desktop; [ -e $file ] && cp -n $file{,.bkup}
echo -e '\n[Desktop Entry]\nType=Application\nExec=/usr/local/bin/conky.sh\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=conky\nName=conky\nComment[en_US]=\nComment=' > $file


##### Configuring metasploit ~ Exploit framework (More info: http://docs.kali.org/general-use/starting-metasploit-framework-in-kali)
echo -e "\e[01;32m[+]\e[00m Configuring metasploit"
#--- Start services
service postgresql start
service metasploit start
#--- Add to start up
#update-rc.d postgresql enable
#update-rc.d metasploit enable
#--- Misc
export GOCOW=1   # Always a cow logo ;)
file=/root/.bashrc; [ -e $file ] && cp -n $file{,.bkup}
grep -q '^GOCOW' $file 2>/dev/null || echo 'GOCOW=1' >> $file
#--- Metasploit 4.10.x+ database fix #1 ~ https://community.rapid7.com/community/metasploit/blog/2014/08/25/not-reinventing-the-wheel
ln -sf /opt/metasploit/apps/pro/ui/config/database.yml /root/.msf4/database.yml    #cp -f   #find / -name database.yml -type f | grep metasploit | grep -v gems   # /usr/share/metasploit-framework/config/database.yml
#--- Metasploit 4.10.x+ database fix #2 ~ Using method #1, so this isn't needed
#file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
#grep -q '^alias msfconsole' $file 2>/dev/null || echo -e '\n## Metasploit\nalias msfconsole="msfconsole db_connect -y /opt/metasploit/apps/pro/ui/config/database.yml"\n\n' >> $file
#--- Apply new alias
#source $file   # If using ZSH, will fail
#--- First time run
echo -e 'sleep 10\ndb_rebuild_cache\nsleep 180\nexit' > /tmp/msf.rc   #echo -e 'go_pro' > /tmp/msf.rc
msfconsole -r /tmp/msf.rc
#--- Setup GUI
#bash /opt/metasploit/scripts/launchui.sh    #*** #<--- Doesn't automate. May take a little while to kick in
#xdg-open https://127.0.0.1:3790/
#--- Remove any leftovers
rm -f /tmp/msf.rc


##### Installing geany ~ gui text editor
echo -e "\e[01;32m[+]\e[00m Installing geany"
apt-get -y -qq install geany
#--- Add to panel
dconf load /org/gnome/gnome-panel/layout/objects/geany/ << EOT
[instance-config]
location='/usr/share/applications/geany.desktop'

[/]
object-iid='PanelInternalFactory::Launcher'
pack-index=3
pack-type='start'
toplevel-id='top-panel'
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'geany']/")"
#--- Configure geany
geany & sleep 5; killall -q -w geany >/dev/null   # Start and kill. Files needed for first time run
# Geany -> Edit -> Preferences. Editor -> Newline strips trailing spaces: Enable. -> Indentation -> Type: Spaces. -> Files -> Strip trailing spaces and tabs: Enable. Replace tabs by space: Enable. -> Apply -> Ok
file=/root/.config/geany/geany.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^.*indent_type.*/indent_type=0/' $file     # Spaces over tabs
sed -i 's/^.*pref_editor_newline_strip.*/pref_editor_newline_strip=true/' $file
sed -i 's/^.*pref_editor_replace_tabs.*/pref_editor_replace_tabs=true/' $file
sed -i 's/^.*pref_editor_trail_space.*/pref_editor_trail_space=true/' $file
sed -i 's/^check_detect_indent=.*/check_detect_indent=true/' $file
sed -i 's/^pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' $file
# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' $file
mkdir -p /root/backups/geany/
mkdir -p /root/.config/geany/plugins/saveactions/
file=/root/.config/geany/plugins/saveactions/saveactions.conf; [ -e $file ] && cp -n $file{,.bkup}
echo -e '\n[saveactions]\nenable_autosave=false\nenable_instantsave=false\nenable_backupcopy=true\n\n[autosave]\nprint_messages=false\nsave_all=false\ninterval=300\n\n[instantsave]\ndefault_ft=None\n\n[backupcopy]\ndir_levels=5\ntime_fmt=%Y-%m-%d-%H-%M-%S\nbackup_dir=/root/backups/geany' > $file


##### Installing meld ~ gui text compare
echo -e "\e[01;32m[+]\e[00m Installing meld"
apt-get -y -qq install meld
#--- Configure meld
gconftool-2 --type bool --set /apps/meld/show_line_numbers true
gconftool-2 --type bool --set /apps/meld/show_whitespace true
gconftool-2 --type bool --set /apps/meld/use_syntax_highlighting true
gconftool-2 --type int --set /apps/meld/edit_wrap_lines 2


##### Installing bless ~ gui hex editor
echo -e "\e[01;32m[+]\e[00m Installing bless"
apt-get -y -qq install bless


##### Installing nessus ~ vulnerability scanner   *** Doesn't automate ***
#echo -e "\e[01;32m[+]\e[00m Installing nessus"
#--- Get download link
#xdg-open http://www.tenable.com/products/nessus/select-your-operating-system    *** #wget "http://downloads.nessus.org/<file>" -O /usr/local/src/nessus.deb   # ***!!! Hardcoded version value
#dpkg -i /usr/local/src/Nessus-*-debian6_*.deb
#service nessusd start
#xdg-open http://www.tenable.com/products/nessus-home
#/opt/nessus/sbin/nessus-adduser   #<--- Doesn't automate
##rm -f /usr/local/src/Nessus-*-debian6_*.deb
#--- Check email
# /opt/nessus/bin/nessus-fetch --register <key>   #<--- Doesn't automate
#xdg-open https://127.0.0.1:8834/
#--- Remove from start up
#update-rc.d -f nessusd remove


##### Installing openvas ~ vulnerability scanner   *** Doesn't automate ***
echo -e "\e[01;32m[+]\e[00m Installing openvas"
apt-get -y -qq install openvas
#openvas-setup   #<--- Doesn't automate ***
#--- Remove 'default' user (admin), and create a new admin user (root).
#test -e /var/lib/openvas/users/admin && openvasad -c remove_user -n admin
#test -e /var/lib/openvas/users/root || openvasad -c add_user -n root -r Admin   #<--- Doesn't automate


##### Installing libreoffice ~ gui office suite
echo -e "\e[01;32m[+]\e[00m Installing libreoffice"
apt-get -y -qq install libreoffice


##### Installing recordmydesktop ~ gui video screen capture
echo -e "\e[01;32m[+]\e[00m Installing recordmydesktop"
apt-get -y -qq install recordmydesktop
#--- Installing GUI front end
apt-get -y -qq install gtk-recordmydesktop


##### Installing gimp ~ gui image editing
#echo -e "\e[01;32m[+]\e[00m Installing gimp"
#apt-get -y -qq install gimp


##### Installing shutter ~ gui screenshot
echo -e "\e[01;32m[+]\e[00m Installing shutter"
apt-get -y -qq install shutter


##### Installing gdebi ~ gui package installer
echo -e "\e[01;32m[+]\e[00m Installing gdebi"
apt-get -y -qq install gdebi


##### Installing psmisc ~ allows for 'killall command' to be used
echo -e "\e[01;32m[+]\e[00m Installing psmisc"
apt-get -y -qq install psmisc


##### Installing midnight commander ~ cli file manager
echo -e "\e[01;32m[+]\e[00m Installing midnight commander"
apt-get -y -qq install mc


##### Installing htop ~ cli process viewer
echo -e "\e[01;32m[+]\e[00m Installing htop"
apt-get -y -qq install htop


##### Installing glance ~ cli process viewer
echo -e "\e[01;32m[+]\e[00m Installing glance"
apt-get -y -qq install glance


##### Installing axel ~ cli download manager
echo -e "\e[01;32m[+]\e[00m Installing axel"
apt-get -y -qq install axel
#--- Setup alias
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^alias axel' $file 2>/dev/null || echo -e '\n## axel\nalias axel="axel -a"\n\n' >> $file
#--- Apply new aliases
#source $file   # If using ZSH, will fail


##### Installing gparted ~ gui partition manager
echo -e "\e[01;32m[+]\e[00m Installing gparted"
apt-get -y -qq install gparted


##### Installing daemonfs ~ gui file monitor
echo -e "\e[01;32m[+]\e[00m Installing daemonfs"
apt-get -y -qq install daemonfs


##### Installing filezilla ~ gui file transfer
echo -e "\e[01;32m[+]\e[00m Installing filezilla"
apt-get -y -qq install filezilla
#--- Configure filezilla
filezilla & sleep 5; killall -q -w filezilla >/dev/null     # Start and kill. Files needed for first time run
sed -i 's#^.*"Default editor".*#\t<Setting name="Default editor" type="string">2/usr/bin/geany</Setting>#' /root/.filezilla/filezilla.xml


##### Installing remmina ~ gui remote desktop
echo -e "\e[01;32m[+]\e[00m Installing remmina"
apt-get -y -qq install remmina


##### Setting up tftp client/server ~ file transfer method
echo -e "\e[01;32m[+]\e[00m Setting up tftp client/server"
apt-get -y -qq install tftp      # tftp client
apt-get -y -qq install atftpd    # tftp Server
#--- Configure atftpd
file=/etc/default/atftpd; [ -e $file ] && cp -n $file{,.bkup}
echo -e 'USE_INETD=false\nOPTIONS="--tftpd-timeout 300 --retry-timeout 5 --maxthread 100 --verbose=5 --daemon --port 69 /var/tftp"' > $file
mkdir -p /var/tftp/
chown -R nobody\:root /var/tftp/
chmod -R 0755 /var/tftp/
update-rc.d -f atftpd remove


##### Installing pure-ftpd ~ file transfer method
echo -e "\e[01;32m[+]\e[00m Installing pure-ftpd"
apt-get -y -qq install pure-ftpd
#--- Configure setup pure-ftpd
update-rc.d -f pure-ftpd remove
mkdir -p /var/ftp/
groupdel ftpgroup 2>/dev/null; groupadd ftpgroup
userdel ftp 2>/dev/null; useradd -d /var/ftp/ -s /bin/false -c "FTP user" -g ftpgroup ftp
chown -R ftp\:ftpgroup /var/ftp/
chmod -R 0755 /var/ftp/
pure-pw userdel ftp 2>/dev/null; echo -e '\n' | pure-pw useradd ftp -u ftp -d /var/ftp/
pure-pw mkdb
#--- Configure pure-ftpd
echo no > /etc/pure-ftpd/conf/UnixAuthentication
echo no > /etc/pure-ftpd/conf/PAMAuthentication
echo yes > /etc/pure-ftpd/conf/NoChmod
echo yes > /etc/pure-ftpd/conf/ChrootEveryone
#echo yes > /etc/pure-ftpd/conf/AnonymousOnly
echo no > /etc/pure-ftpd/conf/NoAnonymous
echo yes > /etc/pure-ftpd/conf/AnonymousCanCreateDirs
echo yes > /etc/pure-ftpd/conf/AllowAnonymousFXP
echo no > /etc/pure-ftpd/conf/AnonymousCantUpload
#mkdir -p /etc/ssl/private/
#openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#chmod 0600 /etc/ssl/private/*.pem
ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure


##### Installing lynx ~ cli web browser
echo -e "\e[01;32m[+]\e[00m Installing lynx"
apt-get -y -qq install lynx


##### Installing p7zip ~ cli file extractor
echo -e "\e[01;32m[+]\e[00m Installing p7zip"
apt-get -y -qq install p7zip-full


##### Installing zip/unzip ~ cli file extractor
echo -e "\e[01;32m[+]\e[00m Installing zip/unzip"
apt-get -y -qq install zip      # Compress
apt-get -y -qq install unzip    # Decompress


##### Installing file roller ~ gui file extractor
echo -e "\e[01;32m[+]\e[00m Installing file roller"
apt-get -y -qq install file-roller
apt-get -y -qq unrar unace unzip rar zip p7zip p7zip-full p7zip-rar


##### Installing PPTP VPN support
echo -e "\e[01;32m[+]\e[00m Installing PPTP VPN support"
apt-get -y -qq install network-manager-pptp-gnome network-manager-pptp


##### Installing flash ~ web plugin
echo -e "\e[01;32m[+]\e[00m Installing flash"
apt-get -y -qq install flashplugin-nonfree
update-flashplugin-nonfree --install


##### Installing java ~ web plugin
#echo -e "\e[01;32m[+]\e[00m Installing java"
# <***insert bash fu here***>


##### Installing the backdoor factory ~ anti-virus bypass
echo -e "\e[01;32m[+]\e[00m Installing backdoor factory"
apt-get -y -qq install backdoor-factory


##### Installing bully ~ WPS brute force
echo -e "\e[01;32m[+]\e[00m Installing bully"
apt-get -y -qq install bully


##### Installing httprint ~ gui web server fingerprint
echo -e "\e[01;32m[+]\e[00m Installing httprint"
apt-get -y -qq install httprint


##### Installing unicornscan ~ fast port scanner
echo -e "\e[01;32m[+]\e[00m Installing unicornscan"
apt-get -y -qq install unicornscan


##### Installing clusterd ~ clustered attack toolkit (jboss, coldfusion, weblogic, tomcat etc)
echo -e "\e[01;32m[+]\e[00m Installing clusterd"
apt-get -y -qq install clusterd


##### Installing webhandler ~ shell TTY handler
echo -e "\e[01;32m[+]\e[00m Installing webhandler"
apt-get -y -qq install webhandler


##### Installing azazel ~ linux userland rootkit
echo -e "\e[01;32m[+]\e[00m Installing azazel"
apt-get -y -qq install git
git clone git://github.com/chokepoint/azazel.git /usr/share/azazel/


##### Installing b374k ~ (PHP) web shell
echo -e "\e[01;32m[+]\e[00m Installing b374k"
apt-get -y -qq install git
git clone git://github.com/b374k/b374k.git /usr/share/b374k/


##### Installing jsp file browser ~ (JSP) web shell
echo -e "\e[01;32m[+]\e[00m Installing jsp file browser"
wget http://www.vonloesch.de/files/browser.zip -O /tmp/jsp.zip && unzip -o -d /usr/share/webshells_jsp/ /tmp/jsp.zip; rm -f /tmp/jsp.zip


##### Installing htshells ~ (htdocs/apache) web shells
echo -e "\e[01;32m[+]\e[00m Installing htshells"
apt-get -y -qq install htshells


##### Installing bridge-utils ~ bridge network interfaces
echo -e "\e[01;32m[+]\e[00m Installing bridge-utils"
apt-get -y -qq install bridge-utils


##### Installing httptunnel ~ tunnels a data stream in HTTP requests
echo -e "\e[01;32m[+]\e[00m Installing httptunnel"
apt-get -y -qq install http-tunnel


##### Installing sshuttle ~ proxy server for VPN over SSH
echo -e "\e[01;32m[+]\e[00m Installing sshuttle"
apt-get -y -qq install sshuttle
#sshuttle --dns --remote root@123.9.9.9 0/0 -vv


##### Installing iodine ~ DNS tunneling (IP over DNS)
echo -e "\e[01;32m[+]\e[00m Installing iodine"
apt-get -y -qq install ptunnel
#iodined -f -P password1 10.0.0.1 dns.mydomain.com
#iodine -f -P password1 123.9.9.9 dns.mydomain.com; ssh -C -D 8081 root@10.0.0.1


##### Installing dns2tcp ~ DNS tunneling (TCP over DNS)
echo -e "\e[01;32m[+]\e[00m Installing dns2tcp"
apt-get -y -qq install dns2tcp
#file=/etc/dns2tcpd.conf; [ -e $file ] && cp -n $file{,.bkup}; echo -e "listen = 0.0.0.0\nport = 53\nuser = nobody\nchroot = /tmp\ndomain = dnstunnel.mydomain.com\nkey = password1\nressources = ssh:127.0.0.1:22" > $file; dns2tcpd -F -d 1 -f /etc/dns2tcpd.conf
#file=/etc/dns2tcpc.conf; [ -e $file ] && cp -n $file{,.bkup}; echo -e "domain = dnstunnel.mydomain.com\nkey = password1\nresources = ssh\nlocal_port = 8000\ndebug_level=1" > $file; dns2tcpc -f /etc/dns2tcpc.conf 178.62.206.227; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing ptunnel ~ IMCP tunneling
echo -e "\e[01;32m[+]\e[00m Installing ptunnel"
apt-get -y -qq install ptunnel
#ptunnel -x password1
#ptunnel -x password1 -p 123.9.9.9 -lp 8000 -da 127.0.0.1 -dp 22; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing zerofree ~ cli nulls free blocks on HDD
echo -e "\e[01;32m[+]\e[00m Installing zerofree"
apt-get -y -qq install zerofree
#fdisk -l
#zerofree -v /dev/sda1   #for i in $(mount | grep sda | grep ext | cut -b 9); do  mount -o remount,ro /dev/sda$i && zerofree -v /dev/sda$i && mount -o remount,rw /dev/sda$i; done


##### Installing veil ~ anti-virus bypass framework
echo -e "\e[01;32m[+]\e[00m Installing veil"
apt-get -y -qq install veil


##### Installing gcc & multilib ~ compiling libraries
echo -e "\e[01;32m[+]\e[00m Installing gcc & multilib"
apt-get -y -qq install gcc-multilib libc6-dev-i386


##### Installing mingw ~ cross compiling tools
echo -e "\e[01;32m[+]\e[00m Installing mingw"
apt-get -y -qq install mingw-w64 binutils-mingw-w64 gcc-mingw-w64 mingw-w64-dev mingw-w64-tools  cmake


##### Installing OP packers ~ anti-virus bypass
echo -e "\e[01;32m[+]\e[00m Installing OP packers"
apt-get -y -qq install upx-ucl   #wget http://upx.sourceforge.net/download/upx309w.zip -P /usr/share/packers/ && unzip -o -d /usr/share/packers/ /usr/share/packers/upx309w.zip; rm -f /usr/share/packers/upx309w.zip
mkdir -p /usr/share/packers/
wget "http://www.eskimo.com/~scottlu/win/cexe.exe" -P /usr/share/packers/
wget "http://www.farbrausch.de/~fg/kkrunchy/kkrunchy_023a2.zip" -P /usr/share/packers/ && unzip -o -d /usr/share/packers/ /usr/share/packers/kkrunchy_023a2.zip; rm -f /usr/share/packers/kkrunchy_023a2.zip
#--- Setup hyperion
unzip -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/Hyperion-1.0.zip
#rm -f /usr/share/windows-binaries/Hyperion-1.0.zip
i686-w64-mingw32-g++ -static-libgcc -static-libstdc++ /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp -o /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe
ln -sf /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe /usr/share/windows-binaries/Hyperion-1.0/crypter.exe


##### Installing fuzzdb ~ multiple types of (word)lists (and more)
echo -e "\e[01;32m[+]\e[00m Installing fuzzdb"
svn checkout http://fuzzdb.googlecode.com/svn/trunk/ /usr/share/fuzzdb/


##### Installing seclist ~ multiple types of (word)lists (and more)
echo -e "\e[01;32m[+]\e[00m Installing seclist"
apt-get -y -qq install seclists


##### Updating wordlists ~ collection of wordlists
echo -e "\e[01;32m[+]\e[00m Updating wordlists"
#--- Extract rockyou wordlist
gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt   #gunzip rockyou.txt.gz
#rm -f /usr/share/wordlists/rockyou.txt.gz
#--- Extract sqlmap wordlist
#unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
#--- Add 10,000 Top/Worst/Common Passwords
wget http://xato.net/files/10k%20most%20common.zip -O /tmp/10kcommon.zip && unzip -o -d /usr/share/wordlists/ /tmp/10kcommon.zip && mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt; rm -f /tmp/10kcommon.zip
#--- Linking to more - folders
#ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
#ln -sf /usr/share/dirbuster/wordlists /usr/share/wordlists/dirbuster
#ln -sf /usr/share/fern-wifi-cracker/extras/wordlists /usr/share/wordlists/fern-wifi
#ln -sf /usr/share/metasploit-framework/data/john/wordlists /usr/share/wordlists/metasploit-jtr
#ln -sf /usr/share/metasploit-framework/data/wordlists /usr/share/wordlists/metasploit
#ln -sf /opt/metasploit/apps/pro/data/wordlists /usr/share/wordlists/metasploit-pro
#ln -sf /usr/share/webslayer/wordlist /usr/share/wordlists/webslayer
#ln -sf /usr/share/wfuzz/wordlist /usr/share/wordlists/wfuzz
#--- Linking to more - files
#ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
#ln -sf /usr/share/dnsmap/wordlist_TLAs.txt /usr/share/wordlists/dnsmap.txt
#ln -sf /usr/share/golismero/wordlist/wfuzz/Discovery/all.txt /usr/share/wordlists/wfuzz.txt
#ln -sf /usr/share/nmap/nselib/data/passwords.lst /usr/share/wordlists/nmap.lst
#ln -sf /usr/share/set/src/fasttrack/wordlist.txt /usr/share/wordlists/fasttrack.txt
#ln -sf /usr/share/termineter/framework/data/smeter_passwords.txt /usr/share/wordlists/termineter.txt
#ln -sf /usr/share/w3af/core/controllers/bruteforce/passwords.txt /usr/share/wordlists/w3af.txt
#ln -sf /usr/share/wpscan/spec/fixtures/wpscan/modules/bruteforce/wordlist.txt /usr/share/wordlists/wpscan.txt
##ln -sf /usr/share/arachni/spec/fixtures/passwords.txt /usr/share/wordlists/arachni
##ln -sf /usr/share/cisco-auditing-tool/lists/passwords /usr/share/wordlists/cisco-auditing-tool/
##ln -sf /usr/share/wpscan/spec/fixtures/wpscan/wpscan_options/wordlist.txt /usr/share/wordlists/wpscan-options.txt
##--- Not enough? Want more? Check below!
##apt-cache search wordlist
##find / \( -iname '*wordlist*' -or -iname '*passwords*' \) #-exec ls -l {} \;


##### Installing apt-file ~ find which package includes a specific file
echo -e "\e[01;32m[+]\e[00m Installing apt-file"
apt-get -y -qq install apt-file
apt-file update


##### Configuring samba ~ file transfer method
echo -e "\e[01;32m[+]\e[00m Configuring samba"
#--- Install samba
apt-get -y -qq install samba
#--- Create samba user
useradd -M -d /nonexistent -s /bin/false samba
#--- Use samba user
file=/etc/samba/smb.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/guest account = .*/guest account = samba/' $file 2>/dev/null || sed -i 's/\[global\]/\[global\]\n   guest account = samba/' $file
#--- Create samba path and configure it
mkdir -p /var/samba/
chown -R samba:samba /var/samba/
chmod -R 0770 /var/samba/
#--- Setup samba paths
grep -q '^\[shared\]' $file 2>/dev/null || echo -e '\n[shared]\n   comment = Shared\n   path = /var/samba/\n   browseable = yes\n   read only = no\n   guest ok = yes' >> $file
#grep -q '^\[www\]' $file 2>/dev/null || echo -e '\n[www]\n   comment = WWW\n   path = /var/www/\n   browseable = yes\n   read only = yes\n   guest ok = yes' >> $file
#--- Check result
#service samba restart
#smbclient -L \\127.0.0.1 -N
#service samba stop


##### Setting up SSH
echo -e "\e[01;32m[+]\e[00m Setting up SSH"
apt-get -y -qq install openssh-server
#--- Wipe current keys
rm -f /etc/ssh/ssh_host_*
rm -f /root/.ssh/*
#--- Generate new keys
#ssh-keygen -A   # Automatic method - we lose control of amount of bits used
ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P ""
ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P ""
ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P ""
ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P ""
ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -P ""
#--- Enable ssh at startup
#update-rc.d -f ssh defaults


##### Cleaning the system
echo -e "\e[01;32m[+]\e[00m Cleaning the system"
#--- Clean package manager
for FILE in clean autoremove autoclean; do apt-get -y -qq $FILE; done                     # Clean up
apt-get -y purge $(dpkg -l | tail -n +6 | grep -v '^ii' | awk '{print $2}')               # Purged packages
#--- Update slocate database
updatedb
#--- Reset folder location
cd ~/ &>/dev/null
#--- Remove any history files (as they could contain sensitive info)
history -c    # Will not work with ZSH
for i in $(cut -d: -f6 /etc/passwd | sort | uniq); do
  [ -e "$i" ] && find "$i" -type f -name '.*_history' -delete
done


##### Time taken (roughly)
finish_time=$(date +%s)
echo -e "\e[01;33m[i]\e[00m Time taken: $(( $(( finish_time - start_time )) / 60 )) minutes"


#-Done--------------------------------------------------#


##### Done!
echo -e "\e[01;33m[i]\e[00m Highly suggest rebooting the machine (before checking the above output)"
echo -e "\e[01;33m[i]\e[00m Do not forget to:"
echo -e "\e[01;33m[i]\e[00m   + Sort out Iceweasel add-ons"
echo -e "\e[01;33m[i]\e[00m   + Take a snapshot (...if you are using a VM)"

echo -e '\n\e[01;32m[+]\e[00m Done!\n'
#reboot
