#!/bin/sh

GATVER=2.3.1
CASA=$(dirname $(dirname $0))

die() {
	echo "$*" >/dev/stderr
	exit 1
}

# If not yet present, create the virtenv
if [ ! -d $CASA/ENV ] ; then
	if [ -n "$(which pip3)" ] ; then
		pip3 install virtualenv   || die "Could no install virtualenv package with pip"
	else
		if [ -n "$(which pip)" ] ; then
			pip install virtualenv   || die "Could no install virtualenv package with pip"
		else
			die "Please install pip"
		fi
	fi
	pushd $CASA              || die "Unexpected error: cannot change to '$CASA'"
	virtualenv ENV           || die "Could not create virtualenv"
    source ENV/bin/activate
    curl https://bootstrap.pypa.io/get-pip.py | python
    pip install -r requirements.txt
    popd
fi

if [ ! -L $CASA/data/simulations ] ; then
	pushd $CASA/data
	ln -s ../../simulations 
	popd
fi


if [ ! -d $CASA/data/gatling-charts-highcharts-bundle-$GATVER ] ; then
	pushd $CASA/data
	curl -o aaa.zip https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/${GATVER}/gatling-charts-highcharts-bundle-${GATVER}-bundle.zip
	unzip aaa.zip
	[ -d gatling-charts-highcharts-bundle-$GATVER ] && rm -f aaa.zip
	popd
fi

