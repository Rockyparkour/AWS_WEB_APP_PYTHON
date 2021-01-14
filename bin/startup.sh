#!/usr/bin/env bash

set -e

CURRENT_DIR=$PWD

# Magic sauce
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null && pwd )"

if [[ ! -d ${SCRIPT_DIR}/../logs ]]; then
  mkdir ${SCRIPT_DIR}/../logs
fi

JAVA_VERSION=14.0.1+7
FUSIONAUTH_JAVA_DIR=${SCRIPT_DIR}/../java
BASE_URL_PATH=https://files.fusionauth.io/java/openjdk

if [[ ! -d ${FUSIONAUTH_JAVA_DIR} ]]; then
  mkdir -p ${FUSIONAUTH_JAVA_DIR}
fi

if [[ ! -d ${FUSIONAUTH_JAVA_DIR} ]]; then
  mkdir -p ${FUSIONAUTH_JAVA_DIR}
fi

# Ensure both the 'current' and 'jdk-${JAVA_VERSION}' exist, this tells us Java is setup and at the correct version
if [ ! -e "${FUSIONAUTH_JAVA_DIR}/current" ] || [ ! -d "${FUSIONAUTH_JAVA_DIR}/jdk-${JAVA_VERSION}" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    if [ -e ~/dev/java/current14 ]; then
      # Development, just sym link to our current version of Java, because only 'current' will exist in dev, we'll always rebuild the symlink.
      cd "${FUSIONAUTH_JAVA_DIR}"
      rm -f current
      ln -s ~/dev/java/current14 current
    else
      curl ${CURL_OPTS} "${BASE_URL_PATH}/openjdk-macos-${JAVA_VERSION}.tar.gz" -o "${FUSIONAUTH_JAVA_DIR}/openjdk-macos-${JAVA_VERSION}.tar.gz"
      tar xfz "${FUSIONAUTH_JAVA_DIR}/openjdk-macos-${JAVA_VERSION}.tar.gz" -C "${FUSIONAUTH_JAVA_DIR}"
      cd "${FUSIONAUTH_JAVA_DIR}"
      rm -f current
      ln -s jdk-${JAVA_VERSION}/Contents/Home current
      rm openjdk-macos-${JAVA_VERSION}.tar.gz
    fi
  elif [ "$(uname -s)" = "Linux" ]; then
    curl ${CURL_OPTS} "${BASE_URL_PATH}/openjdk-linux-${JAVA_VERSION}.tar.gz" -o "${FUSIONAUTH_JAVA_DIR}/openjdk-linux-${JAVA_VERSION}.tar.gz"
    tar xfz "${FUSIONAUTH_JAVA_DIR}/openjdk-linux-${JAVA_VERSION}.tar.gz" -C "${FUSIONAUTH_JAVA_DIR}"
    cd "${FUSIONAUTH_JAVA_DIR}"
    rm -f current
    ln -s jdk-${JAVA_VERSION} current
    rm openjdk-linux-${JAVA_VERSION}.tar.gz
  fi
fi

# Set JAVA_HOME
JAVA_HOME=${FUSIONAUTH_JAVA_DIR}/current

# Search
echo -e "Starting fusionauth-search ... \c"
if [[ -f ${SCRIPT_DIR}/../fusionauth-search/elasticsearch/bin/elasticsearch ]]; then
  if pgrep -f fusionAuthSearchEngine87AFBG16 > /dev/null; then
    echo "skipped, already running."
  else
    cd ${SCRIPT_DIR}/../fusionauth-search/elasticsearch/bin
    nohup ./elasticsearch < /dev/null >> ${SCRIPT_DIR}/../logs/fusionauth-search.log 2>&1 &
    disown
    echo "done."
    echo "  --> Logging to ${SCRIPT_DIR}/../logs/fusionauth-search.log"
  fi
else
  echo " skipped, not installed"
fi

# App
echo -e "Starting fusionauth-app ... \c"
if [[ -f ${SCRIPT_DIR}/../fusionauth-app/apache-tomcat/bin/catalina.sh ]]; then
  cd ${SCRIPT_DIR}/../fusionauth-app/apache-tomcat/bin
  nohup ./catalina.sh start < /dev/null >> ${SCRIPT_DIR}/../logs/fusionauth-app.log 2>&1 &
  disown
  echo "done."
  echo "  --> Logging to ${SCRIPT_DIR}/../logs/fusionauth-app.log"
else
  echo " skipped, not installed"
fi

cd ${CURRENT_DIR}
