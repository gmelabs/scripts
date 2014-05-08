#!/usr/bin/env bash

#################################################################################
# 
#  CONFIGURACIÓN, APROVISIONAMIENTO E INSTALACIÓN DE APLICACIÓN.
#  -------------------------------------------------------------
# 
# Nota: Necesitamos que desde 'remoto':
# 
# - Se copie este script en la instancia
# 
# - Se copie un fichero aprovisionar.properites con la configuración.
#   Al menos, deberá tener:
#   > ----------------------------
#   > PROXYUSER={usuario}
#   > PROXYPASSWD={contraseña}
#   > PROXYSERVER={servidor-proxy}
#   > PROXYPORT={puerto-proxy}
#   > ----------------------------
#   > GIT_CLONE_URL=https://github.com/gmelabs/puppet.git
#   > EXEC_ENV=BUILD (o LOCAL o {whatever}...)
#   > ----------------------------
#   > APP_GROUPID=acn.b.gmelabs  (groupId de la aplicación a instalar)
#   > APP_ARTIFACTID=testweb     (artifactId de la aplicación a instalar)
#   > APP_REPOSITORYID=snapshots (repositorio Nexus del que descargar artefacto)
#   > APP_FILETYPE=war           (tipo de artefacto -jar,war,ear-)
# 
# - Se ejecute este script
#################################################################################

# Se lee la configuracion del script
PROXYUSER=`gawk        -F'=' '/^PROXYUSER=/{print $2}'        /tmp/aprovisionar.properties`
PROXYPASSWD=`gawk      -F'=' '/^PROXYPASSWD=/{print $2}'      /tmp/aprovisionar.properties`
PROXYSERVER=`gawk      -F'=' '/^PROXYSERVER=/{print $2}'      /tmp/aprovisionar.properties`
PROXYPORT=`gawk        -F'=' '/^PROXYPORT=/{print $2}'        /tmp/aprovisionar.properties`
GIT_CLONE_URL=`gawk    -F'=' '/^GIT_CLONE_URL=/{print $2}'    /tmp/aprovisionar.properties`
EXEC_ENV=`gawk         -F'=' '/^EXEC_ENV=/{print $2}'         /tmp/aprovisionar.properties`
APP_GROUPID=`gawk      -F'=' '/^APP_GROUPID=/{print $2}'      /tmp/aprovisionar.properties`
APP_ARTIFACTID=`gawk   -F'=' '/^APP_ARTIFACTID=/{print $2}'   /tmp/aprovisionar.properties`
APP_REPOSITORYID=`gawk -F'=' '/^APP_REPOSITORYID=/{print $2}' /tmp/aprovisionar.properties`
APP_FILETYPE=`gawk     -F'=' '/^APP_FILETYPE=/{print $2}'     /tmp/aprovisionar.properties`

# Se adapta la instancia para que pueda conectar a Internet desde red con proxy
export http_proxy=http://$PROXYUSER:$PROXYPASSWD@$PROXYSERVER:$PROXYPORT/
export https_proxy=https://$PROXYUSER:$PROXYPASSWD@$PROXYSERVER:$PROXYPORT/


# ------------------------------------------------------------------------------------------
# Se instala Git y se descarga la configuracion desde github
yum -y install git
mkdir config && cd config
git clone ${GIT_CLONE_URL} puppet
cd puppet
# Se selecciona la configuracion (*.properties) apropiada al entorno de ejecucion del script
rename \{${EXEC_ENV}\}.properties .properties modules/*/files/*\{${EXEC_ENV}\}.properties

# Se aplica la configuracion
puppet apply --modulepath=modules manifests/site.pp
# -------------------------------------------------------------------------------------------

# Se adapta la instancia para que pueda eliminar proxy y pueda llegar a NEXUS
export http_proxy=
export https_proxy=
# -------------------------------------------------------------------------------------------

# Se instala la última versión de la aplicacion
NEXUS_URL=`gawk  -F'=' '/^NEXUS_URL=/{print $2}'  /tmp/nexus.properties | sed 's/\r//g'`
NEXUS_USER=`gawk -F'=' '/^NEXUS_USER=/{print $2}' /tmp/nexus.properties | sed 's/\r//g'`
NEXUS_PASS=`gawk -F'=' '/^NEXUS_PASS=/{print $2}' /tmp/nexus.properties | sed 's/\r//g'`

FIND_PATH=`curl -X GET -u $NEXUS_USER:$NEXUS_PASS -H "Accept: application/xml" "http://${NEXUS_URL}/nexus/service/local/artifact/maven/resolve?g=${APP_GROUPID}&a=${APP_ARTIFACTID}&v=LATEST&r=${APP_REPOSITORYID}&p=${APP_FILETYPE}" 2>/dev/null | gawk -F'[<>]' '/\<repositoryPath\>/{ print $3 }'`

# Download it to the Tomcat Webapps directory
cd /var/lib/tomcat6/webapps && wget -O ${APP_ARTIFACTID}.war "http://${NEXUS_URL}/nexus/service/local/repositories/${APP_REPOSITORYID}/content/${FIND_PATH}" 2>/dev/null

# Put a file indicating the SNAPSHOT version deployed in Tomcat
ARTIFACT_NAME=${FIND_PATH%%*/}
ARTIFACT_NAME=${ARTIFACT_NAME%.*}
echo ${ARTIFACT_NAME} > /tmp/deployed_${APP_ARTIFACTID}_version
# -------------------------------------------------------------------------------------------
# Reinicio del tomcat6
service tomcat6 stop
service tomcat6 start
