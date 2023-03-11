#arch installation script
#introduction
printf "\033c"
echo ".__.      .    ._.       ,    ..    ,           __.           , 
[__]._. _.|_    | ._  __-+- _.|| _.-+-* _ ._   (__  _.._.*._ -+-
|  |[  (_.[ )  _|_[ )_)  | (_]||(_] | |(_)[ )  .__)(_.[  |[_) | 
                                                          |     
"

#partition 
echo "\nLaunching cfdisk, configure your partitions : "
sleep 1.5
cfdisk /dev/nvme0n1

lsblk

echo "\nEnter partition for / : "
read root

echo "\nEnter partition for efi : "
read efi

echo "\nEnter partition for /home : "
read home
echo "\nDo you want to format /home partition (y/n) : "
read choice

echo "\nCreating efi partition..."
mkfs.fat -F 32 efi
echo "\nCreating root partition..."
mkfs.ext4 root
if [ $choice == 'y' ]:
  "\nCreating home partition..."
  mkfs.ext4 home


echo "\nMounting root partition on /mnt..."
mount root /mnt

echo "\nConnecting to wifi ... "
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl -P "PASSPHRASE" station wlan0 connect "NETWORKNAME"

echo "\nSyncing pacman repository..."
pacman -Syy --noconfirm

echo "\nInstalling reflector"
pacman -Sy reflector --noconfirm --needed

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

echo "\nUpdating pacman mirrorlist..."
reflector -c "IN" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf
echo "\nInstalling essential packages..."
pacstrap -K /mnt base linux linux-firmware vim nano --noconfirm --needed

echo "\nGenerating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc




