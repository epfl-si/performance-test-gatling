#!/bin/sh

usage() {
  cat << '__EOF' | sed 's/^    //'

    Start Gatling job on AWS.
    Options:
      -n NAME    Job name prefix (actual job name will be NAME_datetime)
      -c COUNT   Number of job instances to start [1]
      -t TEST    Name of the gatgling test (class) to start [TestWwwProxy]
      -p PROFILE Name of the profile in ~/.aws/credentials to use
      -e         Shortcut for -p gatling-eu
      -u         Shortcut for -p gatling-us
      -s SECONDS Period of time between synchronization checks. If present 
                 triggers syncrhonization. 
      -S URL     Countdown server address
      -x SECONDS Timeout for synchronization.
      -m         Add one to worker clients so they can be triggered manually

__EOF
}

name="epfl"
tname="TestWwwProxy"
asize=1
profile="gatling-eu"
syncsrv="http://myslideshot.epfl.ch"
syncto=3600
syncint=0
manstart=0

while getopts ":n:c:t:p:s:S:eumh" OPT; do
  [[ $OPTARG =~ ^- ]] && die "Option -$OPT requires an argument."
  case $OPT in
    :)
      die "Option -$OPTARG requires an argument."; ;;
    n)
      name="$OPTARG"; ;;
    c)
      asize=$OPTARG;  ;;
    t)
      tname="$OPTARG"; ;;
    p)
      profile="$OPTARG"; ;;
    e)
      profile="gatling-eu"; ;;
    u)
      profile="gatling-us"; ;;
    S)
      syncsrv="$OPTARG"; ;;
    s)
      syncint="$OPTARG"; ;;
    x)
      syncto="$OPTARG"; ;;
    m)
      manstart=1; ;;
    h)
      usage; exit 0; ;;
  esac
done

job_name="${name}_$(date +%Y%m%d%H%M)"

envs="{name=NAME, value=$job_name}, {name=TESTS, value=$tname}"
if [[ $syncint != "0" ]] ; then
  echo "Job synchronization. Setting countdown server for ${job_name}. "
  let s=$asize+$manstart
  curl "${syncsrv}/set?id=${job_name}&count=${s}"
  envs="$envs, {name=SYNC, value=$syncsrv}, {name=CI, value=$syncint}, {name=CTO, value=$syncto}"
fi

if [ "$asize" == "1" ] ; then
  aws --profile $profile batch submit-job \
      --job-queue gatling --job-definition gatling \
      --job-name "$job_name" \
      --container-overrides "environment=[$envs]"
else
  aws --profile $profile batch submit-job \
      --job-queue gatling --job-definition gatling \
      --job-name "$job_name" --array-properties "{\"size\":$asize}" \
      --container-overrides "environment=[$envs]"
fi

echo "To check the job status:"
echo "aws --profile $profile batch list-jobs --job-queue gatling"
sleep 5
echo "Example:"
aws --profile gatling batch list-jobs --job-queue gatling

echo "Once the job is done, you can collect all the results with:"
echo "aws --profile $profile s3 cp --recursive s3://idevelop-gatling-results/results/${job_name}/ results/${job_name}/"
