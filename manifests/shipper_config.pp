# Added global path
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
  command => "hostname maurice.example.com",
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


$added_packages = [ "java7-runtime-headless", "curl", "unzip", 
                    "apache2-mpm-prefork", "tomcat6", "stunnel", "mailutils",
                    ]

package { $added_packages:
  ensure => "present",
  require => Exec[ "update_packages" ],
}


exec { "apt_get_f":
  command => "apt-get -y -f install",
  require => Package[$added_packages],
}



# Set up Apache config files

# Mair Apache configuration
file { "/etc/apache2/apache2.conf":
    ensure => present,
    source => '/vagrant/shipper.apache2.conf',  
    owner => "root",
    group => "root",
    mode => 0644,
    require => [ File[ "/etc/apache2" ],],
}


# The site we wish to enable
file { "/etc/apache2/sites-available/000-default":
    ensure => present,
    source => '/vagrant/sites-available_000-default',  
    owner => "root",
    group => "root",
    mode => 0644,
    require => [ File["/etc/apache2"], ],            
}


# Enable the site only if it exists

exec { "enable_apache_sites":
    command => "a2ensite 000-default",
    require => [ Service[ "apache2" ], 
                File[ "/etc/apache2/sites-available/000-default" ], ], 
}

service { "apache2":
  enable => "true",
  ensure => "running",
  require => [ File["/etc/apache2/apache2.conf"], 
             File["/etc/apache2/sites-available/000-default"], ]

}


file { "/etc/rsyslog.conf":
    ensure => present,
    source => '/vagrant/rsyslog.conf',  
    owner => "root",
    group => "root",
    mode => 0644,
    notify => Service[ "rsyslog" ]        
}


service { "rsyslog":
  enable => "true",
  ensure => "running",
  require => File[ "/etc/rsyslog.conf" ],
}


# Create a directory structure using a trick from 
# http://www.puppetcookbook.com/posts/creating-a-directory-tree.html
$logstash_dirs = [ "/opt", "/opt/logstash",
        "/etc", "/etc/logstash", "/etc/logstash/patterns",
        "/etc/apache2", "/etc/apache2/sites-available", "/etc/apache2/sites-enabled",
        "/var", "/var/log", "/var/log/logstash", ]

file { $logstash_dirs:
    ensure => "directory",
}


# Download logstash, but only if there is no current .jar file
exec { "download_logstash":
  command => "curl -s https://logstash.objects.dreamhost.com/release/logstash-1.1.9-monolithic.jar -o /opt/logstash/logstash-1.1.9-monolithic.jar",
  creates => "/opt/logstash/logstash-1.1.9-monolithic.jar",
  require => [ File[$logstash_dirs], Package["curl"], ],
}


# Symlink to make it easier to refer to the logstash jar file 
file { '/opt/logstash/logstash.jar':
   ensure => 'link',
   target => '/opt/logstash/logstash-1.1.9-monolithic.jar',
   require => [File[$logstash_dirs], Exec[ "download_logstash" ] ],
}


# Bring in our logstash patterns
file { '/etc/logstash/patterns/postfix':
   source => '/vagrant/postfix',
   require => [ File[$logstash_dirs], Exec[ "download_logstash" ],],
}


# Create the logstash log file, presuming it does not already exist.
# Require that the directory it lives in is already existing.
exec { "create_logstash_log":
  command => "touch /var/log/logstash/shipper.log",
  creates => "/var/log/logstash/shipper.log",
  require => [ File[$logstash_dirs], Service["logstash-agent"],]
}


file { "/etc/logstash/shipper.conf":
  ensure => present,
  source => '/vagrant/shipper.conf',
  owner => "root",
  group => "root",
  mode => 0644,
  notify => Service[ "logstash-agent" ]  
  
}


# Create the logstash-shipper init script. Make it root-owned and executable
file { "/etc/init.d/logstash-agent":
  ensure => present,
  source => '/vagrant/logstash-agent.init',
  owner => "root",
  group => "root",
  mode => 0755,
}


# Run the logstash-shipper init script.
service { "logstash-agent":
  enable => "true",
  ensure => "running",
  require => File[ "/etc/init.d/logstash-agent" ],
}

