#!/bin/sh
# logstash-provision.sh

# Set up timezone correctly
echo "America/New_York" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

# Copy in custom /etc/hosts file
echo "Copying custom /etc/hosts file"
sudo cp /vagrant_data/etc_hosts /etc/hosts
sudo chmod 644 /etc/hosts

# Set hostname
echo "setting hostname to smoker.example.com"
sudo /bin/hostname smoker.example.com

# Update package isting
sudo apt-get -y update

# Install java
sudo apt-get -y install java7-runtime-headless

# Install curl
sudo apt-get -y install curl

# Install emacs
sudo apt-get -y install emacs23

# Install unzip
sudo apt-get -y install unzip

# apt-get -f
sudo apt-get -y -f install

# Resolve timezone issue
#sudo dpkg-reconfigure tzdata
#CURRENT_DATE=`date`

#sudo date -s "$CURRENT_DATE"


# Configure IP address, hostname
# Likely done in Vagrantfile
# hostname: smoker.example.com
# IP address: 10.0.0.1

# Make configuration directories
sudo mkdir -p /opt/logstash
sudo mkdir -p /etc/logstash
sudo mkdir -p /var/log/logstash


cd /opt/logstash
# Download logstash
if [ ! -s logstash-1.1.9-monolithic.jar ]
then
    echo "Downloading logstash"
    sudo curl -s https://logstash.objects.dreamhost.com/release/logstash-1.1.9-monolithic.jar -o logstash-1.1.9-monolithic.jar
else
    echo "Logstash already present"
fi

# Create symbolic link for logstash-central-init fil

sudo ln -s  /opt/logstash/logstash-1.1.9-monolithic.jar  /opt/logstash/logstash.jar


# cd to /tmp
cd

# Install elasticsearch
if [ ! -s elasticsearch-0.20.2.deb ]
then
    echo "Downloading elasticsearch"
    sudo curl -s  https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.deb  -o elasticsearch-0.20.2.deb
else
    echo "Elasticsearch already present"
fi

# Export our Java
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386/

sudo dpkg -i elasticsearch-0.20.2.deb

# Copy in our custom elasticsearch.yml file
echo "Copying custom elasticsearch.yml"
sudo cp /vagrant_data/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

# Restart elasticsearch
sudo /etc/init.d/elasticsearch restart


# Add elasticsearch mapping

#echo "Printing out network configuration"
#ifconfig -a


#echo "sleeping 15 seconds"
#sleep 30
#echo "Looking to to see if port 9200 available"
#sudo lsof -i:9200

# Wait until the elasticsearch PID file exists
echo "Now waiting 10 seconds for elasticsearch PID to appear"
COUNT=0
while [ "$COUNT" -lt 10  ]
do
    echo  ". \c"
    #sudo curl -XGET 'http://localhost:9200/_status'
    sleep 1
    COUNT=`expr $COUNT + 1`
    #echo "$COUNT"
done

echo "Now attempting to upload elasticsearch mapping for logstash index"
#sudo curl -s -XPUT http://10.0.0.2:9200/_template/logstash_per_index -d '{
sudo curl -s -XPUT http://127.0.0.1:9200/_template/logstash_per_index -d '{
    "template": "logstash*",
    "settings": {
        "index.query.default_field": "@message",
        "index.cache.field.type": "soft",
        "index.store.compress.stored": true
    },
    "mappings": {
        "_default_": {
            "_all": {
                "enabled": false
            },
            "properties": {
                "@message": {
                    "type": "string",
                    "index": "analyzed"
                },
                "@source": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@source_host": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@source_path": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@tags": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@timestamp": {
                    "type": "date",
                    "index": "not_analyzed"
                },
                "@type": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        }
    }
}
'


# Check our elasticsearch template
#echo "Checking elasticsearch template configuration"
#sudo curl 'http://127.0.0.1:9200/_all/_mapping?pretty=true'

# Install redis message broker
sudo apt-get -y install redis-server

# Change sysctl parameter for redis
#   This avoids this warning: 
## WARNING overcommit_memory is set to 0! Background save may fail 
## under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' 
## to /etc/sysctl.conf and 
## then reboot or run the command 'sysctl vm.overcommit_memory=1' for this 
##  to take effect.
sudo sysctl vm.overcommit_memory=1

# Copy in custom redis.conf file
echo "Copying custom redis.conf file"
sudo cp /vagrant_data/redis.conf /etc/redis/redis.conf

# Start redis interface
echo "Restarting redis"
sudo /etc/init.d/redis-server restart


# Create logstash-central logfile
sudo touch /var/log/logstash/central.log

# Copy in central.conf fil

if [ ! -s /etc/logstash/central.conf ]
then
    sudo cp /vagrant_data/central.conf /etc/logstash/central.conf
else
    echo "central.conf file already exists"
fi


# Add in logstash service configuration
if [ ! -s /etc/init.d/logstash-central ]
then
    echo "Copying logstash-central init script"
    sudo cp /vagrant_data/logstash-central-orig.init /etc/init.d/logstash-central
    sudo chmod +x /etc/init.d/logstash-central
else
    echo "/etc/init.d/logstash-central already exists"
fi


sudo chown root:root /etc/init.d/logstash-central

echo "Starting logstash-central"
sudo /etc/init.d/logstash-central restart

echo "Checking logstash-central status"
sudo /etc/init.d/logstash-central status

echo "Starting web backend"
sudo nohup /usr/bin/java -jar /opt/logstash/logstash.jar web --backend elasticsearch://127.0.0.1/ >/dev/null 2>/dev/null &

