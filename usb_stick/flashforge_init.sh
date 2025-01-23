#!/bin/sh
# script to be run off an USB stick to install software and
# run commands on the Flashforge Adventurer 3 3D printer
# Installs and enables SSH the SSH server by default, can be
# customized to install other software or run other commands
#

SRC_DIR=`dirname $0`
DST_DIR='/'

PACKAGE_INSTALL_CMD='/bin/opkg install'
COPY_CMD='/bin/cp -r'

# Show image on Adventurer 3 screen by cat-ing file to
# raw framebuffer device
show_image()
{
	/bin/cat $1 > /dev/fb0
	/bin/sync
}

# Install opkg packages located in packages subdirectory
install_packages()
{
	$PACKAGE_INSTALL_CMD $SRC_DIR/packages/*
	/bin/sync
}

# Copy files from files subdirectory
copy_files()
{
	$COPY_CMD $SRC_DIR/files/* $DST_DIR
	/bin/sync
}

# run scripts from scripts subdirectory
run_scripts()
{
	for i in `/bin/ls $SRC_DIR/scripts`
		do /bin/sh $SRC_DIR/scripts/$i
		/bin/sync
	done
}

# Main install function
install_main()
{
	show_image $SRC_DIR/framebuffer_images/start.img

	install_packages
	copy_files
	run_scripts

	show_image $SRC_DIR/framebuffer_images/end.img
}


install_main
exit 0
