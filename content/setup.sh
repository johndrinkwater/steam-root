#!/bin/sh
#
# Script to setup the Steam chroot environment on a new system

root=`dirname $0`
if [ -f /`basename $0` ]; then
	echo "You should run this from outside the chroot environment"
	exit 1
fi

# Set up any proxy environment
fgrep -v proxy "$root/etc/environment" >/tmp/environment_head
fgrep proxy /etc/environment >/tmp/environment_tail
cat /tmp/environment_head /tmp/environment_tail >"$root/etc/environment"

# Set up the machine ID
if [ -f /var/lib/dbus/machine-id ]; then
	cp /var/lib/dbus/machine-id "$root/var/lib/dbus/"
fi

# Set up the hostname and /etc/hosts
if [ -f /etc/hostname ]; then
	cp -v /etc/hostname "$root/etc/"
fi
cp -v /etc/hosts "$root/etc/"

#
# Set up the OpenGL drivers
#

# First copy base configuration
for file in /etc/alternatives/*gnu_gl_conf; do
	if [ -e "$file" ]; then
		cp -av $file "$root/etc/alternatives/"
		real=`readlink $file`
		if [ -f "$real" ]; then
			mkdir -p "$root/`dirname $real`"
			cp -av "$real" "$root/$real"
		fi
	fi
done

# If the 32-bit GL config is empty, use the 64-bit config, which should work
if [ -f "$root/etc/alternatives/i386-linux-gnu_gl_conf" -a \
     ! -s "$root/etc/alternatives/i386-linux-gnu_gl_conf" -a \
     -s "$root/etc/alternatives/x86_64-linux-gnu_gl_conf" ]; then
	cp -av "$root/etc/alternatives/x86_64-linux-gnu_gl_conf" "$root/etc/alternatives/i386-linux-gnu_gl_conf"
fi

# Copy standard OpenGL library if it exists
if [ -f /usr/lib/libGL.so.1 ]; then
	cp -av /usr/lib/libGL.* "$root/usr/lib/"
fi

# Copy Mesa drivers if they exist
for path in /usr/lib/*/mesa /usr/lib/*/dri /usr/lib/*/libLLVM-*
do
	if [ -e "$path" ]; then
		root_path="$root/`dirname $path`"
		mkdir -p "$root_path"
		cp -av $path "$root_path"
	fi
done

# Copy NVIDIA drivers if they exist
for path in /usr/lib/nvidia* /usr/lib32/nvidia*
do
	if [ -e "$path" ]; then
		root_path="$root/`dirname $path`"
		mkdir -p "$root_path"
		cp -av $path "$root_path"
	fi
done

# Copy AMD drivers if they exist
for path in /usr/lib/fglrx /usr/lib32/fglrx /usr/lib/dri \
            /etc/alternatives/i386-linux-gnu_fglrx_dri \
            /etc/alternatives/x86_64-linux-gnu_fglrx_dri
do
	if [ -e "$path" ]; then
		root_path="$root/`dirname $path`"
		mkdir -p "$root_path"
		cp -av $path "$root_path"
	fi
done

# Copy VirtualBox accelerated 3D drivers
for path in /usr/lib/VBoxOGL* /opt/VBoxGuestAdditions*/lib/VBoxOGL*
do
	if [ -e "$path" ]; then
		root_path="$root/`dirname $path`"
		mkdir -p "$root_path"
		cp -av $path "$root_path"
	fi
done

# Fixups for AMD drivers on 64-bit host
if [ -L "$root/usr/lib/dri/fglrx_dri.so" -a -e "$root/usr/lib32/fglrx/dri/fglrx_dri.so" ]; then
	ln -sf /usr/lib32/fglrx/dri/fglrx_dri.so "$root/usr/lib/dri/fglrx_dri.so"
fi

# Update the library path cache
/sbin/ldconfig -r "$root"
