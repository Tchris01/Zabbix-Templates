#!/bin/bash
#nano zbx_vpnserver.sh
#chmod 700 zbx_vpnserver.sh
#apt install dos2unix
#0 0 * * * /usr/bin/find /opt/vpnserver/ -type f -name '*.log' -mtime +30 -exec /usr/bin/rm {} \;
#*/5 * * * * /etc/zabbix/zabbix_agentd.d/bin/zbx_vpnserver.sh > /dev/null 2>&1

IPZABBIX="1.2.3.4"
VPNSRVCMD="/opt/vpnserver/vpncmd"
VPNSRVIP="127.0.0.1"
VPNSRVPWD="111222333444555666777888999"
SENDERCMD="/usr/bin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf"

#Generation des stats du Serveur VPN
$VPNSRVCMD /SERVER $VPNSRVIP /PASSWORD:$VPNSRVPWD /CMD:ServerStatusGet > /tmp/serverstat.tmp
SRVUCASTOIN=$(cat /tmp/serverstat.tmp | grep "Incoming Unicast Total Size" | awk -F "|" '{ print $2 }' | sed 's/\,//g' | awk -F " " '{ print $1 }')
SRVUCASTOOUT=$(cat /tmp/serverstat.tmp | grep "Outgoing Unicast Total Size" | awk -F "|" '{ print $2 }' | sed 's/\,//g' | awk -F " " '{ print $1 }')
SRVMCASTOIN=$(cat /tmp/serverstat.tmp | grep "Incoming Broadcast Total Size" | awk -F "|" '{ print $2 }' | sed 's/\,//g' | awk -F " " '{ print $1 }')
SRVMCASTOOUT=$(cat /tmp/serverstat.tmp | grep "Outgoing Broadcast Total Size" | awk -F "|" '{ print $2 }' | sed 's/\,//g' | awk -F " " '{ print $1 }')

#Transmission des stats
$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k srv.unicast.in -o $SRVUCASTOIN
$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k srv.unicast.out -o $SRVUCASTOOUT
$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k srv.multicast.in -o $SRVMCASTOIN
$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k srv.multicast.out -o $SRVMCASTOOUT

#Generation liste des Hubs sur le serveur
$VPNSRVCMD /SERVER $VPNSRVIP /PASSWORD:$VPNSRVPWD /CMD:HubList > /tmp/hublist.tmp
$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k hub.discovery -o $(cat /tmp/hublist.tmp | grep "Virtual Hub Name" | awk -F "|" '{ print $2 }' | awk 'BEGIN{printf "{\"data\":["}; // {printf c"{\"{#VPNHUB}\":\""$1"\"}";c=","}; END{print "]}"}')


