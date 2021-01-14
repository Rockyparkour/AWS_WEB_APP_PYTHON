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

echo -e "Stopping fusionauth-search ... \c"
if pgrep -f fusionAuthSearchEngine87AFBG16; then
  if ! pkill -f fusionAuthSearchEngine87AFBG16; then
    echo "Failed to stop fusionauth-search"
  else
    echo "done"
  fi
else
  if [[ -d ${SCRIPT_DIR}/../fusionauth-search ]]; then
    echo " skipped, not running."
  else
    echo " skipped, not installed."
  fi
fi

echo -e "Stopping fusionauth-app ... \c"
if [[ -f ${SCRIPT_DIR}/../fusionauth-app/apache-tomcat/bin/catalina.sh ]]; then
  cd ${SCRIPT_DIR}/../fusionauth-app/apache-tomcat/bin
  if ! ./catalina.sh stop; then
    echo "Failed to stop fusionauth-app"
  else
    echo "done"
  fi
else
  echo " skipped, not installed"
fi

cd ${CURRENT_DIR}
