#!/bin/bash

UPLOAD="$1"
FTPSERVER=uploads.androidfilehost.com
LOGIN=
PASSWORD=

if [ "$UPLOAD" == "both" ]
  then
  echo "Starting adb server!"; adb start-server > /dev/null
  NOT_PRESENT="List of devices attached"
  ADB_FOUND=`adb devices | tail -2 | head -1 | cut -f 1 | sed 's/ *$//g'`

  if [[ ${ADB_FOUND} == ${NOT_PRESENT} ]]; then
  echo "Android device wasn't found"
  else
  echo "Android device found, copying build to device"
  adb push $OUT/AOSiP-*.zip /sdcard/AOSiP/
  fi

  lftp <<INPUT_END
  open sftp://$FTPSERVER
  set sftp:auto-confirm yes
  set ssl:verify-certificate no
  user $LOGIN $PASSWORD
  mput $OUT/AOSiP-*.zip
INPUT_END

  echo="Build successfuly transfered to android file host"

fi

if [ "$UPLOAD" == "adb" ]; then {
echo "Starting adb server!"; adb start-server > /dev/null
NOT_PRESENT="List of devices attached"
ADB_FOUND=`adb devices | tail -2 | head -1 | cut -f 1 | sed 's/ *$//g'`

  if [[ ${ADB_FOUND} == ${NOT_PRESENT} ]]; then
  echo "Android device wasn't found"
  else
  echo "Android device found, copying build to device"
  adb push $OUT/AOSiP-*.zip /sdcard/AOSiP/
  fi
  }
  fi 

  if [ "$UPLOAD" == "afh" ]
  then
  lftp <<INPUT_END
  open sftp://$FTPSERVER
  set sftp:auto-confirm yes
  set ssl:verify-certificate no
  user $LOGIN $PASSWORD
  mput $OUT/AOSiP-*.zip
INPUT_END

  echo="Build successfuly transfered to android file host"

fi

  adb kill-server > /dev/null
