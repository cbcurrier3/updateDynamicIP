#/bin/bash
#
# A very simple bash script that uses Check Point R80.10 APIs in order to check and update your dynamic public IP address.
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
export LD_LIBRARY_PATH=/opt/CPsuite-R80/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPsuite-R80/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPshrd-R80/lib:/opt/CPshrd-R80/web/Apache/lib:/opt/CPshrd-R80/database/postgresql/lib:/opt/CPshrd-R80/lib64:/opt/CPsuite-R80/fw1/lib:/opt/CPsuite-R80/fg1/lib:/opt/CPppak-R80/lib:/opt/CPdiag-R80/lib:/opt/CPportal-R80/lib:/opt/CPrt-R80/lib:/opt/CPrt-R80/log_indexer/lib:/opt/CPuepm-R80/lib:/opt/CPuepm-R80/apache22/lib:/opt/CPvsec-R80/lib:/opt/CPcvpn-R80/lib:/opt/CPshrd-R80/database/postgresql/lib:/opt/CPshrd-R80/lib64

OLD_IP="$(/opt/CPshrd-R80/bin/mgmt_cli show host name $PPP_OBJ -u $USER -p $PASSWORD | grep 'ipv4' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')"

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
  /opt/CPshrd-R80/bin/mgmt_cli set host name $PPP_OBJ ipv4-address $PUBLIC_IP -u $USER -p $PASSWORD ignore-warnings true

  echo "Updating gw object topology.."
  GW_OBJ="$(/opt/CPshrd-R80/bin/mgmt_cli show simple-gateway name $GW_OBJ -u $USER -p $PASSWORD -f json)"
  x=$(/opt/CPshrd-R80/bin/jq -r '.interfaces[]' <<< "${GW_OBJ}")
  echo $x > tmp.txt
  sed -i "s/$OLD_IP/$PUBLIC_IP/g" tmp.txt
  sed -i "s/} {/}, {/g" tmp.txt
  payload=[`cat tmp.txt`]
  /opt/CPshrd-R80/bin/mgmt_cli set simple-gateway name $GW_OBJ ipv4-address "$PUBLIC_IP" interfaces "$payload" -u $USER -p $PASSWORD ignore-warnings true
  
  echo "Installing policies"
  /opt/CPshrd-R80/bin/mgmt_cli install-policy policy-package $POLICY access true threat-prevention false -u $USER -p $PASSWORD
fi

echo ""
echo ""

exit 0
