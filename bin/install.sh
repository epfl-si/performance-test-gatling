#!/usr/bin/env bash
#
# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.
#

# Package manager (apt-get, yum, ...)
PKG_MANAGER=""

# Tools needed to install / run
TOOLS=( wget unzip java )

GATLING_LINK='https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/2.3.0/gatling-charts-highcharts-bundle-2.3.0-bundle.zip'
GATLING_ARCHIVE='gatling.zip'

# Check package manager
if [ -n "$(command -v yum)" ]; then
  PKG_MANAGER="$(command -v yum)"
  PACKAGES=( wget unzip java-1.8.0-openjdk-src.x86_64 )
fi

if [ -n "$(command -v apt-get)" ]; then
  PKG_MANAGER="$(command -v apt-get)"
  PACKAGES=( wget unzip openjdk-8-jre )
fi

if [ -z "$PKG_MANAGER" ]; then
  "$0 doesn't support your package manager."
  exit 1
fi

# Install tools if needed
for ((i=0; i < ${#TOOLS[@]}; i++))
do
  if [ -z "$(command -v "${TOOLS[$i]}")" ]; then
    echo "command ${TOOLS[$i]} not found"
    sudo $PKG_MANAGER install ${PACKAGES[$i]}
  fi
done

# Download / extract Gatling
wget -O $GATLING_ARCHIVE $GATLING_LINK
unzip -o "$GATLING_ARCHIVE"
mv gatling-charts-highcharts* gatling
rm "$GATLING_ARCHIVE"
