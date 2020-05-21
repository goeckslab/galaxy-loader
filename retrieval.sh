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

FILEPATH="/tmp/galaxyfiles"

if ! [ -d $FILEPATH ] ; then
  printf "base path $FILEPATH not found, creating..."
  mkdir $FILEPATH
fi

if [ "$(ls -A $FILEPATH/)" ] ; then
  printf "Clearing the contents of $FILEPATH...\n"
  rm -rf $FILEPATH/*
fi

gen3-client configure --profile=$PROFILE --cred=$CREDS --apiendpoint=https://nci-crdc.datacommons.io

while IFS= read -r line; do
  id="$(echo $line | awk '{print $1}')"
  printf "downloading GUID: $id\n"
  gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FILEPATH" &
done <<< "$(tail -n +2 $1)"

wait
printf "files in $1 downloaded...\n"
