# UpdateDynamicIP

A very simple bash script that uses Check Point R80.10 APIs in order to update the public IP address you got from your ISP.

## Getting Started

If you are using a dynamic public IP address, this can change without knowing in advance. If your public IP address changes, you will not be able to perform 
This script checks if the object representing your public IP address is the actual public dynamic IP address you received from your ISP. If it's different, it means the IP changed, so the scripts uses several APIs in order to update the object IP address, the gateway topology and installs the policies. 


### Prerequisites

I assume a standalone environment (Management Server and gateway are running in the same appliance).
I assume you have an object for the dynamic public IP address you received from your ISP. This object can be used in policy rule base, NATs, and so on.
jq --> a lightweight and flexible command-line JSON processor (already installed in R80.10 Management Server)

### Installing

1. Copy the script in a folder (within the Management Server)
2. Give it execution permission
3. Put the script in crontab

### Notes

Do not use it in a production environment! I wrote this just for fun and to learn (and play) a little bit more about Check Point Management APIs.

## Authors

* **Luca Famà** - *Initial work* - [PurpleBooth](https://github.com/lfama)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

