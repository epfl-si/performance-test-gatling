#!/bin/sh
sudo yum update -y
PLBR=$HOME/bin/librarian-puppet
if [ ! -f /opt/puppetlabs/bin/puppet ] ; then
  sudo rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-6.noarch.rpm
  sudo yum install -y puppet-agent
fi
if [ ! -f $PLBR ] ; then
  gem install --no-rdoc --no-ri librarian-puppet
fi
. /etc/profile.d/puppet-agent.sh 
cd $HOME/provision
$PLBR install
sudo $(which puppet) apply --modulepath=$HOME/provision/modules site.pp
