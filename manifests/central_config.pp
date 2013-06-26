Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

# Get fresh packages
exec { "update_packages":
  command => "apt-get  -y update",

}


# Install git for DVCS
package { "git":
  ensure => present,
  require => Exec[ "update_packages" ]
}


# Install our favorite editor
package { "emacs":
  ensure => present,
  require => Exec[ "update_packages" ]
}


# Change our hostname 
exec { "change_hostname": 
  command => "hostname smoker.example.com",
}


# Copy in our custom /etc/hosts file
file { "/etc/hosts":
  ensure => present,
  source => '/vagrant/etc_hosts',
  owner => "root",
  group => "root",
  mode => 0644,
}


exec { "change_timezone":
  command => "echo 'America/New_York' | sudo tee /etc/timezone",
}


exec { "reconfigure_timezone":
  command => "dpkg-reconfigure --frontend noninteractive tzdata",
  require => Exec[ "change_timezone" ],
}


$added_packages = [ "java7-runtime-headless", "curl", "unzip", "redis-server" ]

package { $added_packages:
  ensure => "present",
  require => Exec[ "update_packages" ],
}


exec { "apt_get_f":
  command => "apt-get -y -f install",
  require => Package[$added_packages],
}


# Create a directory structure using a trick from 
# http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
$logstash_dirs = [ "/opt", "/opt/logstash",
        "/etc", "/etc/logstash", "/etc/elasticsearch",
        "/var", "/var/log", "/var/log/logstash", ]

file { $logstash_dirs:
    ensure => "directory",
}


# Download logstash, but only if there is no current .jar file
exec { "download_logstash":
  command => "curl -s https://logstash.objects.dreamhost.com/release/logstash-1.1.9-monolithic.jar -o /opt/logstash/logstash-1.1.9-monolithic.jar",
  creates => "/opt/logstash/logstash-1.1.9-monolithic.jar",
  require => File[$logstash_dirs],
}


# Symlink to make it easier to refer to the logstash jar file 
file { '/opt/logstash/logstash.jar':
   ensure => 'link',
   target => '/opt/logstash/logstash-1.1.9-monolithic.jar',
   require => Exec[ "download_logstash" ],
}


# Create the logstash log file, presuming it does not already exist.
# Require that the directory it lives in is already existing.
exec { "create_logstash_log":
  command => "touch /var/log/logstash/central.log",
  creates => "/var/log/logstash/central.log",
  require => File[$logstash_dirs],
}


file { "/etc/logstash/central.conf":
  ensure => present,
  source => '/vagrant/central.conf',
  owner => "root",
  group => "root",
  mode => 0644,
  notify => Service[ "logstash-central" ]  
  
}


# Create the logstash-central init script. Make it root-owned and executable
file { "/etc/init.d/logstash-central":
  ensure => present,
  source => '/vagrant/logstash-central-orig.init',
  owner => "root",
  group => "root",
  mode => 0755,
}


# Run the logstash-central init script.
service { "logstash-central":
  enable => "true",
  ensure => "running",
  require => File[ "/etc/init.d/logstash-central" ],
}


# Launch the logstash web backend service
exec { "launch_logstash_web_backend":
  command => "nohup /usr/bin/java -jar /opt/logstash/logstash.jar web --backend elasticsearch://127.0.0.1/ >/dev/null 2>/dev/null &",
  require => Service[ "logstash-central" ]
  
}



# Download elasticsearch, if not already present
exec { "download_elasticsearch":
  command => "curl -s  https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.deb  -o /vagrant/elasticsearch-0.20.2.deb",
  creates => "/vagrant/elasticsearch-0.20.2.deb",
  require => Package[$added_packages],
}

# Install elasticsearch package. Since we have an already existing config file
# we want to keep it around.
exec { "install_elasticsearch":
  command => "dpkg -i --force-confold /vagrant/elasticsearch-0.20.2.deb",
  require => Exec[ "download_elasticsearch" ],
}


# Use custom elasticsearch.yml file
file { "/etc/elasticsearch/elasticsearch.yml":
  ensure => present,
  source => '/vagrant/elasticsearch.yml',
  owner => "root",
  group => "root",
  mode => 0644,
  notify => Service[ "elasticsearch" ],
  require => File[$logstash_dirs],
}

# Enable the service on boot, ensure running, and notify of config file changes
service { "elasticsearch":
  enable => "true",
  ensure => "running",
  require => File[ "/etc/elasticsearch/elasticsearch.yml" ]
}

exec { "sleep_for_elasticsearch":
  command => "echo 'sleeping for elasticsearch' && sleep 10",
  require => Service[ "elasticsearch" ],
}


# Upload the elasticsearch index. We use a separate script to avoid clutter.
exec { "upload_es_index":
  command => '/vagrant/upload_es_index.sh',
  require => Exec[ "sleep_for_elasticsearch" ],
}


# Ensure that the redis-server is enabled on boot and running
service { "redis-server":
  enable => "true",
  ensure => "running",
  require => Package[$added_packages],
}

# Copy in our custom redis.conf file, and notify redis-server when it changes
file { "/etc/redis/redis.conf":
  ensure => present,
    source => '/vagrant/redis.conf',  
    owner => "root",
    group => "root",
    mode => 0644,
    notify => Service[ "redis-server" ]  
}





