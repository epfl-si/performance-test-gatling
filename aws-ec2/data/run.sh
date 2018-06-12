#!/bin/sh
TEST=${1:-ActuHome}
SIMDIR=$HOME/data/simulations
RESDIR=$HOME/data/results
GATDIR=$(ls -1d $HOME/data/gatling-charts*|tail -n 1)
$GATDIR/bin/gatling.sh -sf $SIMDIR -rf $RESDIR -m -s epfl.$TEST
