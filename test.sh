#!/usr/bin/env bash

if [ -d /var/lib/tomcat6/webapps/testweb ];
then
        echo "aplicaci�n desplegada";
        exit 0;
else
        echo "aplicaci�n podrida";
        exit -1;
        
fi

