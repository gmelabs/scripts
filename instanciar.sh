#!/usr/bin/env bash

OS_TENANT_NAME=`gawk        -F'=' '/^OS_TENANT_NAME=/{print $2}'        /home/openstack/instanciar.properties`
OS_USERNAME=`gawk        -F'=' '/^OS_USERNAME=/{print $2}'        /home/openstack/instanciar.properties`
OS_PASSWORD=`gawk        -F'=' '/^OS_PASSWORD=/{print $2}'        /home/openstack/instanciar.properties`
OS_AUTH_URL=`gawk        -F'=' '/^OS_AUTH_URL=/{print $2}'        /home/openstack/instanciar.properties`
IMAGEN=`gawk        -F'=' '/^IMAGEN=/{print $2}'        /home/openstack/instanciar.properties`
INST_NAME=`gawk        -F'=' '/^INST_NAME=/{print $2}'        /home/openstack/instanciar.properties`
FLAVOR=`gawk        -F'=' '/^FLAVOR=/{print $2}'        /home/openstack/instanciar.properties`

export OS_TENANT_NAME=$OS_TENANT_NAME
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_AUTH_URL=$OS_AUTH_URL

#Revisamos las IPs Flotantes Disponibles y cargamos en variable la primera libre
export LB_FL_IP=`nova floating-ip-list | gawk -F'|' '/ None /{print$2}' |gawk '$1=$1' |head -1`

#Levantamos la instancia

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}ARRANCAMOS LA INSTANCIA${NC}"

nova boot --image $IMAGEN $INST_NAME --flavor $FLAVOR


#comproba el estado de la instancia y mediante un while aplicarle logica de que hasta que no este ACTIVE no incluye la LB_FL_IP
#Para prueba de concepto, aplicar un sleep

#export ST_INST=`nova list | gawk -F'|' '/ test /{print$4}' |gawk '$1=$1'`

sleep 5


#Incluimos la IP Flotante
green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}INCLUIMOS LA IP FLOTANTE PARA ACCEDER DESDE EL EXTERIOR${NC}"

nova add-floating-ip $INST_NAME $LB_FL_IP


sleep 10

#Mostrar por pantalla las Instancias generadas
nova list --name $INST_NAME

#Exportar en una variable la IP Flotante asignada a la instancia
export FL_IP=`nova list --name $INST_NAME --fields Networks | gawk -F'=' '/=/{print $2}' | gawk '{print $2}'`

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}A LA ESPERA DE ESTABLECER CONEXIÓN CON LA INSTANCIA${NC}"

sleep 30
##Una vez aparezca la IP Flotante (FL_IP), hacer un ping hasta que la instancia responda a IP y se pueda conectar por ssh

##Para prueba de concepto, aplicaremos un sleep con un tiempo estimado para la conexiÃ³n
#sleep 450
while true; do ping -c1 $FL_IP > /dev/null && break; done

sleep 60

green='\e[0;32m'
NC='\e[0m' # No Color
echo -e "${green}COMIENZA EL PROCESO DE DESPLIEGUE${NC}"


##Envio a la instancia del .properties y el .sh que aprovisionara

sshpass -p 'temporal' scp aprovisionar.properties aprovisionar.sh root@$FL_IP:/tmp/

#Modifica el hostname de la instancia y ejecuta el script de aprovisionamiento

sshpass -p 'temporal' ssh root@$FL_IP "sed -i 's/localhost.localdomain localhost/test/g' /etc/hosts && sed -i 's/localhost.localdomain/test/g' /etc/sysconfig/network && hostname test && '/tmp/aprovisionar.sh'"
