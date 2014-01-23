 This script will find check if a remote host has filesystem in RO mode and
 reboot it if it has one. It requires sshpass for automating ssh login.
 sshpass is available here http://sourceforge.net/projects/sshpass/
 If you are lucky your distro might have a binary package.

 How it works:
 
 The script accepts a list of IP Addresses or hostnames as command line
 arguments. It will then ssh into each of them, password provided via sshpass.
 If it finds a fileystem mounted in read only, it ask for confirmation to 
 reboot the host. The list of hosts rebooted will be logged to hostlist.log.
 The script further checks if rebooted host(s) comes back online.

 Usage: ./scriptname <list of IP Addresses or hostnames