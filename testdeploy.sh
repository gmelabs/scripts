#!/usr/bin/env bash

IP_Flotante=`gawk        -F'=' '/^IP_Flotante=/{print $2}'        /home/openstack/fichip`


sshpass -p 'temporal' scp test.sh root@$IP_Flotante:/tmp/

sshpass -p 'temporal' ssh root@$IP_Flotante "'/tmp/test.sh'"

rm -f /home/openstack/fichip