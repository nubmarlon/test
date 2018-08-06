#!/bin/bash
#
# 
# Mod by Nub Marlon
# ==================================================
clear
clear

echo "                                                      "
echo "                                                      "
echo "      _|             _|_|_|_|_|      _|      _|       "
echo "      _|             _|      _|      _|_|    _|       "
echo "      _|             _|      _|      _|  _|  _|       "
echo "      _|             _|      _|      _|    _|_|       "
echo "      _|_|_|_|_|     _|_|_|_|_|      _|      _|       "
echo "                                                      "
echo "                                                      "
echo "                     AUTO SCRIPT                      "
echo "                                                      "
echo " "

sleep 2

# initialization var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}

SERVER_PASSWORD=""
USER=""
HUB=""
SE_PASSWORD=""

echo "Your IP address is: $MYIP"
echo ""
echo -n "Set Virtual Hub: "
read HUB
echo -n "Set ${HUB} hub username: "
read USER
read -s -p "Set SE Server password: " SE_PASSWORD
echo ""
echo " "
echo "Now sit back and wait until the installation finished."
echo " "


sudo apt-get -y update && sudo apt-get -y upgrade && apt-get install expect -y

wget http://www.softether-download.com/files/softether/v4.27-9668-beta-2018.05.29-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.27-9668-beta-2018.05.29-linux-x64-64bit.tar.gz
sudo tar xvzf softether-vpnserver-v4.27-9668-beta-2018.05.29-linux-x64-64bit.tar.gz
rm -rf softether-vpnserver-v4.27-9668-beta-2018.05.29-linux-x64-64bit.tar.gz

sudo apt-get install checkinstall build-essential -y	



cd vpnserver && expect -c 'spawn make; expect number:; send 1\r; expect number:; send 1\r; expect number:; send 1\r; interact'

cd ..

sudo mv vpnserver/ /usr/local && chmod 600 * /usr/local/vpnserver/ && chmod 700 /usr/local/vpnserver/vpncmd && chmod 700 /usr/local/vpnserver/vpnserver

echo '#!/bin/sh
# description: SoftEther VPN Server
### BEGIN INIT INFO
# Provides:          vpnserver
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: softether vpnserver
# Description:       softether vpnserver daemon
### END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0' > /etc/init.d/vpnserver
###
chmod 755 /etc/init.d/vpnserver && /etc/init.d/vpnserver start
update-rc.d vpnserver defaults

HUB_PASSWORD=${SE_PASSWORD}

TARGET="/usr/local/"

sleep 2
${TARGET}vpnserver/vpncmd localhost /SERVER /CMD ServerPasswordSet ${SE_PASSWORD}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubCreate ${HUB} /PASSWORD:${HUB_PASSWORD}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserCreate ${USER} /GROUP:none /REALNAME:none /NOTE:none
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserAnonymousSet ${USER}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:vpn /DEFAULTHUB:${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubDelete DEFAULT
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD SecureNatEnable
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD VpnOverIcmpDnsEnable /ICMP:yes /DNS:yes

#install squid
sudo apt-get install squid
wget https://raw.githubusercontent.com/nubmarlon/test/master/squid.conf -O /etc/squid/squid.conf
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart




echo "========================="
echo "Softether server configuration has been done!"
echo " "
echo "IP address: $MYIP"
echo "Virtual Hub: ${HUB}"
echo "Port: 443, 992, 1194, 5555"
echo "Username: ${USER}"
echo "Auth: Anonymous"
echo "S.E. Server Password: ${SE_PASSWORD}"
echo "========================="
echo " "
echo "Squid Server"
echo "IP address: $MYIP"
echo "Port:3128, 8080, 80"


