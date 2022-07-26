#!/bin/sh
# (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
# Switzerland, VPSI, 2018

GATVER=2.3.1
VENV=aws
CASA=$(dirname $(dirname $0))

die() {
  echo "$*" >/dev/stderr
  exit 1
}

which pyenv >/dev/null 2>&1 || die "Please install pyenv: https://github.com/pyenv/pyenv and pyenv-virtualenv: https://github.com/pyenv/pyenv-virtualenv"

# pyenv
export PYENV_VIRTUALENV_DISABLE_PROMPT=0
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
if which pyenv-virtualenv-init > /dev/null; then 
  eval "$(pyenv virtualenv-init -)"
fi

pyenv virtualenvs | grep -q $VENV
if [ $? -ne 0 ] ; then
  echo "Creating virtualenv $VENV"
  pyenv virtualenv $VENV
fi
pyenv activate $VENV || die "Coiuld not activate $ENV python virtual environment"
pip install -r requirements.txt

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

