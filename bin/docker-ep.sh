#!/bin/bash
#
# Gatling simulation runner entry point
# This only clone the simulation source repository and execute the test with the given command
# There is one mandatory argument: the path of the command for running the simulations
# Then two options:
# 1. the /sim directory is mounted from the host
# 2. the /sim directory is created from an "origin" given in second argument

# ---------------------------- Utility functions
die() {
  echo $* > /dev/stderr
  exit 1
}

git_branch=""
while getopts ":f:b:" OPT; do
  [[ $OPTARG =~ ^- ]] && die "Option -$OPT requires an argument."
  case $OPT in
    :)
      die "Option -$OPTARG requires an argument."; ;;
    f)
      origin="$OPTARG"; ;;
    b)
      git_branch="-b $OPTARG"; ;;
  esac
done
shift $((OPTIND-1))
CMDS="$@"

echo "==== origin:  '$origin'"
echo "     branch:  '$git_branch'"
echo "     CMDS:    $CMDS"
echo "     cr uri:  '$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'" 

# If origin is given, we assume /sim is not yet present
if [ -n "$origin" ] ; then
  [ -d /sim/simulations ] && die "/sim directory is already present. Do not mount if you want to start from external origin" 
  if   [[ $origin == *.git ]] ; then
    git clone ${git_branch} $origin /sim
  else
    die "http simulation server not yet implemented"
  fi
else
  [ -d /sim ] || die "/sim directory is not mounted. Run with docker run -v LOCALDIR:/sim" 
fi


CMDPATHS=""
for cmd in $CMDS ; do
  t=""
  for c in /sim/bin/$cmd /sim/$cmd $cmd ; do
    if [ -f $c ] ; then
      t=$c
    fi
  done
  CMDPATHS="$CMDPATHS $t"
done
echo "     CMDS:    $CMDPATHS"

for c in $CMDPATHS ; do
  . $c
done
