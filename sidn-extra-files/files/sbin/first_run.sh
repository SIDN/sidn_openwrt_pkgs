#!/bin/sh

CHECK_FILE="/etc/first_run.done"

if [ -f "$CHECK_FILE" ]; then
    echo "first run already done, delete $CHECK_FILE to run setup again"
else
    sleep 10
    echo "output of ifconfig:" >> /tmp/wtf
    /sbin/ifconfig >> /tmp/wtf
    echo $? >> /tmp/wtf
    echo "doing first run setup"
    HWADDR=`/sbin/get_hwaddr.sh`
    IP4ADDR=`/sbin/get_ip4addr.sh`
    IP6ADDR=`/sbin/get_ip6addr.sh`
    
    # Replace addresses in unbound.conf file
    cat /etc/unbound/unbound.conf.in | sed "s/XIP4ADDRX/${IP4ADDR}/" | sed "s/XIP6ADDRX/${IP6ADDR}/" > /etc/unbound/unbound.conf
    # generate unbound_control key and cert
    /usr/sbin/unbound-control-setup
    cat /etc/config/wireless.in | sed "s/XHWADDRX/${HWADDR}/" > /etc/config/wireless

    # Replace dnsmasq conf
    cp /etc/config/dhcp.in /etc/config/dhcp

    # Store results
    touch "$CHECK_FILE"
    echo "LAN IPv4: ${IP4ADDR}" >> "$CHECK_FILE"
    echo "LAN IPv6: ${IP6ADDR}" >> "$CHECK_FILE"
    echo "SSID:     SIDN-GL-Inet-${HWADDR}" >> "$CHECK_FILE"
    /etc/init.d/network restart
    
    # we run before dnsmasq and unbound so restarting those is not necessare
fi
