nrep=${NREP:-1}
wtime=${WAIT:-1}
if [ -n "$NAME" ] ; then
  prefix="${NAME}/"
  resdir="results/${NAME}"
else
  prefix=""
  resdir="results/"
fi

echo "====================================== Run simulations ${nrep} x (${TESTS})"
for i in $(seq 1 $nrep) ; do
  for t in ${TESTS} ; do
    gatling.sh -sf /sim/simulations/ -rf /sim/$resdir -m -s epfl.$t
  done
  sleep $wtime
done
