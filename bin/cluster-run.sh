
#!/bin/bash#!/usr/bin/env bash
#
# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.
#
# Script source base: https://gatling.io/docs/current/cookbook/scaling_out/

##################################################################################################################
#Gatling scale out/cluster run script:
#Before running this script some assumptions are made:
#1) Public keys were exchange inorder to ssh with no password promot (ssh-copy-id on all remotes)
#2) Check  read/write permissions on all folders declared in this script.
#3) Gatling installation (GATLING_HOME variable) is the same on all hosts
#4) Assuming all hosts has the same user name (if not change in script)
##################################################################################################################

if [ -z $1 ] || [ $# -gt 1 ]
then
    echo "Usage: $0 <simulation_name>"
    exit -1
fi

SIMULATION_NAME="computerdatabase.$1"

#Test if simulation fiel exist
CURRENT_DIR="${PWD##*/}"
SEARCH_PATH="."
if [ $CURRENT_DIR == "bin" ]
then
  SEARCH_PATH="./.."
fi

if [ ! $(find $SEARCH_PATH -name $1.scala) ]
then
  echo "Simulation not exist."
fi

#Assuming same user name for all hosts
USER_NAME='kis'

#Remote hosts list
#HOSTS=( idevelopsrv20 idevelopsrv21 idevelopsrv22 idevelopsrv23 idevelopsrv24 )
HOSTS=(  )

#Assuming all Gatling installation in same path (with write permissions)
GATLING_LOCAL_HOME=gatling
GATLING_REMOTE_HOME=/home/$USER_NAME/performance-test-gatling/gatling
GATLING_LOCAL_SIMULATIONS_DIR=simulations
GATLING_REMOTE_SIMULATIONS_DIR=/home/$USER_NAME/performance-test-gatling/simulations
GATLING_LOCAL_RUNNER=$GATLING_LOCAL_HOME/bin/gatling.sh
GATLING_REMOTE_RUNNER=$GATLING_REMOTE_HOME/bin/gatling.sh

GATLING_LOCAL_REPORT_DIR=$GATLING_LOCAL_HOME/results/
GATHER_LOCAL_REPORTS_DIR=$GATLING_LOCAL_HOME/reports/
GATLING_REMOTE_REPORT_DIR=$GATLING_REMOTE_HOME/results/

echo "Starting Gatling cluster run for simulation: $SIMULATION_NAME"

echo "Cleaning previous runs from localhost"
rm -rf $GATHER_LOCAL_REPORTS_DIR
mkdir $GATHER_LOCAL_REPORTS_DIR
rm -rf $GATLING_LOCAL_REPORT_DIR

for HOST in "${HOSTS[@]}"
do
  echo "Cleaning previous runs from host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'rm -rf $GATLING_REMOTE_REPORT_DIR'"
done

for HOST in "${HOSTS[@]}"
do
  echo "Copying simulations to host: $HOST"
  scp -r $GATLING_LOCAL_SIMULATIONS_DIR $USER_NAME@$HOST:$GATLING_REMOTE_SIMULATIONS_DIR
done

for HOST in "${HOSTS[@]}"
do
  echo "Running simulation on host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'nohup $GATLING_REMOTE_RUNNER -nr -sf $GATLING_REMOTE_SIMULATIONS_DIR -s $SIMULATION_NAME > $GATLING_REMOTE_HOME/run.log 2>&1 &'"
done

echo "Running simulation on localhost"
$GATLING_LOCAL_RUNNER -nr -sf $GATLING_LOCAL_SIMULATIONS_DIR -s $SIMULATION_NAME

echo "Gathering result file from localhost"
ls -t $GATLING_LOCAL_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_LOCAL_REPORT_DIR}{} ${GATLING_LOCAL_REPORT_DIR}report
cp ${GATLING_LOCAL_REPORT_DIR}report/simulation.log $GATHER_LOCAL_REPORTS_DIR

for HOST in "${HOSTS[@]}"
do
  echo "Gathering result file from host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'ls -t $GATLING_REMOTE_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REMOTE_REPORT_DIR}{} ${GATLING_REMOTE_REPORT_DIR}report'"
  scp $USER_NAME@$HOST:${GATLING_REMOTE_REPORT_DIR}report/simulation.log ${GATHER_LOCAL_REPORTS_DIR}simulation-$HOST.log
done

mv $GATHER_LOCAL_REPORTS_DIR $GATLING_LOCAL_REPORT_DIR
echo "Aggregating simulations"
$GATLING_LOCAL_RUNNER -ro reports

#using Firefox on Ubuntu
firefox ${GATLING_LOCAL_REPORT_DIR}reports/index.html
