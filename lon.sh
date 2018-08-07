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


#Installing SE

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

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local



# setting port ssh
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 444' /etc/ssh/sshd_config
service ssh restart


# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=3128/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 143"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart



#install squid
sudo apt-get -y install squid
wget https://raw.githubusercontent.com/nubmarlon/test/master/squid.conf -O /etc/squid/squid.conf
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart


# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear]
accept = 443
connect = 127.0.0.1:3128
END

#make certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=PH/ST=Manila/L=Manila/O=None/OU=None/CN=Nubmarlon/emailAddress=None"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

#Configure stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

# download script
cd /usr/bin
wget -O menu "https://cdn.rawgit.com/nubmarlon/test/95126675/menu.sh"
wget -O usernew "https://cdn.rawgit.com/nubmarlon/test/95126675/usernew.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew

# finishing
service ssh restart
service dropbear restart
service squid restart




echo "========================="
echo "Softether server configuration has been done!"
echo " "
echo "IP address: $MYIP"
echo "Virtual Hub: ${HUB}"
echo "Username: ${USER}"
echo "Auth: Anonymous"
echo "S.E. Server Password: ${SE_PASSWORD}"
echo "========================="
echo " "
echo "OpenSSH  : 22, 444"
echo "Dropbear : 143, 3128"
echo "SSL      : 443"
echo "Squid    : 8000, 8080"
echo "type menu (Displays a list of available commands)"
