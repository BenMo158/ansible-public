#!/bin/bash
### BEGIN INIT INFO
# Provides:          lvs-realserver
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

. /etc/rc.d/init.d/functions

{% if lb_kind == "NAT" %}
# route table: /etc/iproute2/rt_tables
LAN_IP={{ lvs_lan_address }}
LAN_GW={{ lan_gateway }}
LAN_SCOPE="{{ lvs_lan_address | regex_replace('(^\d+\.\d+\.\d+)\.\d+$','\\1.0') }}/24"
ROUTE_TABLE=lvs
LAN_INT={{ lan_interface }}

# add route to lvs
startRealserver() {
        [ -n "`grep lvs /etc/iproute2/rt_tables`" ] || echo "50 lvs" >> /etc/iproute2/rt_tables
        [ -n "`ip addr show $LAN_INT | grep -o $LAN_IP`" ] || ip addr add $LAN_IP/24 brd + dev $LAN_INT
        [ -z "`ip rule list | grep -o $LAN_IP`" ] || ip rule del from $LAN_IP
        ip route flush table $ROUTE_TABLE >/dev/null 2>&1
        ip route add table $ROUTE_TABLE $LAN_SCOPE dev $LAN_INT:$ROUTE_TABLE proto kernel scope link src $LAN_IP >/dev/null 2>&1
        ip route add table $ROUTE_TABLE default via $LAN_GW dev $LAN_INT:$ROUTE_TABLE src $LAN_IP >/dev/null 2>&1
        ip rule add from $LAN_IP table $ROUTE_TABLE prio 500 >/dev/null 2>&1
		echo -e "\n\e[0;33mRealServer start...\e[0m\n"
}

# del route
stopRealserver() {
        [ -z "`grep lvs /etc/iproute2/rt_tables`" ] || sed -i "s/50 lvs//" /etc/iproute2/rt_tables
        [ -z "`ip addr show $LAN_INT | grep -o $LAN_IP`" ] || ip addr del $LAN_IP/24 brd + dev $LAN_INT
        [ -z "`ip rule list | grep -o $LAN_IP`" ] || ip rule del from $LAN_IP
		echo -e "\n\e[0;31mRealServer stop...\e[0m\n"
}

# show status
realStatus() {
        showVip=`ip addr show $LAN_INT | grep -o $LAN_IP`
        showRule=`ip rule list  | grep lvs | head -n 1`
        showTable=`grep "lvs" /etc/iproute2/rt_tables`
        showRoute=`ip route show | grep $LAN_IP`
		if [ ! "$showVip" -o ! "$showRule" -o ! "$showTable" -o ! "$showRoute" ];then
                echo -e "\n\e[031mRealServer is not running...\e[0m"
        else
                echo -e "\n\e[032mRealServer is running...\e[0m"
        fi
        echo -e "
LVS LB_kind:\t\t\e[0;33mNAT\e[0m
RealServer VIP:\t\t\e[0;33m$showVip\e[0m
RealServer Table:\t\e[0;33m$showTable\e[0m
RealServer Rule:\t\e[0;33m$showRule\e[0m
RealServer Route:\t\e[0;33m$showRoute\e[0m\n"
}
case "$1" in
start)
        startRealserver
        ;;
stop)
        stopRealserver
        ;;
status)
        realStatus
        ;;
*)
        echo -e "\n\e[0;31mError:\e[0m Usage: $0 {start|status|stop}\n"
        exit 1
        ;;
esac
exit 0
{% else %}
VIP={{ vip_address }}

startRealserver() {
		#ifconfig lo:0 $VIP netmask 255.255.255.255 broadcast $VIP
		ip addr add $VIP/32 broadcast $VIP dev lo
		/sbin/route add -host $VIP dev lo
		echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
		echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
		echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
		echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
		sysctl -p >/dev/null 2>&1
		echo -e "\n\e[0;33mRealServer Start...\e[0m\n"
}
	
stopRealserver() {
		#ifconfig lo:0 down
		route del $VIP >/dev/null 2>&1
		ip addr del $VIP/32 broadcast $VIP dev lo
		echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
		echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
		echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
		echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
		echo -e "\n\e[0;31mRealServer Stop...\e[0m\n"
}

realStatus() {
		# Status of LVS-DR real server.
        showVip=`ip addr show lo | grep -Po "(?<=inet )$VIP"`
        showRoute=`ip route show | grep $VIP`
        if [ ! "$showVip" -o ! "$showRoute" ];then
            echo -e "\n\e[0;32mRealServer is not running...\e[0m"
        else
            echo -e "\n\e[0;33mRealServer is Running...\e[0m"
        fi
		                echo -e "
LVS lb_kind:\t\t\e[0;33mDR\e[0m
RealServer Vip:\t\t\e[0;33m$showVip\e[0m
RealServer Route:\t\e[0;33m$showRoute\e[0m\n
ARP_Response:
\t\e[0;33m/proc/sys/net/ipv4/conf/lo/arp_ignore = `cat /proc/sys/net/ipv4/conf/lo/arp_ignore`\e[0m
\t\e[0;33m/proc/sys/net/ipv4/conf/lo/arp_announce = `cat /proc/sys/net/ipv4/conf/lo/arp_announce`\e[0m
\t\e[0;33m/proc/sys/net/ipv4/conf/all/arp_ignore = `cat /proc/sys/net/ipv4/conf/all/arp_ignore`\e[0m
\t\e[0;33m/proc/sys/net/ipv4/conf/all/arp_announce = `cat /proc/sys/net/ipv4/conf/all/arp_announce`\e[0m
"
}

case "$1" in
start)
		startRealserver
		;;
stop)
		stopRealserver
		;;
status)
		realStatus
		;;
*)
        # Invalid entry.
        echo -e "\n\e[0;31mERROR:\e[0m Usage: $0 {start|status|stop}\n"
        exit 1
		;;
esac
exit 0
{% endif %}
