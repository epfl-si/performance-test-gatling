# 1. the /sim directory is mounted from the host
# 2. the /sim directory is created from an "origin" given in second argument

echo "==== origin:  '${ORIGIN}'"
origin="${ORIGIN}"
# If origin is given, we assume /sim is not yet present
if [ -n "$origin" ] ; then
  [ -d /sim/simulations ] && die "/sim directory is already present. Do not mount if you want to start from external origin"
  if   [[ $origin == *.git ]] ; then
    sleep $(( ( RANDOM % 20 )  + 1 ))
    git clone $origin /sim
    if [ ! -d /sim/simulations ] ; then
      echo "===! First git clone failed. Retrying"
      sleep $(( ( RANDOM % 20 )  + 1 ))
      git clone $origin /sim
    fi
  elif [[ $origin == s3* ]] ; then
    [ -n "${AWS_ACCESS_KEY_ID}" ]     || die "Please provide an AWS_ACCESS_KEY_ID"
    [ -n "${AWS_SECRET_ACCESS_KEY}" ] || die "Please provide an AWS_SECRET_ACCESS_KEY"
    echo "=== S3 origin. Keys are present."
    aws s3 cp --recursive $origin /sim/simulations || die "Simulations copy from S3 failed"
  else
    die "http simulation server not yet implemented"
  fi
else
  [ -d /sim ] || die "/sim directory is not mounted. Run with docker run -v LOCALDIR:/sim"
fi
[ -d /sim/simulations ]  || die "Simulation directory is not present after fetch. Giving up."
