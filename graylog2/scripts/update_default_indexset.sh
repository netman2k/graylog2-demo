#!/bin/bash
#
# This can change default indexset configuration
# You could change these default index set values with environment variables
#
# Please refer to this page
# - http://docs.graylog.org/en/2.4/pages/configuration/index_model.html
#
# Author: DaeHyung Lee<daehyung@gmail.com>
#

[ -z $GRAYLOG_HOST ] && GRAYLOG_HOST="http://localhost:9000"
[ -z $GRAYLOG_USER ] && GRAYLOG_USER="admin"
[ -z $GRAYLOG_PASSWORD ] && GRAYLOG_PASSWORD="admin" 

# Rotation strategy
# * message_count:  Message count based
# * size:           Index size based
# * time:           Time based
[ -z $GRAYLOG_ROTATION_STRATEGY ] && GRAYLOG_ROTATION_STRATEGY="message_count"
[ -z $GRAYLOG_ROTATION_MAX_DOCS_PER_INDEX ] && GRAYLOG_ROTATION_MAX_DOCS_PER_INDEX="20000000"
[ -z $GRAYLOG_ROTATION_MAX_SIZE_PER_INDEX ] && GRAYLOG_ROTATION_MAX_SIZE_PER_INDEX="1073741824"
[ -z $GRAYLOG_ROTATION_TIME_PERIOD ] && GRAYLOG_ROTATION_TIME_PERIOD="P1D"

[ -z $GRAYLOG_ELASTICSEARCH_INDEX_PREFIX ] && GRAYLOG_ELASTICSEARCH_INDEX_PREFIX="graylog"
[ -z $GRAYLOG_ELASTICSEARCH_SHARDS ] && GRAYLOG_ELASTICSEARCH_SHARDS=4
[ -z $GRAYLOG_ELASTICSEARCH_REPLICAS ] && GRAYLOG_ELASTICSEARCH_REPLICAS=0

# Retention strategy
# * delete:  Delete Index
# * close:   Close Index
# * none:    Do nothing
[ -z $GRAYLOG_RETENTION_STRATEGY ] && GRAYLOG_RETENTION_STRATEGY="delete"
[ -z $GRAYLOG_RETENTION_MAX_NUM_OF_INDICES ] && GRAYLOG_RETENTION_MAX_NUM_OF_INDICES="20"

# Set whether run rebuilding after change
# * 0: not run
# * 1: run
[ -z $GRAYLOG_REBUILD_INDEX ] && GRAYLOG_REBUILD_INDEX=1

# requirement check
which jq > /dev/null
[ $? -eq 1 ] && { echo "You need to install jq first to use this script" 1>&2; exit 1; }

# Retrieve id of the default index set
id=$(curl -s -u $GRAYLOG_USER:$GRAYLOG_PASSWORD -H 'Accept: application/json' \
  $GRAYLOG_HOST/api/system/indices/index_sets | \
  jq -r '.index_sets[] | select(.title == "Default index set") | .id')

[ $? -eq 1 ] && { echo "[ERROR] Error occurred" 1>&2; exit 1; }

# Decide rotation stategy
if [ "${GRAYLOG_ROTATION_STRATEGY}" = "message_count" ];then
  rotation_strategy_class="org.graylog2.indexer.rotation.strategies.MessageCountRotationStrategy"
  rotation_option="\"max_docs_per_index\": ${GRAYLOG_ROTATION_MAX_DOCS_PER_INDEX}"
elif [ "${GRAYLOG_ROTATION_STRATEGY}" = "size" ];then
  rotation_strategy_class="org.graylog2.indexer.rotation.strategies.SizeBasedRotationStrategy"
  rotation_option="\"max_size\": ${GRAYLOG_ROTATION_MAX_SIZE_PER_INDEX}"
elif [ "${GRAYLOG_ROTATION_STRATEGY}" = "time" ];then
  rotation_strategy_class="org.graylog2.indexer.rotation.strategies.TimeBasedRotationStrategy"
  rotation_option="\"rotation_period\": ${GRAYLOG_ROTATION_TIME_PERIOD}"
else
  echo "[ERROR] Wrong rotation strategy" 1>&2
  exit 1
fi

# Decide retention stategy
if [ "${GRAYLOG_RETENTION_STRATEGY}" = "delete" ];then
  retention_strategy_class="org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy"
  retention_option="\"max_number_of_indices\": ${GRAYLOG_RETENTION_MAX_NUM_OF_INDICES}"
elif [ "${GRAYLOG_RETENTION_STRATEGY}" = "close" ];then
  retention_strategy_class="org.graylog2.indexer.retention.strategies.ClosingRetentionStrategy"
  retention_option="\"max_number_of_indices\": ${GRAYLOG_RETENTION_MAX_NUM_OF_INDICES}"
elif [ "${GRAYLOG_RETENTION_STRATEGY}" = "none" ];then
  retention_strategy_class="org.graylog2.indexer.retention.strategies.NoopRetentionStrategy"
  retention_option="\"max_number_of_indices\": 2147483647"
else
  echo "[ERROR] Wrong retention strategy" 1>&2
  exit 1
fi

# Generate PAYLOAD
cat <<EOF > ./data.json
{
  "id": "${id}",
  "title": "Default index set",
  "description": "The Graylog default index set",
  "index_prefix": "${GRAYLOG_ELASTICSEARCH_INDEX_PREFIX}",
  "shards": ${GRAYLOG_ELASTICSEARCH_SHARDS},
  "replicas": ${GRAYLOG_ELASTICSEARCH_REPLICAS},
  "rotation_strategy_class": "${rotation_strategy_class}",
  "rotation_strategy": {
    "type": "${rotation_strategy_class}Config",
    ${rotation_option}
  },
  "retention_strategy_class": "${retention_strategy_class}",
  "retention_strategy": {
    "type": "${retention_strategy_class}Config",
    ${retention_option}
  },
  "index_analyzer": "standard",
  "index_optimization_max_num_segments": 1,
  "index_optimization_disabled": false,
  "writable": true,
  "default": true
}
EOF

# Request updating
result=$(curl -s -u $GRAYLOG_USER:$GRAYLOG_PASSWORD -X PUT -H 'Content-Type: application/json' $GRAYLOG_HOST/api/system/indices/index_sets/$id -d @./data.json)

# Print result
echo $result | jq .

echo "If you want to clean your previous indices on your Elasticsearch than run this"
echo "\$ curl -XDELETE 'http://<ELATICSEARCH>:9200/_all'"

echo "You might need to rebuild your indices, after change"
echo "\$ curl -XPOST $GRAYLOG_HOST/api/system/indices/ranges/rebuild"


