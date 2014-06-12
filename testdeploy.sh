#!/usr/bin/env bash

sleep 60

IP_Flotante=`gawk        -F'=' '/^IP_Flotante=/{print $2}'        /home/openstack/fichip`


sshpass -p 'temporal' scp test.sh root@$IP_Flotante:/tmp/

sshpass -p 'temporal' ssh root@$IP_Flotante "'/tmp/test.sh'"

if [ $? -ne 0 ];
then exit 1;
fi

rm -f /home/openstack/fichip