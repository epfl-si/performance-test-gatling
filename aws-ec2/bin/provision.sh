#!/bin/sh
CASA=$(dirname $(dirname $0))

ssh="$(pipenv run python ec2.py ssh)"
if [ $# -eq 0 ] ; then
ips="$(pipenv run python ec2.py list -i)"
else
ips="$*"
fi
echo "Provisioning $ips"
echo "IPs: $ips"
echo "SSH: $ssh"
for ip in $ips ; do
	for dir in data provision ; do
	   rsync -a -L --delete -e "$ssh" $CASA/$dir/ $ip:/home/ec2-user/$dir/
	done
	$ssh $ip "cd provision && sh setup.sh"
done