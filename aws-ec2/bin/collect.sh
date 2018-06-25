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
 rsync -a -L -e "$ssh" $ip:/home/ec2-user/data/results/ $CASA/results/    &
done
wait

for dir in $CASA/results/* ; do
  echo "---------- $dir"
  if [ ! -d $dir/report ] ; then
    mkdir $dir/report
    for rd in $dir/*-* ; do
      if [ -f $rd/simulation.log ] ; then
        cp $rd/simulation.log $dir/report/$(basename $rd).log
      fi
    done
    $CASA/data/gatling-charts-highcharts-bundle-$GATVER/bin/gatling.sh -ro $dir/report -rf ./ -sf $CASA/data/simulations
    rsync -av $dir/report/ cangiani@lth.epfl.ch:/web/cangiani/gat/$(basename $dir)/
  fi
done
