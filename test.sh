#!/usr/bin/env bash

if [ -d /var/lib/tomcat6/webapps/testweb ];
then
        echo "aplicación desplegada";
        exit 0;
else
        echo "aplicación podrida";
        exit -1;
        
fi

