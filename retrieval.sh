#!/usr/bin/env bash

PROFILE=ncicrdc

filecheck () {
if ! [ -f "$1" ]; then
  printf "'$1' is not a file\n"
  exit 1
fi
}

filecheck "$1"
filecheck "$2"

MANIFEST=$1
CREDS=$2

APIKEY="3217c67d843a7aa0ce3e72497a5ffb00"
ENDPOINT="locahost"
PORT="8080"

BASEPATH="/tmp/galaxyfiles"

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

FULLPATH="$BASEPATH/$TIMESTAMP"

if ! [ -d $FULLPATH ] ; then
  printf "base path $FULLPATH not found, creating..."
  mkdir -p $FULLPATH
fi



gen3-client configure --profile=$PROFILE --cred=$CREDS --apiendpoint=https://nci-crdc.datacommons.io

while IFS= read -r line; do
  id="$(echo $line | awk '{print $1}')"
  printf "downloading GUID: $id\n"
  gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FULLPATH" &
done <<< "$(tail -n +2 $1)"

wait
printf "files in $1 downloaded to path:\n - $FULLPATH\n\t...adding to Galaxy..."

python3 main.py -a "$APIKEY" -e "$ENDPOINT" -p "$PORT" -s "$TIMESTAMP"