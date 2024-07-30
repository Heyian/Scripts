#!/bin/sh

backdest="{your-backup-destination-dir}"
profiledir="{your-profile-dir}"
packageDest=$profiledir/.backup
#Infos pour le home folder
pc="{name-of-your-pc}"
distro="{your-distro}"
date=$(date "+%A")

# Exclude file location
prog=${0##*/} # Program name from filename
excdir="$profiledir/scripts"
#exclude_file="$excdir/$prog-exc.txt"
exclude_list="$profiledir/scripts/QTowerBak-exclusions.txt"

# -p, --acls and --xattrs store all permissions, ACLs and extended attributes. 
# Without both of these, many programs will stop working!
# It is safe to remove the verbose (-v) flag. If you are using a 
# slow terminal, this can greatly speed up the backup process.
# Use bsdtar because GNU tar will not preserve extended attributes.

#Backup du home folder
type=home
backupfile="$backdest/$date-$distro-$type.tar.gz"
bsdtar --exclude-from="$exclude_list" --acls --xattrs --totals -cpaf "$backupfile" $profiledir 2>&1 | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /var/log/backups/QTowerBak.log

#Export pacman packages
backupfile="$backdest/$date-pacman_pkglist.txt"
pacman -Qqen > $backupfile
pacman -Qqem > "$backdest/$date-pacman_foreign_pkglist.txt"
pacman -Qqen > "$packageDest/pacman_pkglist.txt"
pacman -Qqem > "$packageDest/pacman_foreign_pkglist.txt"

#Copy /usr/share files to .backup
#Plymouth themes
backupfile="$packageDest/usr_share/plymouth-themes.tar.gz"
bsdtar --acls --xattrs --totals -cpaf "$backupfile" /usr/share/plymouth/themes 2>&1 | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /var/log/backups/QTowerBak.log

#SDDM Themes
backupfile="$packageDest/usr_share/sddm-themes.tar.gz"
bsdtar --acls --xattrs --totals -cpaf "$backupfile" /usr/share/sddm/themes 2>&1 | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /var/log/backups/QTowerBak.log

#Icons
backupfile="$packageDest/usr_share/icons.tar.gz"
bsdtar --acls --xattrs --totals -cpaf "$backupfile" /usr/share/icons 2>&1 | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /var/log/backups/QTowerBak.log


#Copy /etc files to .backup
#Systemd services
cp /etc/systemd/system/* $packageDest/etc/system/systemd/

#Docker
cp /etc/docker/* $packageDest/etc/docker/

#Grub
cp /etc/default/grub $packageDest/etc/default/grub


