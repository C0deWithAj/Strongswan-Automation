#!/bin/bash

NODE_NAME=`uname -n`
SS_SYS_DIR=/etc/strongswan
SS_LOCAL_DIR=/root/strongswan #Fo keeping SS certificates - mandatory
SS_SETUP_DIR=/root/VPNServer/Strongswan # To keep our setup files from Git - not require after installation
SS_SETUP_CONFIG_FILES=$SS_SETUP_DIR/files/configs
SS_SETUP_CERTS=$SS_SETUP_DIR/files/android-certs
SS_SETUP_SCRIPTS=$SS_SETUP_DIR/files/scripts

SS_SETUP_CRON_DIR=$SS_SETUP_SCRIPTS/cron_jobs #Containing Crons for config - not required after setups
SS_LOCAL_CRON_DIR=$SS_LOCAL_DIR/cron_jobs     #always required




FILE_SERVER_INFO="SERVER_INFO.conf"
FILE_STATS_CONN_CRON=$SS_LOCAL_CRON_DIR/ActiveConnection.py  # Always required
FILE_STATS_CONN_CONFIG=$SS_SETUP_CRON_DIR/ActiveConnection.py        #Not required after running setup
FILE_CRON_RESULT=$SS_LOCAL_CRON_DIR/CronResults.txt


SERVER_TYPE=$1 # First param:  FREE/PREMIUM

function check_params()
{
  serv_type="${SERVER_TYPE,,}"
  	if [ "$serv_type" != "free" ] && [ "$serv_type" != "premium" ]; then
      echo -e "***Parameters Required***"
      echo "Please pass a parameter Free or Premium with file execution e.g ./setupvpn.sh Free"
      echo "Exiting.."
      exit
   fi
}



function check_os()
{
	echo '===================================================='
	echo '---Checking OS requirements---'
	RELEASE=`cat /etc/redhat-release`
	SUBSTR=`echo $RELEASE|cut -c1-22`
	if [ "$SUBSTR" == "CentOS Linux release 7" ]
	then
	    echo "OS: $RELEASE... valid"
	else
	    echo "OS: $RELEASE... invalid"
		echo 'Centos 7 is required.'
		echo 'Exiting...'
		exit
	fi
}

function install_strongswan()
{
	echo "---Installing Strongswan---"
	# Lets check if we have strongswan installed already
	# Also check for correct version if installed.
	if hash strongswan 2>/dev/null; then
		echo "Strongswan is already installed"
		# lets check if we have valid strongswan version
		SS_VERSION=`strongswan --version`
		SS_VERSION=`echo $SS_VERSION|cut -c1-50`
		if [[ "$SS_VERSION" == $"Linux strongSwan U5.6.1"* ]]
		then
		    echo "StrongSwan: [$SS_VERSION]... valid"
			#TODO: Maybe we need to stop the running instance
			return
		else
			echo 'Exiting version of Strongswan is invalid'
			echo '[$SS_VERSION]'
			echo 'Please uninstall exiting. Correct version will be intalled automatically.'
			exit
		fi
	fi
	# We dont have an existing installed package
	# TODO: Lets install it using yum
        echo "Installing epel repository"
        yum install http://ftp.nluug.nl/pub/os/Linux/distr/fedora-epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm -y
        echo "Finished installing epel repo"
        echo "Installing strongswan"
        yum install strongswan-5.7.2 -y
        if hash strongswan 2>/dev/null; then
               echo "Strongswan installed successfully"
         else
               echo "Error: Required strongswan couldn't install. Please update epel repo"
               exit
        fi

}

function install_openssl()
{

  #Check if openssl is installed already
       if hash openssl 2>/dev/null; then
           echo "Openssl already installed"
           echo "-->Updating Openssl to incorporate latest packages"
           yum update openssl -y
           return
       #TODO Install opensll
           echo "Installing openssl"
           yum install openssl
        fi

}



# NOTE: Requires further furnishing
function generate_certificates()
{
   if [ ! -d "$SS_LOCAL_DIR" ]; then
     echo "Creating strongswan directory"
     mkdir /root/strongswan
    else
     rm $SS_LOCAL_DIR/.
   fi

   #    echo "Copying Android certificate"
   #  cp -Rf $SS_SETUP_CERTS/. $SS_LOCAL_DIR


   #cp -Rf $SS_SETUP_DIR/files/scripts/. $SS_LOCAL_DIR
  # echo "*files copied*"

  # cp -Rf $SS_SETUP_CERTS/


   echo "-->Generate Certificates"
   chmod +x $SS_SETUP_SCRIPTS/server_key.sh
   chmod +x $SS_SETUP_SCRIPTS/client_key.sh

   OUTPUT="$(ip route get 1 | awk '{print $NF;exit}')"

   #$SS_SETUP_SCRIPTS/server_key.sh "${OUTPUT}"
   # Output = ip of server

   $SS_SETUP_SCRIPTS/server_key.sh "${OUTPUT}"
   $SS_SETUP_SCRIPTS/client_key.sh "tester" "tester@pentaloop.com"


   echo "*Certificates generated*"

}

