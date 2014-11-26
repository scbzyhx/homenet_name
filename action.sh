#! /bin/sh
RESOLVE_PATH=/tmp/hosts/
DB=/etc/db/hostdb.db
SQL=sqlite3
PID_FILE=/var/run/dnsmasq.pid
LOG=/tmp/yhx_dhcp.log
#echo "$*" >> /dhcp-script/echolog.log
action=$1
mac=$2
ip_addr=$3
host_name=$4

fname="${RESOLVE_PATH}${ip_addr}"

reload(){
	for pid in `cat $PID_FILE`
	do
		kill -HUP $pid
	done
}

hasAlias(){
	mac=$1;
	presentName=`$SQL $DB "select * from hostRecords where mac = '$mac'" | awk -F "|" '{printf $3}'`;
	#if [ "$presentName" != "" ]; then
	echo $presentName
	#fi
}

#1:ip,2:native name,3:newname
createAlias(){
	echo "$1 $2 $3" > ${RESOLVE_PATH}${1}
}

#1:MAC,2:IP,3:hostname
addNew(){
	presentName=`hasAlias "$1"`;
	#echo "after hasAlias"
	echo $presentName >> $LOG
	if [ "$presentName" != "" ]; then
		createAlias $2 $3 $presentName;
		reload;
		echo "createAlias: $2 $3 $presentName  ->  reload" >> $LOG
	fi
}
#
oldAction(){
	#do nothing	
	echo "Old and do nothing" >> $LOG;
	
}
#1:MAC,2:IP
delAction(){
	if [ -e "$RESOLVE_PATH$$2" ]; then
		rm "$RESOLVE_PATH$2"
		#RELOAD
		reload; 
		echo "rm $2 -> reload" >> $LOG;
		#may be set the onOff = 0
	fi
}

case $action in
	"add")
		addNew $mac $ip_addr $host_name;
		;;
	"old")
		if [ -e fname ] ; then
			#echo $fname >> /dhcp-script/echolog.log
			addNew $mac $ip_addr $host_name
		fi

		;;
	"del")
		
		#Just delete the dns record
		delAction $mac,$ip_addr;
		;;
	*)
		#echo "default:$1" >> /dhcp-script/echolog.log
		;;
esac



