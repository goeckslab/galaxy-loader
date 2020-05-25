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

if [ -z "$3" ] ; then
  printf "$3 is empty, should be API key\n"
  exit 1
fi

if [ -z "$4" ] ; then 
  printf "$4 must be a base path\n"
  exit 1
fi

MANIFEST=$1
CREDS=$2

APIKEY="$3"
ENDPOINT="127.0.0.1"
PORT="8080"

BASEPATH="$4"

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
  gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FULLPATH"
  # 3 retries for failed resolution
  if [ "$?" != 0 ] ; then
    sleep 2
    gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FULLPATH"
    if [ "$?" != 0 ] ; then
      sleep 2
      printf "... retrying ... "
      gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FULLPATH"
      if [ "$?" != 0 ] ; then
        sleep 2
        printf "re-retrying ... \n"
        gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$FULLPATH"
    fi
    fi
  fi
done <<< "$(tail -n +2 $1)"

# wait # save thread faniciness
printf "files in $1 downloaded to path:\n - $FULLPATH\n\t...adding to Galaxy...\n"

python3 main.py -a "$APIKEY" -e "$ENDPOINT" -p "$PORT" -s "$TIMESTAMP"