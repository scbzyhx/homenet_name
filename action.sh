#! /bin/sh

echo "$*" >> /dhcp-script/echolog.log
action=$1
mac=$2
ip_addr=$3
host_name=$4
fname="/tmp/hosts/${ip_addr}"
pidfile="/var/run/dnsmasq.pid"


case $action in
	"add")
		#echo "add" >> /dhcp-script/echolog.log
		#We need to lookup, if previous record exists, then make a file and reload dnsmasq else do nothing
		;;
	"old")
		if [ -e fname ] ; then
			echo $fname >> /dhcp-script/echolog.log
		fi

		#echo "old" >> /dhcp-script/echolog.log
		;;
	"del")
		#echo "de" >> /dhcp-script/echolog.log
		
		#Just delete the dns record

		if [ -e "/tmp/hosts/${ip_addr}" ] ; then
			rm /tmp/hosts/${ip_addr}	
		fi
		;;
	*)
		echo "default" >> /dhcp-script/echolog.log
		;;
esac
		
