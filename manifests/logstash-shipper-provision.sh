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
echo "setting hostname to maurice.example.com"
sudo /bin/hostname maurice.example.com

# Update package isting
sudo apt-get -y update

# Install java
sudo apt-get -y install java7-runtime-headless

# Install curl
sudo apt-get -y install curl

# Install apache
sudo apt-get -y install apache2-mpm-prefork

# Install mailutils
#sudo apt-get -y install mailutils

# Install Tomcat6
sudo apt-get -y install tomcat6

# Install stunnel
sudo apt-get -y install stunnel

# Install postfix mail server
#sudo apt-get -y install postfix
# Attempt unattended postfix install
DEBIAN_FRONTEND=noninteractive apt-get -y install postfix

# Install mailutils
sudo apt-get -y  install mailutils

# Install emacs
sudo apt-get -y install emacs23

# Install unzip
sudo apt-get -y install unzip

# apt-get -f
sudo apt-get -y -f install

# Copy in Apache2 configfiles
echo "Copying apache2.conf"
sudo cp /vagrant_data/shipper.apache2.conf /etc/apache2/apache2.conf
echo "Copying site enabled with logstash format"
sudo cp /vagrant_data/sites-enabled_000-default /etc/apache2/sites-enabled/000-default
echo "Restarting apache2"
sudo service apache2 restart

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

# Create symbolic link for logstash-shipper-init fil

sudo ln -s  /opt/logstash/logstash-1.1.9-monolithic.jar  /opt/logstash/logstash.jar


# cd to /tmp
cd

# Configure rsyslog.conf
echo "Copying rsyslog.conf"
sudo cp /vagrant_data/rsyslog.conf /etc/rsyslog.conf

echo "Restarting rsyslog"
sudo service rsyslog restart


# Create the logstash patterns directory, if needed

if [ ! -d /etc/logstash/patterns ]
then
    sudo mkdir -p /etc/logstash/patterns
fi

echo "Copying logstash patterns to patterns directory"
sudo cp /vagrant_data/postfix /etc/logstash/patterns/postfix

# Remove temp editor files, or they will get consumed by LogStash!
sudo rm /etc/logstash/patterns/postfix~
sudo rm /etc/logstash/patterns/nohup.out


# Create logstash-shipper logfile
sudo touch /var/log/logstash/shipper.log

# Copy in shipper.conf file

if [ ! -s /etc/logstash/shipper.conf ]
then
    sudo cp /vagrant_data/shipper.conf /etc/logstash/shipper.conf
else
    echo "shipper.conf file already exists"
fi


# Add in logstash service configuration
if [ ! -s /etc/init.d/logstash-agent ]
then
    echo "Copying logstash-agent init script"
    sudo cp /vagrant_data/logstash-agent.init /etc/init.d/logstash-agent
    sudo chmod +x /etc/init.d/logstash-agent
else
    echo "/etc/init.d/logstash-agent already exists"
fi


sudo chown root:root /etc/init.d/logstash-agent

echo "Starting logstash-agent"
sudo /etc/init.d/logstash-agent restart

echo "Checking logstash-agent status"
sudo /etc/init.d/logstash-agent status


