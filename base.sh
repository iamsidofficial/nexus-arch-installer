#!/bin/bash

# Print a fancy title
printf "\033c"
echo ".__.      .    ._.       ,    ..    ,           __.           , 
[__]._. _.|_    | ._  __-+- _.|| _.-+-* _ ._   (__  _.._.*._ -+-
|  |[  (_.[ )  _|_[ )_)  | (_]||(_] | |(_)[ )  .__)(_.[  |[_) | 
                                                          |     
"

# Partition the disk
echo "Time to partition your disk. Launching cfdisk..."
sleep 1.5
cfdisk /dev/nvme0n1

# Display available partitions
lsblk

# Get partition names from user
echo "Enter the name of the partition you want to use for / (e.g., /dev/nvme0n1p1): "
read root

echo "Enter the name of the partition you want to use for /efi: "
read efi

echo "Enter the name of the partition you want to use for /home: "
read home

echo "Do you want to format the /home partition? (y/n): "
read choice

# Format partitions
echo "Creating /efi partition..."
mkfs.fat -F32 $efi

echo "Creating / partition..."
mkfs.ext4 $root

if [ $choice == 'y' ]; then
  echo "Creating /home partition..."
  mkfs.ext4 $home
fi

# Mount the partitions
echo "Mounting partitions..."
mount $root /mnt
mount $home /mnt/home --mkdir
mount $efi /mnt/boot/efi --mkdir

# Connect to wifi
echo "Connecting to wifi..."
echo "Scanning for networks..."
iwctl station wlan0 scan
echo "Available networks:"
iwctl station wlan0 get-networks
echo "Enter the name of the network you want to connect to: "
read NETWORKNAME
echo "Enter the passphrase for $NETWORKNAME: "
read -s PASSPHRASE
iwctl -P "$PASSPHRASE" station wlan0 connect "$NETWORKNAME"

# Update pacman repository and mirrorlist
echo "Syncing pacman repository..."
pacman -Syy --noconfirm

echo "Installing reflector..."
pacman -Sy reflector --noconfirm --needed

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

echo "Updating pacman mirrorlist..."
reflector -c "IN" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf

# Install essential packages
echo "Installing essential packages..."
pacstrap -K /mnt base linux linux-firmware vim nano --noconfirm --needed

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Set Time-Zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$Region/$City /etc/localtime

# Generate /etc/adjtime
arch-chroot /mnt hwclock --systohc

# Generate locale
arch-chroot /mnt sed -i 's/^#LANG="en_US.UTF-8"/LANG="en_US.UTF-8"/g' locale.gen
arch-chroot echo "LANG=en_US.UTF-8" > locale.conf
arch-chroot locale-gen

# Set hostname
echo "Enter hostname for your system: "
read hostname
arch-chroot echo "$hostname" > /etc/hostname

# Set up hosts file
arch-chroot echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname" > /etc/hosts

# Set root password
echo "Time to set a root password. Don't make it 'password' this time, okay? ;)"
arch-chroot passwd

# Enable Parallel Downloads inside chroot
echo "Enabling parallel downloads to speed things up...hopefully"
arch-chroot sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf

# Notify user that base installation is done
echo "Base installation complete! Now onto the bootloader."

# Install Boot-Loader (GRUB)
echo "Installing GRUB bootloader"
arch-chroot pacman -S grub efibootmgr
arch-chroot grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
arch-chroot grub-mkconfig -o /boot/grub/grub.cfg

# Create additional user
echo "Creating a new user account...any ideas for a cool username?"
read username
arch-chroot useradd -m $username

# Set password for new user
echo "And what password would you like for $username? Make it a good one!"
arch-chroot passwd $username

# Add user to various groups for better access
arch-chroot usermod -aG wheel,audio,video,storage,libvirt $username

# Enable sudo access for new user
echo "Almost done! Enabling sudo access for $username"
arch-chroot pacman -S sudo
arch-chroot sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' 

# Notify user that installation is complete
echo "All done! Type 'umount -a' and reboot to enjoy your new Arch Linux installation!"

