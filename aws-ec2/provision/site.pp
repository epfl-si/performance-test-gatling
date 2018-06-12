ensure_packages(['wget unzip'], {ensure => 'installed'})

class { 'java' :
  package => 'java-1.8.0-openjdk',
  java_alternative => '/usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java'
}