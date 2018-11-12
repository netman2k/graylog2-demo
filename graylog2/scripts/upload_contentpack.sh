#!/bin/bash
#
# This can upload contentpack content
#
# Please refer to this page
# - http://docs.graylog.org/en/2.4/pages/configuration/index_model.html
#
# Author: DaeHyung Lee<daehyung@gmail.com>
#
[ $# -eq 0 ] && { echo "Usage $0 <File to upload>"; exit 1; }
FILE=$1

[ -z $GRAYLOG_HOST ] && GRAYLOG_HOST="http://localhost:9000"
[ -z $GRAYLOG_USER ] && GRAYLOG_USER="admin"
[ -z $GRAYLOG_PASSWORD ] && GRAYLOG_PASSWORD="admin" 

# requirement check
which jq > /dev/null
[ $? -eq 1 ] && { echo "You need to install jq first to use this script" 1>&2; exit 1; }

# Upload contentpack
output="/tmp/result_$$"
curl -s -i -o $output -s -u ${GRAYLOG_USER}:${GRAYLOG_PASSWORD} -X POST -H 'Content-Type: application/json' $GRAYLOG_HOST/api/system/bundles -d @${FILE}

if [ $(egrep -c "HTTP/1.1 201 Created" $output) -eq "1" ];then
  # Get bundle ID from response header
  bundle_id=$(cat $output | grep "Location:" | awk '{ split($2,n,"/");print n[length(n)] }')
   
  # Apply it
  if [ $bundle_id ];then
    # Note that I removed carriage return character from the bundle_id to fix command
    res_code=$(curl -w "%{http_code}\n" -s -u ${GRAYLOG_USER}:${GRAYLOG_PASSWORD} -X POST -H 'Content-Type: application/json' $GRAYLOG_HOST/api/system/bundles/${bundle_id//}/apply)

    # Error code might be 404 or 500
    if [ ${res_code} = "204" ];then
      echo "Applied contentpack" 
    else
      echo "Failed applying contentpack" 1>&2
    fi

  else
    echo "Could not found any bundle ID from the response header" 1>&2
  fi
else
    echo "Unable to upload contentpack you requested." 1>&2
fi

