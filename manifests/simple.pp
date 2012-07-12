exec { "apt-update":
  command     => "/usr/bin/apt-get update",
  refreshonly => true;
}

group { "puppet":
  ensure => "present",
}

package { "jruby":
  ensure => "present"
}

package {"scala":
  ensure => "present"
}

File { owner => 0, group => 0, mode => 0644 }

file { '/etc/motd':
 content => "The barber shaves only those who do not shave themselves. Who shaves the barber?\n"
 }
