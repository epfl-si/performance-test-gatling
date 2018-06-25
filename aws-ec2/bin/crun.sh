#!/bin/sh
# (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
# Switzerland, VPSI, 2018

PSSH=""
crun() {
	[ -n "$PSSH" ] || PSSH="$(./bin/ec2.py pssh)"
	echo "PSSH: $PSSH"
	echo "$PSSH -i -t 0 '$*'" | /bin/sh
}

crun $*
