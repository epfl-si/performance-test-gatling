#!/bin/sh
#
# Wrapper script for starting Gatling having defined the parameters 
# needed by the simulation as JAVA_OPTS defines

usage() {
  echo "TODO"
}

die() {
  echo "$*"
  exit 1
}

SIMDIR=$HOME/data/simulations
GATDIR=$(ls -1d $HOME/data/gatling-charts*|tail -n 1)

JAVA_OPTS=""
while getopts ":hu:b:t:p:n:l:s:K" OPT; do
  [[ $OPTARG =~ ^- ]] && die "Option -$OPT requires an argument."
  case $OPT in
    :)
       die "Option -$OPTARG requires an argument."; ;;
    \?)
       usage
       die "Unrecognized flag $OPTARG"; ;;
    K)
      echo "Cleaning all previous results"; rm -rf $HOME/data/results/*; ;;
    u)
      opt_u="_$OPTARG" ; JAVA_OPTS="$JAVA_OPTS -Dusers=$OPTARG"; ;;
    t)
      opt_t="_$OPTARG" ; JAVA_OPTS="$JAVA_OPTS -Dduration=$OPTARG"; ;;
    p)
      opt_p="_$OPTARG" ; JAVA_OPTS="$JAVA_OPTS -Dreqpath=$OPTARG"; ;;
    n)
      opt_n="_$OPTARG" ; JAVA_OPTS="$JAVA_OPTS -Dnpages=$OPTARG"; ;;
    b)
      opt_b="_$OPTARG" ; JAVA_OPTS="$JAVA_OPTS -Dbaseurl=$OPTARG"; ;;
    s)
      JAVA_OPTS="$JAVA_OPTS -Dpseed=$OPTARG"; ;;
    l)
      opt_l="_$OPTARG" ; ;;
    h)
      usage; exit; ;;
  esac
done
shift $((OPTIND-1))
TEST=${1:-ActuHome}

RESDIR="$HOME/data/results/${TEST}${opt_l}${opt_b}${opt_p}${opt_n}${opt_u}"
[ -d $RESDIR ] || mkdir -p $RESDIR

echo "JAVAOPTS = $JAVA_OPTS"
echo "TEST     = $TEST"
echo "RESDIR   = $RESDIR"
export JAVA_OPTS
$GATDIR/bin/gatling.sh -sf $SIMDIR -rf $RESDIR -m -s epfl.$TEST