for hub in $(cat /tmp/hublist.tmp | grep "Virtual Hub Name" | awk -F "|" '{ print $2 }')
do
	echo "Hub $hub" > /tmp/cmd.tmp
	echo "StatusGet" >> /tmp/cmd.tmp
	$VPNSRVCMD /SERVER $VPNSRVIP /PASSWORD:$VPNSRVPWD /IN:/tmp/cmd.tmp /OUT:/tmp/$hub.tmp > /dev/null
	#Generation des stats pour chaque HUB
	HUBSTATUS=$(cat /tmp/$hub.tmp | grep "Status  " | awk -F "|" '{ print $2 }') 
	HUBTYPE=$(cat /tmp/$hub.tmp | grep "Type" | awk -F "|" '{ print $2 }')
	TOTALSESSION=$(cat /tmp/$hub.tmp | grep "Sessions" | grep -v "("  | awk -F "|" '{ print $2 }')
	CLISESSION=$(cat /tmp/$hub.tmp | grep "Client" | awk -F "|" '{ print $2 }')
	BRISESSION=$(cat /tmp/$hub.tmp | grep "Bridge" | awk -F "|" '{ print $2 }')
	REGUSER=$(cat /tmp/$hub.tmp | grep "Users" | awk -F "|" '{ print $2 }')
	HUBUCASTOIN=$(cat /tmp/$hub.tmp | grep "Incoming Unicast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
	HUBUCASTOOUT=$(cat /tmp/$hub.tmp | grep "Outgoing Unicast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
	HUBMCASTOIN=$(cat /tmp/$hub.tmp | grep "Incoming Broadcast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
	HUBMCASTOOUT=$(cat /tmp/$hub.tmp | grep "Outgoing Broadcast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
	
	rm -f /tmp/zabsend.tmp
	#Transmission des stats pour chaque HUB
	echo "\"$(/bin/hostname -s)\" \"hub.status[$hub]\" \"$HUBSTATUS\"" > /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.type[$hub]\" \"$HUBTYPE\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.total.session[$hub]\" \"$TOTALSESSION\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.session.client[$hub]\" \"$CLISESSION\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.session.bridge[$hub]\" \"$BRISESSION\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.users.registered[$hub]\" \"$REGUSER\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.unicast.in[$hub]\" \"$HUBUCASTOIN\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.unicast.out[$hub]\" \"$HUBUCASTOOUT\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.multicast.in[$hub]\" \"$HUBMCASTOIN\"" >> /tmp/zabsend.tmp
	echo "\"$(/bin/hostname -s)\" \"hub.multicast.out[$hub]\" \"$HUBMCASTOOUT\"" >> /tmp/zabsend.tmp
	$SENDERCMD -z $IPZABBIX -i /tmp/zabsend.tmp

	#Generation liste des Utilisateurs sur le Hub
	echo "Traitement de $hub"
	echo "Hub $hub" > /tmp/cmd.tmp
	echo "UserList" >> /tmp/cmd.tmp
	rm -f /tmp/usrlst.tmp
	$VPNSRVCMD /SERVER $VPNSRVIP /PASSWORD:$VPNSRVPWD /IN:/tmp/cmd.tmp /OUT:/tmp/usrlst.tmp > /dev/null
	dos2unix /tmp/usrlst.tmp > /dev/null
	cat /tmp/usrlst.tmp | grep "User Name" | awk -F "|" '{ print $2 }' | awk -v hub="$hub" 'BEGIN{printf "{\"data\":["}; // {printf c"{\"{#HUB}\":\"" hub "\",\"{#USRHUB}\":\""$1"\"}";c=","}; END{print "]}"}' >> /tmp/lld$hub.tmp
	$SENDERCMD -z $IPZABBIX -s $(/bin/hostname -s) -k hub.user.discovery -o $(cat /tmp/lld$hub.tmp)

	#Transmission des stats pour chaque Hub Users 
	for usr in $(cat /tmp/usrlst.tmp | grep "User Name" | awk -F "|" '{ print $2 }')
	do
		echo "Traitement de $hub-$usr"
		echo "Hub $hub" > /tmp/cmd.tmp
		echo "UserGet $usr" >> /tmp/cmd.tmp
		$VPNSRVCMD /SERVER $VPNSRVIP /PASSWORD:$VPNSRVPWD /IN:/tmp/cmd.tmp /OUT:/tmp/$usr.tmp > /dev/null
		dos2unix /tmp/$usr.tmp  > /dev/null
		HUBUCASTOIN=$(cat /tmp/$usr.tmp | grep "Incoming Unicast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
		HUBUCASTOOUT=$(cat /tmp/$usr.tmp | grep "Outgoing Unicast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
		HUBMCASTOIN=$(cat /tmp/$usr.tmp | grep "Incoming Broadcast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
		HUBMCASTOOUT=$(cat /tmp/$usr.tmp | grep "Outgoing Broadcast Total Size" | awk -F "|" '{ print $2 }'| sed 's/\,//g' | awk -F " " '{ print $1 }')
		USRNBLOGIN=$(cat /tmp/$usr.tmp | grep "Number of Logins" | awk -F "|" '{ print $2 }')
		
		rm -f /tmp/zabsend.tmp		
		echo "\"$(/bin/hostname -s)\" \"user.login[$hub,$usr]\" \"$USRNBLOGIN\"" > /tmp/zabsend.tmp
		echo "\"$(/bin/hostname -s)\" \"user.unicast.in[$hub,$usr]\" \"$HUBUCASTOIN\"" >> /tmp/zabsend.tmp
		echo "\"$(/bin/hostname -s)\" \"user.unicast.out[$hub,$usr]\" \"$HUBUCASTOOUT\"" >> /tmp/zabsend.tmp
		echo "\"$(/bin/hostname -s)\" \"user.multicast.in[$hub,$usr]\" \"$HUBMCASTOIN\"" >> /tmp/zabsend.tmp
		echo "\"$(/bin/hostname -s)\" \"user.multicast.out[$hub,$usr]\" \"$HUBMCASTOOUT\"" >> /tmp/zabsend.tmp
		$SENDERCMD -z $IPZABBIX -i /tmp/zabsend.tmp
	done
done

rm -f /tmp/*.tmp