#!/bin/sh
# (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
# Switzerland, VPSI, 2018

GATVER=2.3.1
CASA=$(dirname $(dirname $0))
. ENV/bin/activate

ssh="$(./bin/ec2.py ssh)"
if [ $# -eq 0 ] ; then
  ips="$(./bin/ec2.py list -i)"
else
  ips="$*"
fi
echo "IPs: $ips"
echo "SSH: $ssh"
for ip in $ips ; do
  rsync -L -e "$ssh" $CASA/data/*.sh $ip:/home/ec2-user/data/
  rsync -a -L -e "$ssh" --delete $CASA/data/simulations/ $ip:/home/ec2-user/data/simulations/ 
done
