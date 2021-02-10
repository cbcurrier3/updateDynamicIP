#/bin/bash
#
# v4 - R81
# A very simple bash script that uses Check Point R81 APIs in order to check and update your dynamic public IP address.
# https://github.com/lfama/updateDynamicIP
# Revised to address chages in newer Releases
# Edited 2/03/2021 9:00 am EST
# By CB Currier <ccurrier@checkpoint.com>
#
### Edit the following variables according to your needs
#
# The Gateway object's name
GW_OBJ="gwname"
# PPP interface object's name
PPP_OBJ="pppoe_ext"
# PPP interface name as it appears in the gateway (i.e., ifconfig output)
PPP_IFACE="pppoe1"
# API Port
APIPort="443"
# Policy package name
POLICY="Standard"
# Administrator username
USER="admin"
# Administrator password
PASSWORD="password"

if [ -f /opt/CPshared/5.0/tmp/.CPprofile.sh ]; then
 . /opt/CPshared/5.0/tmp/.CPprofile.sh
fi

if [ -f /etc/rc.d/rc.local.user ]; then
  . /etc/rc.d/rc.local.user
fi

echo "-----------------"
echo "     Begin"
echo "-----------------"
echo "  $(date)"
echo "-----------------"

# You need this in order to run the script as a cron job
export LD_LIBRARY_PATH=/opt/CPsuite-R81/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPsuite-R81/fw1/oracle_oi/sdk:/opt/uf/SecureComputing/lib:/opt/KAV/ppl:/opt/KAV/lib:/opt/CPshrd-R81/lib:/opt/CPshrd-R81/web/Apache/lib:/opt/CPshrd-R81/database/postgresql/lib:/opt/CPshrd-R81/lib64:/opt/CPsuite-R81/fw1/lib:/opt/CPsuite-R81/fg1/lib:/opt/CPppak-R81/lib:/opt/CPdiag-R81/lib:/opt/CPportal-R81/lib:/opt/CPrt-R81/lib:/opt/CPrt-R81/log_indexer/lib:/opt/CPuepm-R81/lib:/opt/CPuepm-R81/apache22/lib:/opt/CPvsec-R81/lib:/opt/CPcvpn-R81/lib:/opt/CPshrd-R81/database/postgresql/lib:/opt/CPshrd-R81/lib64

OLD_IP="$(mgmt_cli --port 443 show host name $PPP_OBJ -u $USER -p $PASSWORD | grep 'ipv4' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')"
MGMT_IP="$(mgmt_cli --port 443 show simple-gateway name $GW_OBJ  -u $USER -p $PASSWORD --format json | jq -c .interfaces[]|grep Mgmt |jq . | grep ipv4-address | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')"

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
  /opt/CPshrd-R81/bin/mgmt_cli --port 443 set host name $PPP_OBJ ipv4-address $PUBLIC_IP -u $USER -p $PASSWORD ignore-warnings true
  echo "Updating gw object topology.."
  /opt/CPshrd-R81/bin/mgmt_cli --port 443 show simple-gateway name $GW_OBJ -u $USER -p $PASSWORD -f json > tmp.txt
  sed -i "s/$OLD_IP/$PUBLIC_IP/g" tmp.txt
  IFILE=$(cat tmp.txt)
  IFACES=$(cat tmp.txt |jq '.interfaces | length')
  OUT=""
  #for loop to pull each interface ...
  for (( E=1; E<=$IFACES; E++ ))
  do
    X=$((E-1))
    IFACE="cat tmp.txt | jq '.interfaces[$X]' | jq -c '{\"name\": .name,\"ipv4-address\": .\"ipv4-address\", \"ipv4-network-mask\": .\"ipv4-network-mask\", \"ipv4-mask-length\": .\"ipv4-mask-length\", \"color\": .\"color\",\"topology\": .\"topology\",\"anti-spoofing\": .\"anti-spoofing\", \"security-zone\": .\"security-zone\"}' |sed -e 's/\:{//g' -e 's/},/,/g' -e 's/}}/]/g' -e 's/{//g' -e 's/]//g' -e 's/}//g' -e 's/null//g' -e 's/  / /g'|awk -F, '{for (i=1;i<=NF;i++) printf \"interfaces.$E.\"\$i\", \"}'| sed -e 's/\\r\\n//g' -e 's/,/ /g' -e 's/  / /g' -e 's/\"\:/ /g'  >> ztest.txt "
eval $IFACE
    TOPSET="cat tmp.txt | jq -c '.interfaces[$X][\"topology-settings\"]' |sed -e 's/\:{//g' -e 's/},/,/g' -e 's/}}/]/g' -e 's/{//g' -e 's/}//g' -e 's/null//g' |awk -F, '{for (i=1;i<=NF;i++) printf \"interfaces.$E.topology-settings.\"\$i\",\"}'| sed -e 's/\\r\\n//g' -e 's/,/ /g' -e 's/\\\.\"/./g' -e 's/\" \"/ \"/g' -e 's/\"\:/ /g'  >> ztest.txt "
eval ${TOPSET%?}
   #   "security-zone-settings"
    ZONE="cat tmp.txt | jq -c '.interfaces[$X][\"security-zone-settings\"]' |sed -e 's/:{//g' -e 's/},/,/g' -e 's/}}/]/g' -e 's/{//g' -e 's/}//g' -e 's/null//g' |awk -F, '{for (i=1;i<=NF;i++) printf \"interfaces.$E.security-zone-settings.\"\$i\",\"}'| sed -e 's/\\r\\n//g' -e 's/,/ /g' -e 's/\\\.\"/./g' -e 's/\" \"/ \"/g' -e 's/\"\:/ /g'  >> ztest.txt "
eval ${ZONE%?}
   # "anti-spoofing-settings"
    ANTI="cat tmp.txt | jq -c '.interfaces[$X][\"anti-spoofing-settings\"]' |sed -e 's/\:{//g' -e 's/},/,/g' -e 's/}}/]/g' -e 's/{//g' -e 's/}//g' -e 's/null//g' |awk -F, '{for (i=1;i<=NF;i++) printf \"interfaces.$E.anti-spoofing-settings.\"\$i\",\"}'| sed  -e 's/\\r\\n//g' -e 's/,/ /g' -e 's/\\\.\"/./g' -e 's/\" \"/ \"/g' -e 's/\"\:/ /g'  >> ztest.txt "
eval ${ANTI%?}
  done
  sed -i "s/  / /g" ztest.txt
  sed -i 's/\."/\./g' ztest.txt
  sed -i 's/" "/ "/g' ztest.txt
  OUT=$(cat ztest.txt)
  echo "Updating $GW_OBJ Object Topology"
  /opt/CPshrd-R81/bin/mgmt_cli --port 443 set simple-gateway name $GW_OBJ ipv4-address "$MGMT_IP" $OUT -u $USER -p $PASSWORD ignore-warnings true
  #echo "Installing policy"
  /opt/CPshrd-R81/bin/mgmt_cli --port 443 install-policy policy-package $POLICY access true threat-prevention false -u $USER -p $PASSWORD
# if the ztest.txt file exists remove it.
  [ -f ztest.txt ] && rm ztest.txt
# if the tmp.txt file exists remove it.
  [ -f tmp.txt ] && rm tmp.txt
fi

echo ""
echo "-----------------"
echo "   Finished"
echo "-----------------"
echo "  $(date)"
echo "-----------------"

exit 0