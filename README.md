
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

## 🛠 Tools & Language
- Bash shell scripting 
- Python (vici health stats using cron job)
- SSH

