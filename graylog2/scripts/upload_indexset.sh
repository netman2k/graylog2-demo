#!/bin/bash
#
# This can create an index set
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

# Upload index set
output="/tmp/result_$$"
curl -s -i -o $output -s -u ${GRAYLOG_USER}:${GRAYLOG_PASSWORD} -X POST \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' $GRAYLOG_HOST/api/system/indices/index_sets -d @${FILE}

if [ $(egrep -c "HTTP/1.1 200 OK" $output) -eq "1" ];then
  echo "Applied contentpack" 
else
    echo "Unable to upload index set you requested." 1>&2
fi
