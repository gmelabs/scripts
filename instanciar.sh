#!/usr/bin/env bash

#Revisamos las IPs Flotantes Disponibles y cargamos en variable la primera libre
export LB_FL_IP=`nova floating-ip-list | gawk -F'|' '/ None /{print$2}' |gawk '$1=$1' |head -1`

#Levantamos la instancia
nova boot --image Centos-GP-CI test --flavor 1


#comprobar el estado de la instancia y mediante un while aplicarle logica de que hasta que no este ACTIVE no incluye la LB_FL_IP
#Para prueba de concepto, aplicar un sleep

export ST_INST=`nova list | gawk -F'|' '/ test /{print$4}' |gawk '$1=$1'`

sleep 30


#Incluimos la IP Flotante
nova add-floating-ip test $LB_FL_IP


sleep 10


nova list

#listar el nova list (con la 2Âº IP) hasta tener la IP Flotante

export FL_IP=`nova list --name test --fields Networks | gawk -F'=' '/=/{print $2}' | gawk '{print $2}'`



##Una vez aparezca la IP Flotante (FL_IP), hacer un ping hasta que la instancia responda a IP y se pueda conectar por ssh

##Para prueba de concepto, aplicaremos un sleep con un tiempo estimado para la conexiÃ³n
sleep 450
 
##Envio a la instancia del .properties y el .sh que aprovisionara

sshpass -p 'temporal' scp aprovisionar.properties aprovisionar.sh root@$FL_IP:/tmp/

#Modifica el hostname de la instancia y ejecuta el script de aprovisionamiento

sshpass -p 'temporal' ssh root@$FL_IP "sed -i 's/localhost.localdomain localhost/test/g' /etc/hosts && sed -i 's/localhost.localdomain/test/g' /etc/sysconfig/network && hostname test && '/tmp/aprovisionar.sh'"
