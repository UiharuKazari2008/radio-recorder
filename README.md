# Lizumi Audio Recorder

Includes the Audio Recorder, Metadata Writer, and the Start and Stop Screenrc Files

Example Homekit switch to toggle recorder
```
{
	"accessory": "Script2",
	"name": "Radio Recorder",
	"on": "bash /home/homebridge/newRecord.sh rec",
	"off": "bash /home/homebridge/newRecord.sh stop",
	"state": "timeout 3 bash /home/homebridge/newRecord.sh s",
	"on_value": "true",
	"unique_serial": "0000461"
}
```

This uses bash script to start and stop to prevent super long ssh commands in config files
```
HOST="pi@HOST"
#OPTS="-q -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=3 -i RSAKEY"
OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=3 -i RSAKEY"
if [ "$1" =  's' ]; then
	if [ $(timeout 2 ssh $HOST $OPTS 'ps ux | grep "[a]record" | wc -l' 2> /dev/null || echo "0") -gt 0 ]; then
		echo "true"
	else
		echo "false"
	fi
elif [ "$1" = 'rec' ]; then
	timeout 65 ssh $HOST $OPTS 'screen -dm -c /home/pi/.screenrc.rec';
elif [ "$1" = 'stop' ]; then
	timeout 65 ssh $HOST $OPTS 'screen -dm -c /home/pi/.screenrc.stop';
fi
```