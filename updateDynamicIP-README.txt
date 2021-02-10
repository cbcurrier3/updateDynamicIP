UpdateDynamicIP
 Edited 2/03/2021 9:00 am EST
 By CB Currier - https://github.com/cbcurrier3
 v4 - R81

A bash script that uses Check Point R81 APIs to check and update your dynamic public IP address
due to a shortcoming in the GAIA OS with pppoe interfaces.

Original script by Luca Fama
https://github.com/lfama/updateDynamicIP
Revised to address chages in newer Releases

Overview

If you are using a dynamic public IP address, this can change without knowing in advance (due to ISP configuration change, device reboot, etc.) especially when using ADSL Internet connection with PPPoE interface.
If your public IP address changes, you will not be able to perform some operation properly (manual NAT rules, VPN remote access, etc..).

This script checks if the object representing your public IP address is the actual public dynamic IP address you received from your ISP. If it's different, it means the IP changed, so the scripts uses several APIs in order to update the object IP address, update the gateway topology and install the policy.

Running this script as a cron job can be useful to continuously check if the public IP address changed, so that it can be updated with the newly assigned. The script prints some useful information while running, so you can easily redirect the output to a log file and keep track of the operations.

Prerequisites

Standalone environment (Management Server and Gateway are running in the same appliance).

I assume you have an object representing the dynamic public IP address you received from your ISP. This object can be used in policy rule base, NAT rules, and so on.

jq - A lightweight and flexible command-line JSON processor (already installed in R80.10 Management Server). I used this tool to parse the json object.

Installing

Copy the script in a folder (within the Management Server)
Open the script with a text editor and set the variables according to your environment
Give it execution permission
Put the script in crontab (for example you can run this job each 10 minutes)
Crontab example (redirecting standard output and error to a log file)

*/10 * * * * /home/cronuser/updateDynamicIP.sh >> /var/log/updateDynamicIP.log 2>&1

Cpd scheduler option (more stable):
    cpd_sched_config add updateDynamicIP -c /home/cronuser/updateDynamicIP.sh -e 14400 -s -r

    To see the configured tasks:
        cpd_sched_config print
    To disable a task:
        cpd_sched_config deactivate updateDynamicIP -r
    To Activate a diabled task:
        cpd_sched_config activate updateDynamicIP -r
    To delete a task:
        cpd_sched_config delete updateDynamicIP -r

Notes
 CBC - 2/03/2021
 * Rev V4 - Upgraded to R81 
 -------------
 Changes for this version v4
 -------------
 Library References upgraded to point to R81 directories.
 
 CBC - 4/23/2020
 * In the IFACE script the IPV6 and Comments fields have been skipped
 this is due to their values often not being populated and having not written
 a process to test and omit a field if not populated.
 a future release should address this.

 * It may be necessary to update the interface proces to use quotes around field values
 running without for now but this may be necessary due to the use of reserved characted
 being used in field values that may break the script.
 -------------
 Changes for this version v3
 -------------
 Script was updated to address errors in the use of the eval command which removed
 periods from the field names when generating them. Also updated the IFACE process
 to generate specific fields for reason detialed above.

 lfama - 1/30/2018
 I wrote this just for fun and to learn (and play) a little bit more about Check Point Management APIs.

 Only tested in R80.10 Standalone environment running on 3200 appliance.

Authors

 Luca Fama - Initial work - https://guthub.com/lfama

 CB Currier - Updates - https://guthub.com/cbcurrier3