#!/bin/sh


name="epfl"
tname="TestWwwProxy"
asize=1
profile="gatling-eu"

while getopts ":n:c:t:p:eu" OPT; do
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
      profile=gatling-eu; ;;
    u)
      profile=gatling-us; ;;
    h)
      usage; exit 0; ;;
  esac
done

job_name="${name}_$(date +%Y%m%d%H%M)"
if [ "$asize" == "1" ] ; then
  aws --profile $profile batch submit-job \
      --job-queue gatling --job-definition gatling \
      --job-name "$job_name" \
      --container-overrides "environment=[{name=NAME, value=$job_name}, {name=TESTS, value=$tname}]"
else
  aws --profile $profile batch submit-job \
      --job-queue gatling --job-definition gatling \
      --job-name "$job_name" --array-properties "{\"size\":$asize}" \
      --container-overrides "environment=[{name=NAME, value=$job_name}, {name=TESTS, value=$tname}]"
fi

echo "To check the job status:"
echo "aws --profile gatling batch list-jobs --job-queue gatling"
sleep 5
echo "Example:"
aws --profile gatling batch list-jobs --job-queue gatling

echo "Once the job is done, you can collect all the results with:"
echo "aws --profile $profile s3 cp --recursive s3://idevelop-gatling-results/results/${job_name}/ results/${job_name}/"
