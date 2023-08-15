#!/bin/bash
#xfce_desktop by Keamenophys (Somekind of FreeBSD Studio and Workstation)
#Version 2.5

test $? -eq 0 || exit 1 "NEED TO BE ROOT TO RUN THIS"

echo "Bienvenue sur X240 base script"
echo "Ce script installera un systeme de base pur un thinkpad X240"
echo "WARNING!! - Execute only in a fresh vanilla installation"
sleep 5

## CHANGE FreeBSD REPOS TO LATEST
# sed -i '' 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

## REBUILD AND UPDATE PKG DATABASE 
echo "mise a jour des packages..."
echo ""
pkg update && pkg upgrade -y
echo ""

## FETCH FreeBSD PORTS
echo "Telechargement Arborescence des Ports pour la première fois...";
echo ""
portsnap fetch auto
echo ""

## COMPILE CPU OPTIMIZED APPLICATIONS
echo "Ajout du nombre de CPU dans make.conf";
touch /etc/make.conf
CPUCORES=$(sysctl hw.ncpu | cut -d ":" -f2 | cut -d " " -f2)
echo "CPUTYPE?=native" >> /etc/make.conf
echo "MAKE_JOBS_NUMBER?=$CPUCORES" >> /etc/make.conf
echo "OPTIONS_SET=OPTIMIZED_CFLAGS CPUFLAGS" >> /etc/make.conf

## INSTALLS BASE DESKTOP AND CORE UTILS
echo "Installation du bureau..."
echo ""
xargs pkg install -y < install_XDM

## ENABLES BASIC SYSTEM SERVICES
echo "Enabling basic services"
sysrc moused_enable="YES"
sysrc dbus_enable="YES"
sysrc update_motd="NO"
sysrc rc_startmsgs="NO"

echo ""

## CONFIGURATION DE XDM 

echo "xsetroot -solid black" > /usr/local/etc/X11/xdm/Xsetup_0

mv /usr/local/etc/X11/xdm/Xresources /usr/local/etc/X11/xdm/Xressources.bk
mv Xresources /usr/local/etc/X11/xdm/

mv /etc/ttys /etc/ttys.bk
mv ttys /etc/

## CHANGE SLIM THEME TO FBSD
# sed -i '' 's/current_theme       default/current_theme       fbsd/g' /usr/local/etc/slim.conf

## CREATES .xinitrc SCRIPT FOR A REGULAR DESKTOP USER
echo read -p "Want to enable XFCE for a regular user? (yes/no): " X;
echo ""
if [ "$X" = "yes" ]
then
    echo ; read -p "pour quel utilisateur ? " user;
    touch /usr/home/$user/.xinitrc
    echo 'exec xfce4-session' >> /usr/home/$user/.xinitrc
    echo ""
    echo "$user activé"
 else fi

## CONFIGURES AUTOMOUNT FOR THE REGULAR DESKTOP USER
touch /usr/local/etc/automount.conf
echo "USERUMOUNT=YES" >> /usr/local/etc/automount.conf
echo "USER=$user" >> /usr/local/etc/automount.conf
echo "FM='thunar'" >> /usr/local/etc/automount.conf
echo "NICENAMES=YES" >> /usr/local/etc/automount.conf
echo "/media		-media		-nosuid" >> /etc/auto_master
echo "notify 100 {
	match "system" "GEOM";
	match "subsystem" "DEV";
	action "/usr/sbin/automount -c";
};" >> /etc/devd.conf
sysrc autofs_enable="YES"

## SPECIAL PERMISSIONS FOR USB DRIVES AND WEBCAM
echo "perm    /dev/da0        0666" >> /etc/devfs.conf
echo "perm    /dev/da1        0666" >> /etc/devfs.conf
echo "perm    /dev/da2        0666" >> /etc/devfs.conf
echo "perm    /dev/da3        0666" >> /etc/devfs.conf
echo "perm    /dev/video0     0666" >> /etc/devfs.conf
echo ""

## ADDS USER TO CORE GROUPS
echo "Adding $user to video/realtime/wheel/operator groups"
pw groupmod video -m $user
pw groupmod audio -m $user
pw groupmod realtime -m $user
pw groupmod wheel -m $user
pw groupmod operator -m $user
pw groupmod network -m $user
pw groupmod webcamd -m $user
echo ""

## ADDS USER TO SUDOERS
#echo "Adding $user to sudo"
#echo "$user ALL=(ALL:ALL) ALL" >> /usr/local/etc/sudoers
#echo ""
#
touch /usr/local/etc/doas.conf

echo "permit nopass keepenv root     as root" >> /usr/local/etc/doas.conf
echo "permit nopass keepenv $user     as root" >> /usr/local/etc/doas.conf

## ENABLES LINUX COMPAT LAYER
echo "Enabling Linux compat layer..."
echo ""
kldload linux.ko
sysrc linux_enable="YES"
echo ""

## FreeBSD SYSTEM TUNING FOR BEST DESKTOP EXPERIENCE
echo "Optimizing system parameters and firewall..."
echo ""
mv /etc/sysctl.conf /etc/sysctl.conf.bk
mv /boot/loader.conf /boot/loader.conf.bk
mv /etc/login.conf /etc/login.conf.bk

mv sysctl.conf /etc/
mv login.conf /etc/
mv devfs.rules /etc/
mv loader.conf /boot/

sysrc devfs_system_ruleset="system"
# touch /etc/pf.conf
#echo 'block in all' >> /etc/pf.conf
#echo 'pass out all keep state' >> /etc/pf.conf
#
## CONFIGURES MORE CORE SYSTEM SERVICES
echo "Enabling additional system services..."
echo ""
#sysrc pf_enable="YES"
#sysrc pf_rules="/etc/pf.conf" 
#sysrc pflog_enable="YES"
#sysrc pflog_logfile="/var/log/pflog"
sysrc ntpd_enable="NO"
sysrc ntpdate_enable="NO"
sysrc powerd_enable="YES"
sysrc powerd_flags="-n hiadaptive -a hiadaptive -b adaptive"
sysrc performance_cx_lowest="C1"
sysrc economy_cx_lowest="Cmax"
sysrc clear_tmp_enable="YES"
sysrc clear_tmp_X="YES"
# sysrc fsck_y_enable="YES"
sysrc syslogd_enable="NO"
sysrc syslogd_flags="-ss"

# DAEMONS | no # -------------------------------------------------------------
sysrc sendmail_enable="NO"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc dumpdev="NO"
sysrc webcamd_enable="YES"


## UPDATES CPU MICROCODE
echo "mise a jour du CPU microcode..."
echo ""
pkg install -y devcpu-data
sysrc microcode_update_enable="YES"
service microcode_update start
echo ""
echo "Microcode est a jour"
echo ""

## CLEAN CACHES AND AUTOREMOVES UNNECESARY FILES
echo "Cleaning system..."
echo ""
pkg clean -y
pkg autoremove -y
echo ""

## DONE, PLEASE RESTART
echo "Installation done"
echo "Please, check now /boot/loader.conf and /etc/sysctl.conf if you need to make some changes"
echo "Also READ and EDIT the nVidia / Intel / AMD to install the GPU drivers in this step"
echo "Don't forget to reboot your system after that"
echo "BSD-XFCE by Wamphyre :)"