#TODO: copy content of ipsec.conf and ipsec.secrets to strongswan
function setup_config_files()
{

  if [ ! -f "$SS_SYS_DIR/ipsec.conf" ]; then
    echo "Error: Ipsec.conf doesn't exist. Please uninstall strongswan and re-run the script again."
  exit
 fi


 cat "$SS_SETUP_CONFIG_FILES/ipsec.conf" > "$SS_SYS_DIR/ipsec.conf"

 if [ ! -f "$SS_SYS_DIR/ipsec.secrets" ]; then
    echo "Error: Ipsec.secrets doesn't exist. Please uninstall strongswan & re-run the script again"
   exit
 fi


 cat "$SS_SETUP_CONFIG_FILES/ipsec.secrets" > "$SS_SYS_DIR/ipsec.secrets"
 echo "*Done setting configuration files*"

}


#TODO: Add forwarding rule if it doesn't exist already
function allow_ipv4_forwarding()
{
  if [ ! -f "/etc/sysctl.conf" ]; then
    echo "Sysctl.conf file doesn't exist. This file is required for ipv4 forwarding. Please check with your linux administrator"
   break
  fi

  rule1="net.ipv4.ip_forward=1"
  rule2="net.ipv4.conf.all.accept_redirects = 0"
  rule3="net.ipv4.conf.all.send_redirects = 0"
  rule4="net.ipv4.ip_no_pmtu_disc = 1"

  #TODO: Add rules to sysctl file one by one without duplicating
  file=/etc/sysctl.conf
  grep -qF -- "$rule1" "$file" || echo "$rule1" >> "$file"
  grep -qF -- "$rule2" "$file" || echo "$rule2" >> "$file"
  grep -qF -- "$rule3" "$file" || echo "$rule3" >> "$file"
  grep -qF -- "$rule4" "$file" || echo "$rule4" >> "$file"


}


function configure_firewall()
{
  echo "---Configure firewall---"
  if [[ `firewall-cmd --state` = running ]]
 then
    echo "Firewall running already"
 else
     systemctl enable firewalld
     systemctl start firewalld
 fi

  echo "Adding firewall rules"
  firewall-cmd --permanent --add-service="ipsec"
  firewall-cmd --permanent --add-port=4500/udp
  firewall-cmd --permanent --add-port=500/udp
  firewall-cmd --permanent --add-masquerade
  firewall-cmd --reload
  echo "Firewall opened for VPN Server"
}


function setup_strongswan()
{
	echo "---Setup Strongswan---"
        generate_certificates
        echo "-->Setting configurtion files"
        setup_config_files
        echo "Allow ipv4 forwarding"
        allow_ipv4_forwarding
        #TODO: Turn off Duplicheck plugin
        #Must be turned off to use one credential for multiple android phones
        echo -e "duplicheck { \n enable = no \n load = no \n}" > /etc/strongswan/strongswan.d/charon/duplicheck.conf

        #TODO: Create meta data file for Server
        create_server_config
}


function create_server_config()
{
   if [ ! -f "$SS_LOCAL_DIR/$FILE_SERVER_INFO" ]; then
      touch $SS_LOCAL_DIR/$FILE_SERVER_INFO
   fi
      #TODO: Create conf file material
     echo -e "****Strongswan Server*****\nServerType: $SERVER_TYPE" > $SS_LOCAL_DIR/$FILE_SERVER_INFO
}


function configure_cron_job()
{
   echo "---Configure cron job----"
   if ! hash pip 2>/dev/null; then
     echo "--installing pip for python"
     yum install python-pip -y

     if ! hash pip 2>/dev/null; then
    echo "*ERROR* Pip installation failed. Please manually install pip and re-run the script"
      exit
     fi
   fi

   echo "Upgrading pip"
   pip install --upgrade pip


   if ! python -c "import vici" &> /dev/null; then
    echo "-->Installing Vici"
    pip install vici
   fi

   if ! python -c "import requests" &> /dev/null; then
    echo "-->Installing requests module for python"
    pip install requests
   fi


    if [ ! -d "$SS_LOCAL_CRON_DIR" ]; then
            mkdir $SS_LOCAL_CRON_DIR
        fi

    if [ -f "$FILE_STATS_CONN_CONFIG" ]; then
          cp -R -u -p  $SS_SETUP_CRON_DIR/.  $SS_LOCAL_CRON_DIR
        fi

      touch $FILE_CRON_RESULT
      chmod a+x $FILE_STATS_CONN_CRON #Permission for cron to execute this file

    echo "-->Scheduling Cron job"
    #write out current crontab
    crontab -l > mycron
    #echo new cron into cron file
    echo "* * * * * python $FILE_STATS_CONN_CRON >> $SS_LOCAL_CRON_DIR/CronResults.txt" >> mycron
    echo "* * * * * (sleep 29 ; python $FILE_STATS_CONN_CRON >> $SS_LOCAL_CRON_DIR/CronResults.txt)" >> mycron
    #install new cron file
    crontab mycron
    rm mycron


   echo "*** Cron job scheduled***"
   echo "******* Setup completed ************"

}


function startVPN()
{
   echo "-->Starting VPN"
   systemctl start strongswan
   systemctl enable strongswan
   echo "--->Restarting Strongswan"
   #NOTE: Strongswan restart is mandatory for loading secrets files
   strongswan restart
   echo "*******Strongswan has been configured successfully********"
   echo "NOTE: Copy Android certificate from /root/strongswan/certs/vpnHostCert.pem"

}

check_params
check_os
install_strongswan
install_openssl
setup_strongswan
configure_firewall
startVPN
configure_cron_job


