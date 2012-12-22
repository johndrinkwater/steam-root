
This is a chroot environment of Ubuntu 12.04 LTS

To set it up, please unpack the steam-root archive that matches your system architecture, and run setup.sh, which is designed to copy your 3D drivers into the chroot environment.

You can also install schroot, which is an easy way of setting up the chroot environment without requiring root permissions.

Once schroot is installed, you can add an entry to /etc/schroot/schroot.conf, replacing $USER with your username, and $HOME/steam-root with the full path to the steam-root directory:
[steam-$USER]
type=directory
users=$USER
directory=$HOME/steam-root

Make sure that /run and /run/shm are enabled in /etc/schroot/mount-defaults:
/run            /run            none    rw,bind         0       0
/run/shm        /run/shm        none    rw,bind         0       0

Then, enter the chroot environment with:
schroot -c steam-$USER

# Do a final ldconfig step to update the cache:
/sbin/ldconfig

# Set your DISPLAY environment variable
export DISPLAY=:0

# Run steam!
steam
