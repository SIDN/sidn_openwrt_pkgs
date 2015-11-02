#!/bin/bash -e

# This scripts waits for an interface to come up with the given
# name and the given ip address
# It will wait for at most MAX_ATTEMPTS
                                       
ATTEMPTS=0                             
SLEEPTIME=1
MAX_ATTEMPTS=30
               
IFACE=$1       
IPADDR=$2
         
OK=1        
while [ $OK != 0 ]
do                
  ifconfig $IFACE | grep $IPADDR 2>/dev/null >/dev/null
  OK=$?                                                
  if [ $OK -ne 0 ]                                     
  then                                 
    sleep $SLEEPTIME            
    ATTEMPTS=$((ATTEMPTS+1))
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
    then                              
        OK=0                          
    fi                                
  fi                                  
done                                  
