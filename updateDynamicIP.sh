#/bin/bash
# AUTHOR: Luca Fama - Initial work - https://github.com/lfama
# Version R80.20 v1
# Updated 5/3/19 by CB Currier
#
# A very simple bash script that uses Check Point R80.20 APIs in order to check and update your dynamic public IP address.
# https://github.com/lfama/updateDynamicIP
#
#
### Edit the following variables according to your needs
# The Gateway object's name
GW_OBJ="gw-name"
# PPP interface object's name
PPP_OBJ="PPPobj"
# PPP interface name as it appears in the gateway (i.e., ifconfig output)
PPP_IFACE="pppoe1"
# Policy package name
POLICY="MyPolicy"
# Administrator username
USER="admin"
# Administrator password
PASSWORD="sup3rS3cr3t!"
echo "$(date)"

# You need this in order to run the script as a cron job
export LD_LIBRARY_PATH=/opt/CPsuite-R80.20/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPsuite-R80.20/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPshrd-R80.20/lib:/opt/CPshrd-R80.20/web/Apache/lib:/opt/CPshrd-R80.20/database/postgresql/lib:/opt/CPshrd-R80.20/lib64:/opt/CPsuite-R80.20/fw1/lib:/opt/CPsuite-R80.20/fg1/lib:/opt/CPppak-R80.20/lib:/opt/CPdiag-R80.20/lib:/opt/CPportal-R80.20/lib:/opt/CPrt-R80.20/lib:/opt/CPrt-R80.20/log_indexer/lib:/opt/CPuepm-R80.20/lib:/opt/CPuepm-R80.20/apache22/lib:/opt/CPvsec-R80.20/lib:/opt/CPcvpn-R80.20/lib:/opt/CPshrd-R80.20/database/postgresql/lib:/opt/CPshrd-R80.20/lib64

OLD_IP="$(/opt/CPshrd-R80.20/bin/mgmt_cli --port 4434 show host name $PPP_OBJ -u $USER -p $PASSWORD | grep 'ipv4' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')"

PUBLIC_IP="$(/bin/cp-ifconfig.sh $PPP_IFACE | grep "inet addr" |  grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)"

if [ -z "$OLD_IP" ]
then
  echo "Error while getting original public IP address... Exiting..."
  exit 1
fi

if [ -z "$PUBLIC_IP" ]
then
  echo "Error while getting current public IP address... Exiting..."
  exit 1
fi

echo "Old public IP address: $OLD_IP"
echo "Current public IP address: $PUBLIC_IP"


if [ "$OLD_IP" == "$PUBLIC_IP" ]
then
  echo "IP didn't change.. Nothing to do.. Exiting.."
else
  echo "IP changed.. Updating object, topology and installing policies.."
  echo ""
  echo "Updating PPP object IP address"
  /opt/CPshrd-R80.20/bin/mgmt_cli --port 4434 set host name $PPP_OBJ ipv4-address $PUBLIC_IP -u $USER -p $PASSWORD ignore-warnings true

  echo "Updating gw object topology.."

  $(/opt/CPshrd-R80.20/bin/mgmt_cli --port 4434 show simple-gateway name $GW_OBJ -u $USER -p $PASSWORD -f json > /var/log/tmp/tmp.txt )
  echo -n "" > /var/log/tmp/itmp.txt

  ifaces=$(cat /var/log/tmp/tmp.txt |jq -s -r '.[]|.interfaces[]' | jq -s -r 'map([]) |length');
  for ((a=0;a<$ifaces;a+=1));
   do b=$(($a + 1));
        resa=$( cat /var/log/tmp/tmp.txt |jq -s -r ".[] | .interfaces[$a] | with_entries(if .key == \"anti-spoofing-settings\" or .key == \"topology-settings\" or .key == \"security-zone-settings\" then empty else . end)| with_entries( .key |= \"interfaces.$b.\" + .)" );
        echo -n $resa >> /var/log/tmp/itmp.txt;

        resb=$( cat /var/log/tmp/tmp.txt |jq -s -r ".[] | .interfaces[$a] | with_entries(if .key == \"anti-spoofing-settings\" then . else empty end)| .[\"anti-spoofing-settings\"] |with_entries( .key |= \"interfaces.$b.anti-spoofing-settings.\" + .)" );
        echo -n $resb >> /var/log/tmp/itmp.txt;

        resc=$( cat /var/log/tmp/tmp.txt |jq -s -r ".[] | .interfaces[$a] | with_entries(if .key == \"topology-settings\" then . else empty end)| .[\"topology-settings\"] |with_entries( .key |= \"interfaces.$b.topology-settings.\" + .)" );
        echo -n $resc >> /var/log/tmp/itmp.txt;

        resd=$( cat /var/log/tmp/tmp.txt |jq -s -r ".[] | .interfaces[$a] | with_entries(if .key == \"security-zone-settings\" then . else empty end)| .[\"security-zone-settings\"] |with_entries( .key |= \"interfaces.$b.security-zone-settings.\" + .)" );
        echo -n $resd >> /var/log/tmp/itmp.txt;
   done

  sed -i "s/$OLD_IP/$PUBLIC_IP/g" /var/log/tmp/itmp.txt
  payload=$(cat /var/log/tmp/itmp.txt|sed -e "s/, \"/ /g" |sed -e "s/\":/ /g"|sed -e "s/\",/ /g"|sed -e "s/ }{ / /g"|sed -e "s/ }null{ / /g"|sed -e "s/{//g"|sed -e "s/}//g"|sed -e "s/\"interfaces/interfaces/g")

  echo "Installing policies"
  /opt/CPshrd-R80.20/bin/mgmt_cli --port 4434 set simple-gateway name $GW_OBJ $payload -u $USER -p $PASSWORD ignore-warnings true  --format json
  rm -rf /var/log/tmp/itmp.txt
  rm -rf /var/log/tmp/tmp.txt

fi

echo ""
echo ""

exit 0
