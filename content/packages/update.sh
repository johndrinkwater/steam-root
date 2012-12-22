#!/bin/sh

# Use root path
export PATH=/sbin:$PATH

# Use proxy environment
. /etc/environment; export http_proxy

# Add Valve software source key
sudo apt-key add /packages/signature.gpg

# Upgrade environment
sudo apt-get -y update
sudo apt-get -y dist-upgrade

# Install additional packages
arch=`dpkg --print-architecture`
packages=`cat /packages/packages-*-all.txt /packages/packages-*-$arch.txt | fgrep -v '#'` 2>/dev/null
if [ "$packages" ]; then
    # This is horrible, but we need to retry until we succeed here...
    while ! sudo apt-get -y install $packages; do
        echo "Retrying..."
        sleep 3
        sudo apt-get -y -f install
    done
fi

# A bunch of the i386 development packages conflict with the amd64 versions
if [ -f "/packages/manual-dev-$arch.txt" ]; then
    curr=`pwd`
    temp=`mktemp -d`
    cd "$temp"
    apt-get download `cat "/packages/manual-dev-$arch.txt"`
    for file in *.deb; do dpkg -x "$file" "$file.d"; done
    sudo cp -a */usr/lib/* /usr/lib
    cd "$curr"
    rm -rf "$temp"
fi
    
for package in /packages/*.deb; do
    if [ -f "$package" ]; then
        sudo dpkg -i "$package"
    fi
done

# Remove cached binary packages to save space
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/archives/partial/*
