# UpdateDynamicIP

A very simple bash script that uses Check Point R80.10 APIs in order to check and update your dynamic public IP address.

## Overview

If you are using a dynamic public IP address, this can change without knowing in advance (due to ISP configuration change, device reboot, etc.) especially when using ADSL Internet connection whit PPPoE interface.   
If your public IP address changes, you will not be able to perform some operation properly (manual NAT rules, VPN remote access, etc..).

This script checks if the object representing your public IP address is the actual public dynamic IP address you received from your ISP. If it's different, it means the IP changed, so the scripts uses several APIs in order to update the object IP address, update the gateway topology and install the policy. 

Running this script as a cron job can be useful to continuously check if the public IP address changed, so that it can be updated with the newly assigned. The script prints some useful information while running, so you can easily redirect the output to a log file and keep track of the operations.

### Prerequisites

* Standalone environment (Management Server and Gateway are running in the same appliance).

* I assume you have an object representing the dynamic public IP address you received from your ISP. This object can be used in policy rule base, NAT rules, and so on.

* [jq](https://stedolan.github.io/jq/) - A lightweight and flexible command-line JSON processor (already installed in R80.10 Management Server). I used this tool to parse the json object.


### Installing

1. Copy the script in a folder (within the Management Server)
2. Open the script with a text editor and set the variables according to your environment
2. Give it execution permission
3. Put the script in crontab (for example you can run this job each 10 minutes)

Crontab example (redirecting standard output and error to a log file) 
```
*/10 * * * * /home/cronuser/updateDynamicIP.sh >> /var/log/updateDynamicIP.log 2>&1
```

### Notes

I wrote this just for fun and to learn (and play) a little bit more about Check Point Management APIs. 

Only tested in R80.10 Standalone environment running on 3200 appliance.

## Author

* **Luca Famà** - *Initial work* - [lfama](https://github.com/lfama)


