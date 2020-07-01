#!/usr/bin/env bash

help () {
  printf "Arguments (separated by a space after script name):\n"
  printf "1st: Manifest file location\n"
  printf "2nd: Credentials file location\n"
  printf "3rd: API key\n"
  printf "4th: Base path where files will be downloaded\n"
  printf "5th: URL (without port) of Galaxy instance\n"
  printf "6th: Port on which Galaxy is listening (default: 80)\n\n"
}

if [ "$1" == "-h" ] ; then 
  help
  exit 0
elif [ "$1" == "--help" ] ; then
  help
  exit 0
fi

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
  printf "argument 3 is empty, should be API key\n"
  exit 1
fi

if [ -z "$4" ] ; then 
  printf "argument 4 must be a base path\n"
  exit 1
fi

if [ -z "$5" ] ; then
  ENDPOINT="127.0.0.1"
  printf "Argument 5 (endpoint) not set ... using '$ENDPOINT'\n"
else
  ENDPOINT="$5"
fi

if [ -z "$6" ] ; then
  PORT="80"
  printf "Argument 6 (port) not set ... using '$PORT'\n"
else
  PORT="$6"
fi

MANIFEST=$1
CREDS=$2

APIKEY="$3"

BASEPATH="$4"

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

FULLPATH="$BASEPATH/$TIMESTAMP"

if ! [ -d $FULLPATH ] ; then
  printf "base path $FULLPATH not found, creating..."
  mkdir -p $FULLPATH
fi



gen3-client configure --profile=$PROFILE --cred=$CREDS --apiendpoint=https://nci-crdc.datacommons.io

RESULT=""
TMPPATH="/tmp/gen3temp"
mkdir -p "$TMPPATH"

while IFS= read -r line; do
  id="$(echo $line | awk '{print $1}')"
  printf "downloading GUID: $id\n"
  RESULT=$(gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$TMPPATH" 2>&1 1>/dev/null |  grep "503 Service Unavailable error has occurred")
  # 3 retries for failed resolution
  if [ ! -z "$RESULT" ] ; then
    sleep 2
    printf " retrying ... "
    RESULT=$(gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$TMPPATH" 2>&1 1>/dev/null |  grep "503 Service Unavailable error has occurred")
    if [ ! -z "$RESULT" ] ; then
      sleep 2
      printf "... re-retrying ... "
      RESULT=$(gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$TMPPATH" 2>&1 1>/dev/null |  grep "503 Service Unavailable error has occurred")
      if [ ! -z "$RESULT" ] ; then
        sleep 2
        printf "re-re-retrying ... \n"
        RESULT=$(gen3-client download-single --profile=$PROFILE --guid=$id --no-prompt --download-path="$TMPPATH" 2>&1 1>/dev/null |  grep "503 Service Unavailable error has occurred")
    fi
    fi
  fi
done <<< "$(tail -n +2 $1)"

# move from temp path to final path
mv "$TMPPATH/*" "$FULLPATH/"

# wait # save thread faniciness
printf "files in $1 downloaded to:\n - $TMPPATH\n and moved to path:\n - $FULLPATH\n\t...adding to Galaxy...\n"

python3 main.py -a "$APIKEY" -e "$ENDPOINT" -p "$PORT" -s "$FULLPATH"
