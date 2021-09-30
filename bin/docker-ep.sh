#!/bin/bash
#
# Gatling simulation runner entry point
# Loads a set of scripts given as command line arguments and execute them.
#
# ---------------------------- Utility functions
die() {
  echo $* > /dev/stderr
  exit 1
}

git_branch=""
while getopts ":e" OPT; do
  [[ $OPTARG =~ ^- ]] && die "Option -$OPT requires an argument."
  case $OPT in
    :)
      die "Option -$OPTARG requires an argument."; ;;
    e)
      echo "------------------------------------------------- env"
      env
      echo "-------------------------------------------------/env"
      ;;
  esac
done
shift $((OPTIND-1))
CMDS="$@"

echo "     CMDS:    $CMDS"
CMDPATHS=""
for cmd in $CMDS ; do
  t=""
  if [[ $cmd == http* ]] ; then
    t=$(mktemp -u -t XXXXXX).sh
    wget -O $t $cmd || t=""
  else
    for c in /bin/sim/$cmd /sim/bin/$cmd /sim/$cmd $cmd ; do
      if [ -f $c ] ; then
        t=$c
      fi
    done
  fi
  echo "     add '$t' as result of '$cmd'"
  CMDPATHS="$CMDPATHS $t"
done

for c in $CMDPATHS ; do
  if [ -f $c ] ; then
    echo "     Calling $c."
    . $c
  else
    echo "!! --- command $c not found! Wille be skipped."
  fi
done
