#!/bin/bash
echo "========================= Simulation runner with Tests='$*'"
for t in $* ; do
  /gatling/bin/gatling.sh -sf /sim/simulations/ -rf /sim/gatling/results -m -s epfl.$t
done
