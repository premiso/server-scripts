#!/bin/bash
# This is the script I use to initial most of my lowend VPS's. 
# Use at your own risk.

# Edit these variables
SSHPUBKEYURL=<link to your pubkey url>
PACKAGES_TO_REMOVE="apache*" # space seperated (debian setup)
PACKAGES_TO_INSTALL="openvpn-server" # space seperate (Debian setup)
LOCAL_USER_NAME=<insert desired username>
# End of edit variables

# start functions
fetchPubKey () {
	SSHPUBKEY=`exec wget -q -O - $SSHPUBKEYURL`
}

removePackages() {
	apt-get purge $PACKAGES_TO_REMOVE | echo 'Y'
}

installPackages() {
	apt-get update
	apt-get install $PACKAGES_TO_INSTALL | echo 'Y'
}

copySSHConf() {
	echo `exec wget -q -O - $SSH_CONF_URL` > /etc/sshd_config
}

addUser() {
	adduser $LOCAL_USER_NAME

	echo "$LOCAL_USER_NAME	ALL=(ALL) ALL" >> /etc/sudoers
	mkdir -p /home/$LOCAL_USER_NAME/.ssh

	fetchPubKey

	echo $SSHPUBKEY > /home/$LOCAL_USER_NAME/.ssh/authorized_keys
	chmod 0600 /home/$LOCAL_USER_NAME/.ssh/authorized_keys

	chown -R $LOCAL_USER_NAME:$LOCAL_USER_NAME /home/$LOCAL_USER_NAME/.ssh
}


