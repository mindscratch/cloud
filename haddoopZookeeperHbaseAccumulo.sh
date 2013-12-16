#!/bin/bash
#NOTE: your localhost line in /etc/hosts must be 127.0.0.1

echo "Acquiring Java and curl from Ubuntu repos..."
sudo apt-get -q update
sudo apt-get -q install curl openjdk-6-jdk -y

echo "Setting up environment..."
cat >> /home/ubuntu/.bashrc <<EOF
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
export HADOOP_HOME=/home/ubuntu/hadoop-0.20.2-cdh3u3
export ZOOKEEPER_HOME=/home/ubuntu/zookeeper-3.3.4-cdh3u3
export PATH=$PATH:/home/ubuntu/hadoop-0.20.2-cdh3u3/bin:/home/ubuntu/accumulo-1.4.3/bin

EOF

export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
export HADOOP_HOME=/home/ubuntu/hadoop-0.20.2-cdh3u3
export ZOOKEEPER_HOME=/home/ubuntu/zookeeper-3.3.4-cdh3u3
export PATH=$PATH:/home/ubuntu/hadoop-0.20.2-cdh3u3/bin:/home/ubuntu/accumulo-1.4.3/bin

echo "Acquiring archives..."
cd /home/ubuntu
echo "- Hadoop"
curl -O -L -s http://archive.cloudera.com/cdh/3/hadoop-0.20.2-cdh3u3.tar.gz
echo "- Zookeeper"
curl -O -L -s http://archive.cloudera.com/cdh/3/zookeeper-3.3.4-cdh3u3.tar.gz
echo "- Accumulo"
curl -O -L -s http://apache.mesi.com.ar/accumulo/1.4.3/accumulo-1.4.3-dist.tar.gz
#echo "- HBase"
#curl -O -L -s http://psg.mtu.edu/pub/apache/hbase/stable/hbase-0.94.8.tar.gz

echo "Extracting archives..."
tar -zxf hadoop-0.20.2-cdh3u3.tar.gz
tar -zxf zookeeper-3.3.4-cdh3u3.tar.gz
tar -zxf accumulo-1.4.3-dist.tar.gz
#tar -zxf hbase-0.94.8.tar.gz

echo "Configuring Hadoop..."
ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -N ''
cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
ssh-keyscan localhost >> /home/ubuntu/.ssh/known_hosts
cat >> hadoop-0.20.2-cdh3u3/conf/hadoop-env.sh <<EOF
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
EOF
cat > hadoop-0.20.2-cdh3u3/conf/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:8020</value>
  </property>
  <property>
    <name>mapred.child.java.opts</name>
    <value>-Xmx512m</value>
  </property>
  <property>
    <name>analyzer.class</name>
    <value>org.apache.lucene.analysis.WhitespaceAnalyzer</value>
  </property>
  <property>
    <name>hadoop.proxyuser.ubuntu.hosts</name>
    <value>*</value>
  </property>

  <property>
    <name>hadoop.proxyuser.ubuntu.groups</name>
    <value>*</value>
  </property>
</configuration>

EOF
cat > hadoop-0.20.2-cdh3u3/conf/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
   <property>
       <name>mapred.job.tracker</name>
       <value>localhost:8021</value>
   </property>
   <property>
       <name>mapred.child.java.opts</name>
       <value>-Xmx1024m</value>
   </property>
</configuration>

EOF
hadoop-0.20.2-cdh3u3/bin/hadoop namenode -format

echo "Starting Hadoop..."
hadoop-0.20.2-cdh3u3/bin/start-all.sh

echo "Configuring Zookeeper..."
sudo mkdir /var/zookeeper
sudo chown ubuntu:ubuntu /var/zookeeper

echo "Running Zookeeper..."
zookeeper-3.3.4-cdh3u3/bin/zkServer.sh start

echo "Configuring Accumulo..."
cp accumulo-1.4.3/conf/examples/1GB/standalone/* accumulo-1.4.3/conf/
sed -i 's/>secret</>password</' accumulo-1.4.3/conf/accumulo-site.xml
accumulo-1.4.3/bin/accumulo init --clear-instance-name <<EOF
accumulo
password
password
EOF

#NOTE: Uncomment these lines to start Accumulo by default
#echo "Starting Accumulo..."
#accumulo-1.4.3/bin/start-all.sh

#echo "Configuring Hbase"
#cat > hbase-0.94.8/conf/hbase-site.xml <<EOF
#<?xml version="1.0"?>
#<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
#<configuration>
#<property>
#<name>hbase.rootdir</name>
#<value>file:///home/ubuntu/hbase</value>
#</property>
#<property>
#<name>hbase.zookeeper.property.dataDir</name>
#<value>/var/zookeeper</value>
#</property>
#<property>
#<name>hbase.zookeeper.quorum</name>
#<value>localhost</value>
#  </property>
#  <property>
#   <name>hbase.zookeeper.property.clientPort</name>
#   <value>2181</value>
#  </property>
#  <property>
#    <name>hbase.cluster.distributed</name>
#    <value>true</value>
#</property>
#</configuration>
#
#EOF


echo "Moving necessary jar files from Hadoop to HDFS..."
#mv hbase-0.94.8/lib/hadoop-core-1.0.4.jar /home/ubuntu/
cp hadoop-0.20.2-cdh3u3/hadoop-core-0.20.2-cdh3u3.jar hbase-0.94.8/lib/hadoop-core-0.20.2.jar
cp hadoop-0.20.2-cdh3u3/lib/guava-r09-jarjar.jar hbase-0.94.8/lib/

#echo "Modifying hbase-0.94.8/conf/hbase-env.sh to not launch bundled Zookeeper instance..."
#echo "export HBASE_MANAGES_ZK=false
#export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/" >>  hbase-0.94.8/conf/hbase-env.sh

#echo "Starting Hbase..."
#./hbase-0.94.8/bin/start-hbase.sh <<EOF
#yes
#EOF

echo 'Done!'
