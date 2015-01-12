#!/bin/bash

#
# NOTE: This script is run within the chroot after second stage debootstrap!
#

set -e

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 DIST DIST_URL KERNEL_VERSION INSTALL_KODI"
	exit 1
fi

DIST=$1
DIST_URL=$2
KERNEL_VERSION=$3
INSTALL_KODI=$4
MARILLAT_URL="http://www.deb-multimedia.org"

echo "Running postinstall.sh script..."

# Set root password
echo "root:root" | chpasswd

# Set the locale
sed -i "s/^#[[:space:]]*en_US\.UTF-8\(.*\)/en_US\.UTF-8\1/g" /etc/locale.gen
locale-gen

# Set timezone
dpkg-reconfigure -f noninteractive tzdata

# Initialize /etc/apt/sources.list
echo "deb $DIST_URL $DIST main contrib non-free" > /etc/apt/sources.list
echo "deb-src $DIST_URL $DIST main contrib non-free" >> /etc/apt/sources.list

# Install marillat repo
echo "deb $MARILLAT_URL $DIST main non-free" >> /etc/apt/sources.list

# Update apt
apt-get update

# Generate the initial ramfs
update-initramfs -c -t -k $KERNEL_VERSION

insserv framebuffer-start
insserv hostname-init
insserv zram

# Prevent apt-get from starting services
echo "#!/bin/sh
exit 101
" > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# Run custom install scripts
if [ -d "/postinst" ]; then
	for i in /postinst/* ; do
		if [ -x "$i" ]; then
			echo "Running post-install script $i..."
			$i
		fi
	done
fi


# Install Kodi
if [ "$INSTALL_KODI" = "1" ]; then
    apt-get install -y --force-yes kodi-standalone kodi
fi

# Re-enable services to start
rm /usr/sbin/policy-rc.d

# Cleanup
apt-get clean

