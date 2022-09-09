sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
#CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
sudo shutdown -r now
