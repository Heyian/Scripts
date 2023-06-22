#!/bin/bash

RESULT=$DUPLICATI__PARSED_RESULT 

if [ "$RESULT" == "Success" ]
then
ERRORC=0
else
ERRORC="fail"
fi
curl --retry 3 https://hc-ping.com/a042ca1f-476d-4351-9d16-7d4201fec4ec/"$ERRORC"
#echo "$ERRORC" > /var/tmp/dupli.log
exit 0
