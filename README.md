
# Strongswan - IPSEC VPN Automation script

![](https://strongswan.org/images/strongswan_large.png)

### Introduction: 
This is a bash script to automate the configuration of a new Strongswan based VPN server. Additionally, it also contains python based  (vici API) cron jobs to consistently send health stats to your desired server.





#### What is strongswan: 
An Open Source IPsec-based VPN solution for Linux and other UNIX based operating systems implementing both the IKEv1 and IKEv2 key exchange


#### Why Strongswan:
I wanted to find  configure a VPN server that could serve both IOS and android Clients and has the freedom of being open source. 
Since, Strongswan supports IKEV2 hence it works flawlessly with IOS client. And similarly works flawlessly for IKEV-1 based android Client. 





## Pre-requisites: 

- Cent OS 7
- Linux Kernel required: 3.10.0-514

## Deployment:

To deploy this project login to your cent OS server through SSH and do:
```
Install strongSwan: 
```
The strongSwan packages are available in the Extra Packages for Enterprise Linux (EPEL) repository. We should enable EPEL first, then install strongSwan.

Next step: 
```
yum install http://ftp.nluug.nl/pub/os/Linux/distr/fedora-epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
yum install strongswan openssl
```

Generate certificates: 
Both the VPN client and server need a certificate to identify and authenticate themselves. I have prepared two shell scripts to generate and sign the certificates. Server_key.sh and client_key.sh are available in files/scripts section.  
First, We move these two scripts file into  /etc/strongswan/ipsec.d. Then: 

```
cd /etc/strongswan/ipsec.d
chmod a+x server_key.sh
chmod a+x client_key.sh
```

Organization names can be changed. If you want to change it, open the .sh files and replace O’s value with organization name. e.g,  O=YOUR_ORGANIZATION_NAME.

Next, use server_key.sh with the IP address of your server to generate the certificate authority (CA) key and certificate for server. Replace SERVER_IP with the IP address of your Vultr VPS.

./server_key.sh SERVER_IP
Generate the client key, certificate, and P12 file. Here, I will create the certificate and P12 file for the VPN user "john".

./client_key.sh test test@gmail.com  aaa
Replace "test" and his email with yours before running the script.

After the certificates for client and server are generated, copy /etc/strongswan/ipsec.d/test.p12 and /etc/strongswan/ipsec.d/cacerts/strongswanCert.pem to your local computer.



### Note: 
Rest of the strongswan configuration part is provided in the "Strongswan_configuration.odt" inside the Repo. 
## 🛠 Tools & Language
- Bash shell scripting 
- Python (vici health stats using cron job)
- SSH

