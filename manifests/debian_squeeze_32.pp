group { "puppet":
  ensure => "present",
}

package { "openjdk-6-jre":
  ensure => "present"
}

File { owner => 0, group => 0, mode => 0644 }

file { '/etc/motd':
 content => "The barber shaves only those who do not shave themselves. Who shaves the barber?\n"
 }
