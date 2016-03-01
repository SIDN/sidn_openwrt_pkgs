#!/bin/sh -e

# This scripts waits for an interface to come up with the given
# name and the given ip address
# It will wait for at most MAX_ATTEMPTS

ATTEMPTS=0
SLEEPTIME=1
MAX_ATTEMPTS=30

IFACE=$1
IPADDR=$2

OK=1
while [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]            
do
  if ifconfig ${IFACE} | grep -q ${IPADDR}; then  
    echo "if is up"
    exit                                        
  fi                                     
  echo "if is not up, waiting ($ATTEMPTS)"  
  sleep $SLEEPTIME                       
  ATTEMPTS=$((ATTEMPTS+1))               
done
