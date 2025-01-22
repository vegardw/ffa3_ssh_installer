#!/bin/sh
# Fix permission on /root and subdirectories to enable SSH access
#

# On some Adventurer 3 printers the /root directory is not owned by
# root, leading to SSH not allowing logins. Also set directory and
# file permissions to be sure they are correct
chown -R root:root /root
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*

# Set permissions on other files
chmod +x /opt/auto_run.sh
