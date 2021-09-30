[ -n "${S3_BUCKET}" ] || die "Please provide an S3 bucket name (S3_BUCKET)"
[ -n "${AWS_ACCESS_KEY_ID}" ] || die "Please provide an AWS_ACCESS_KEY_ID"
[ -n "${AWS_SECRET_ACCESS_KEY}" ] || die "Please provide an AWS_SECRET_ACCESS_KEY"

echo "====================================== Save results to S3"
for f in /sim/$resdir/*/simulation.log ; do
  d=$(basename $(dirname $f ))_$(md5sum $f | cut -f 1 -d ' ').log         
  if [ -f $f ] ; then
    aws s3 cp $f s3://${S3_BUCKET}/$resdir/$d
  fi
done
