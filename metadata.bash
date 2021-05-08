DATE=`date +"%b-%d-%Y_%H%M"`

# Recorder Settings
REC_DIR='/home/pi/rec'

# Notification System
ENABLE_NOTIFY=0
SYSID=''
WSSKey=''
APIServer=''

# Channel Guide URLS
LINEUPURL52='https://www.siriusxm.com/channels/diplos-revolution'
LINEUPURL51='https://www.siriusxm.com/channels/bpm'
LINEUPURLEMO='https://www.siriusxm.com/channels/the-emo-project'
LINEUPURLHITS='https://www.siriusxm.com/channels/siriusxm-hits-1'
LINEUPURL2K='https://www.siriusxm.com/channels/pop2k'
LINEUPURLHEAT='https://www.siriusxm.com/channels/the-heat'
LINEUPURLRAW='https://www.siriusxm.com/channels/raw-dog-comedy'
LINEUPURLCHILL='https://www.siriusxm.com/channels/chill'

# Calender Event Service
# Location of Get Event, If your using a custom event name retriver you must follow 2 rules
# 1 - Must return NOEVENT somewhere to bypass otherwise ANY text returned will be filename
# 2 - Like aboce your program should ONLY return what will be the filename, you must be EXTREMELY SILENT!!, use a log file if you need it.
GETDATAJS='/home/pi/get-event/index.js'

# Lizumi SOS Active Channel Number Storage
CHNUMBER=""
CHANNELACT=$(timeout 15 curl -q "http://lizumi.blackheart.space:8055/get?item=channel")

if [[ ! -z "$CHANNELACT" ]]; then
	if [ "$CHANNELACT" == "diplo" ]; then
		LINEUPURL="$LINEUPURL52"
		CHNUMBER="CH52_"
	elif [ "$CHANNELACT" == "bpm" ]; then
		LINEUPURL="$LINEUPURL51"
		CHNUMBER="CH51_"
	elif [ "$CHANNELACT" == "chill" ]; then
		LINEUPURL="$LINEUPURLCHILL"
		CHNUMBER="CH53_"
	elif [ "$CHANNELACT" == "emo" ];then
		LINEUPURL="$LINEUPURLEMO"
		CHNUMBER="CH713_"
	elif [ "$CHANNELACT" == "hits" ];then
		LINEUPURL="$LINEUPURLHITS"
		CHNUMBER="CH2_"
	elif [ "$CHANNELACT" == "pop2k" ];then
		LINEUPURL="$LINEUPURL2K"
		CHNUMBER="CH10_"
	elif [ "$CHANNELACT" == "heat" ];then
		LINEUPURL="$LINEUPURLHEAT"
		CHNUMBER="CH46_"
	elif [ "$CHANNELACT" == "rawdog" ];then
		LINEUPURL="$LINEUPURLRAW"
		CHNUMBER="CH99_"
	else
		echo "FAILED to get the a valid radio channel, fallback to Diplo"
		LINEUPURL="$LINEUPURL52"
	fi
else
	echo "FAILED to get the current radio channel, fallback to Diplo"
	LINEUPURL="$LINEUPURL52"
fi

EVENTNAME=''
echo "The time is $DATE"
echo "Checking the event system for a event...(60 sec wait)"
if [[ "$1" != "now" ]]; then
	sleep 60
fi
RESULTDATA=$(node ${GETDATAJS})
if [[ "${RESULTDATA}" != *"NOEVENT"* ]]; then
	EVENTNAME=$(echo ${RESULTDATA} | sed -e 's/ /_/g' | sed 's/[^a-zA-Z0-9_]//g')
	if [ $ENABLE_NOTIFY = 1]; then
		timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
		--post-data message="Got Event for recording! - ${CHNUMBER}${EVENTNAME}&channel=info&event=undefined" ${APIServer}/endpoint/sendNotification &
	fi
else
	echo "Failed to get valid event data from ical, Will be getting metadata from $LINEUPURL"
	echo "Sleeping until its time to pull...."
	if [[ "$1" != "now" ]]; then
		sleep 900
	fi
	EVENTNAME=$(wget -q -O- $LINEUPURL | grep '<h3 class="lineup-name">' | head -1 | awk -F'e">' '{print $2}' | awk -F'</h' '{print $1}' | sed -e 's/ /_/g' | sed 's/[^a-zA-Z0-9_]//g')
	if [ $ENABLE_NOTIFY = 1]; then
		timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
		--post-data message="Did not get a event this recording! Using Channel metadata from SXM - ${CHNUMBER}${EVENTNAME}&channel=warn&event=undefined" ${APIServer}/endpoint/sendNotification &
	fi
fi

if [[ "$1" != "now" ]]; then
	echo "${CHNUMBER}${EVENTNAME}" > ${REC_DIR}/.REC_$DATE.txt
	echo "Current Show is : $(cat .REC_$DATE.txt)"
else
	echo $EVENTNAME
fi

