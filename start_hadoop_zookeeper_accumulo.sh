#!/bin/env bash

echo "starting hadoop"
hadoop-0.20.2-cdh3u3/bin/start-all.sh

echo "starting zookeeper"
zookeeper-3.3.4-cdh3u3/bin/zkServer.sh start

"echo starting accumulo"
accumulo-1.4.3/bin/accumulo init --clear-instance-name <<EOF
accumulo
password
password
EOF
