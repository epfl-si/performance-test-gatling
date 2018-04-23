# 1. the /sim directory is mounted from the host
# 2. the /sim directory is created from an "origin" given in second argument

origin="${ORIGIN}"

echo "==== origin:  '$origin'"
echo "     branch:  '$git_branch'"
# If origin is given, we assume /sim is not yet present
if [ -n "$origin" ] ; then
  [ -d /sim/simulations ] && die "/sim directory is already present. Do not mount if you want to start from external origin"
  if   [[ $origin == *.git ]] ; then
    git clone $origin /sim
  else
    die "http simulation server not yet implemented"
  fi
else
  [ -d /sim ] || die "/sim directory is not mounted. Run with docker run -v LOCALDIR:/sim"
fi
