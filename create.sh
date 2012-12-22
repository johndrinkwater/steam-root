#!/bin/sh

# Set up useful variables
distribution=precise # Codename for Ubuntu 12.04 LTS
actions=""
host_arch=`dpkg --print-architecture`

# Get to the script directory
cd `dirname $0`

exit_usage()
{
    echo "Usage: $0 [--create|--update|--archive|--shell] <arch> <version>" >&2
    exit 1
}
    
while [ "$1" ]; do
    case "$1" in
    --create|--update|--archive|--shell)
        actions="$actions $1"
        ;;
    --*)
        echo "Unknown command line parameter: $1" >&2
        exit_usage
        ;;
    *)
        if [ "$arch" = "" ]; then
            case "$1" in
            i386|amd64)
                arch=$1
                ;;
            *)
                echo "Unsupported architecture: $1, valid values are i386, amd64" >&2
                exit 1
                ;;
            esac
        elif [ "$version" = "" ]; then
            case "$1" in
            *.*.*)
                version=$1
                ;;
            *)
                echo "Expected version in the form major.minor.patch" >&2
                exit 1
                ;;
            esac
        else
            echo "Unknown command line parameter: $1" >&2
            exit_usage
        fi
        ;;
    esac

    shift
done

if [ -z "$arch" -o -z "$version" ]; then
    exit_usage
fi
mkdir -p $arch

# Set our root directory (but don't create it yet)
root=$arch/steam-root


check_create()
{
    if [ ! -f "$arch/$distribution-base.tgz" ]; then
        echo "Missing $arch/$distribution-base.tgz, creating..."
        sleep 1
        return 0
    fi

    if [ ! -d "$root" ]; then
        echo "Missing $root, creating..."
        sleep 1
        return 0
    fi

    if [ "$actions" ]; then
        case "$actions" in
        *--create*)
            return 0;;
        *)
            return 1;;
        esac
    fi

    # Default to not create unless we need to
    return 1
}

action_create()
{
    # Create the initial bootstrap
    bootstrap_archive=$arch/$distribution-base.tgz
    if [ ! -f $bootstrap_archive ]; then
        if [ "$arch" = "$host_arch" ]; then
            pbuilder_archive="$distribution-base.tgz" 
        else
            pbuilder_archive="$distribution-$arch-base.tgz" 
        fi
        if [ ! -f $HOME/pbuilder/$pbuilder_archive ]; then
            pbuilder-dist $distribution $arch create
        fi
        cp $HOME/pbuilder/$pbuilder_archive $bootstrap_archive || exit 2
    fi

    # Create our chroot directory
    rm -rf $root
    mkdir -p $root

    # Unpack it into our chroot directory
    tar zxf $bootstrap_archive --exclude=dev -C $root 
    mkdir $root/dev
}

mount_chroot()
{
    sudo mount -o bind /dev $root/dev
    sudo mount -o bind /dev/pts $root/dev/pts
    sudo mount -o bind /sys $root/sys
    sudo mount -o bind /proc $root/proc
}

unmount_chroot()
{
    sudo umount $root/dev/pts
    sudo umount $root/dev
    sudo umount $root/sys
    sudo umount $root/proc
}

unmount_exit()
{
    unmount_chroot
    exit 2
}

check_update()
{
    if [ "$actions" ]; then
        case "$actions" in
        *--update*)
            return 0;;
        *)
            return 1;;
        esac
    fi

    # Default to always update
    return 0
}

action_update()
{
    # Copy in initial content
    cp -av content/* $root/

    # If sudo doesn't exist, we'll emulate it with fakeroot
    # This is because we don't want the chroot environment to require root
    # permissions for anything, in case normal users want to use it.
    if [ ! -e $root/usr/bin/sudo ]; then
        ln -s fakeroot $root/usr/bin/sudo
    fi

    # Set up proxy environment
    fgrep -v proxy $root/etc/environment >/tmp/environment_head
    fgrep proxy /etc/environment >/tmp/environment_tail
    cat /tmp/environment_head /tmp/environment_tail >$root/etc/environment

    # Run the update script in the chroot environment
    trap unmount_exit INT TERM
    mount_chroot
    sudo chroot $root /packages/update.sh
    unmount_chroot
    trap '' INT TERM

    # Change ownership to $USER so we can pack it up
    sudo chown -R $USER $root
}

check_shell()
{
    if [ "$actions" ]; then
        case "$actions" in
        *--shell*)
            return 0;;
        *)
            return 1;;
        esac
    fi

    # Default not to run the shell
    return 1
}

action_shell()
{
    # Run a shell in the chroot environment
    mount_chroot
    sudo chroot $root
    unmount_chroot

    # Change ownership to $USER so we can pack it up
    sudo chown -R $USER $root
}

check_archive()
{
    if [ "$actions" ]; then
        case "$actions" in
        *--archive*)
            return 0;;
        *)
            return 1;;
        esac
    fi

    # Default to always archive
    return 0
}

action_archive()
{
    # Back up completed environment
    echo "Archiving steam-root..."
    (cd $arch && tar zcf ../steam-root-$version-$arch.tgz steam-root)
    ls -l steam-root-$version-$arch.tgz
}

if check_create; then
    action_create
fi
if check_update; then
    action_update
fi
if check_shell; then
    action_shell
fi
if check_archive; then
    action_archive
fi
