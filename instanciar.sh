#!/usr/bin/env bash

export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=openstack
export OS_AUTH_URL="http://20.1.34.123:5000/v2.0/"

#Revisamos las IPs Flotantes Disponibles y cargamos en variable la primera libre
export LB_FL_IP=`nova floating-ip-list | gawk -F'|' '/ None /{print$2}' |gawk '$1=$1' |head -1`

#Levantamos la instancia

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}ARRANCAMOS LA INSTANCIA${NC}"

nova boot --image Centos-GP-CI test --flavor 5b021ae4-2ba7-4979-9bc3-56d0c5d27b58


#comprobar el estado de la instancia y mediante un while aplicarle logica de que hasta que no este ACTIVE no incluye la LB_FL_IP
#Para prueba de concepto, aplicar un sleep

#export ST_INST=`nova list | gawk -F'|' '/ test /{print$4}' |gawk '$1=$1'`

sleep 5


#Incluimos la IP Flotante
green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}INCLUIMOS LA IP FLOTANTE PARA ACCEDER DESDE EL EXTERIOR${NC}"

nova add-floating-ip test $LB_FL_IP


sleep 10

#Mostrar por pantalla las Instancias generadas
nova list --name test

#Exportar en una variable la IP Flotante asignada a la instancia
export FL_IP=`nova list --name test --fields Networks | gawk -F'=' '/=/{print $2}' | gawk '{print $2}'`

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}A LA ESPERA DE ESTABLECER CONEXIÓN CON LA INSTANCIA${NC}"

sleep 30
##Una vez aparezca la IP Flotante (FL_IP), hacer un ping hasta que la instancia responda a IP y se pueda conectar por ssh

##Para prueba de concepto, aplicaremos un sleep con un tiempo estimado para la conexiÃ³n
#sleep 450
while true; do ping -c1 $FL_IP > /dev/null && break; done

sleep 35

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}COMIENZA EL PROCESO DE DESPLIEGUE${NC}"


##Envio a la instancia del .properties y el .sh que aprovisionara

sshpass -p 'temporal' scp aprovisionar.properties aprovisionar.sh root@$FL_IP:/tmp/

#Modifica el hostname de la instancia y ejecuta el script de aprovisionamiento

sshpass -p 'temporal' ssh root@$FL_IP "sed -i 's/localhost.localdomain localhost/test/g' /etc/hosts && sed -i 's/localhost.localdomain/test/g' /etc/sysconfig/network && hostname test && '/tmp/aprovisionar.sh'"
