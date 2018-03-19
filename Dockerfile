FROM multiscan/gatling:v0.0.1
ADD . /sim
ENTRYPOINT /sim/bin/run_simulations.sh "$TESTS"
