#!/bin/bash
# This script will find and check if a remote host has filesystem in RO mode and
# reboot it if it has one. It requires sshpass for automating ssh login
# sshpass is available here http://sourceforge.net/projects/sshpass/
# How it works in detail:
# The script accepts a list of IP Addresses or hostnames as command line
# arguments. It will then ssh into each of them, password provided via sshpass.
# If it finds a fileystem mounted in read only, it ask for confirmation to 
# reboot the host. It will also logs the host to hostlist.log.
# The script further checks if rebooted host(s) comes back online.
#
# Usage: ./scriptname <list of IP Addresses or hostnames


# Validate command line arguments
if [[ $# -eq 0 ]]; then
        echo "Usage: ./scriptname <list of IP Addresses or hostnames>"
        exit
fi

# Check if sshpass is installed
which sshpass > /dev/null 2>&1
if [[  $? -ne 0 ]]; then
        echo "sshpass missing"
        echo "This script requires package sshpass"
        exit
fi

# Grab the root password for the remote hosts from user
echo "What is the common root root_password for remote remote_hosts?:"
read -s root_password

# Clear the tmp_hostlist.log if it exists
rm -rf tmp_hostlist.log > /dev/null 2>&1

# This is the actual command which will check for the a read-only mounted 
# filesystem, customize as required. The exceptions are placed in the second
# part of the pipe.

run_this="grep -w ro /proc/mounts | grep -v 'exception1\|exception2\|exception3'"

# Iterate for block thru all hosts in the command line arguments
for remote_host in $@
do
		# Run the command on the remote host and capture the output in ro_filesystem
        ro_filesystem=$(sshpass -p $root_password ssh -o StrictHostKeyChecking=no root@$remote_host $run_this)
        
		# The script enters this block if ro_filesystem is not empty.
		# If there are no RO filesystem, it will skip this block.
		if [[ ! -z $ro_filesystem ]]; then
				# Capture ro_filesystem into an array, each element separated
				# by newline. This is for display filesystems in RO mode	
                set -- "$ro_filesystem"
                IFS=$'\n';
                declare -a ro_fs_array=($*)
                echo "$remote_host has the following filesystem mounted in READ_ONLY mode"
                for line in "${ro_fs_array[@]}"
                do
					# grep is used instead of cat to highlight "ro"
					echo $line | grep --color  ro
                done

				# Get confirmation from user to reboot.	If rebooting,
				# log the hostname to a file.
                while true;
                do
                        echo "Do you want to reboot the remote_host?[y/n]:"
                        read answer
                        case $answer in
                        [Yy]*)  echo "Rebooting $remote_host"
                                echo $remote_host >> tmp_hostlist.log
								sshpass -p $root_password ssh -o StrictHostKeyChecking=no root@$remote_host reboot
                                break
                                ;;
                        [Nn]*) break;;
                        * ) echo "Please answer y or n.";;
                        esac
                done

        fi
done

# Check for rebooted host by way of checking
# tmp_hostlist.log exists
if [[ -f tmp_hostlist.log ]]; then
		# Append "date Reboot hosts:" to hostlist.log
        echo "$(date +"%x %X") Reboot hosts:" >> hostlist.log
		# Append the list of rebooted host in the current		
        cat tmp_hostlist.log >> hostlist.log
		
		# First check the host stop responding	
        echo "Checking hosts are DOWN"
        for remote_host in $(cat tmp_hostlist.log)
        do		
				# Ping the host until it stops responding
                ping -c1 $remote_host  > /dev/null 2>&1
                while [[ $? -eq 0 ]]
                do
                    echo "$remote_host is still UP"
                    sleep 2
                    ping -c1 $remote_host  > /dev/null 2>&1
                done
                echo "$remote_host is DOWN"
        done

		# Now check if they come back 
		echo "Checking hosts are UP"
		
        for remote_host in $(cat tmp_hostlist.log)
        do
			# Ping host until it responds
            ping -c1 $remote_host  > /dev/null 2>&1
            while [[ $? -ne 0 ]]
                do
                     echo "$remote_host is still DOWN"
                     sleep 2
                     ping -c1 $remote_host  > /dev/null 2>&1
				done
            echo "$remote_host is UP"
        done
		
		echo "All hosts up!"
		

echo "The following hosts with read-only filesystem were rebooted."
echo "The list of host(s) is logged to hostlist.log"	
cat tmp_hostlist.log  		
# Delete tmp_hostlist.log		
  rm -rf tmp_hostlist.log

else
	echo "The script did not find any host with a read-only filesystem."
fi
