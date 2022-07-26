#!/bin/sh
# (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
# Switzerland, VPSI, 2018

CASA=$(dirname $(dirname $0))
. ENV/bin/activate

provision_one() {
    ip=$1
    echo "Provisioning $ip"
    for dir in data provision ; do
        rsync -a -L --delete -e "$ssh" $CASA/$dir/ $ip:/home/ec2-user/$dir/
    done
    $ssh $ip "cd provision && sh setup.sh"
}

ssh="$($CASA/bin/ec2.py ssh)"
if [ $# -eq 0 ] ; then
    ips="$($CASA/bin/ec2.py list -i)"
else
    ips="$*"
fi
# echo "Provisioning $ips"
# echo "IPs: $ips"
# echo "SSH: $ssh"
for ip in $ips ; do
    provision_one $ip &
done
wait
echo "Done."