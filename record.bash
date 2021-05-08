# Recorder Settings
REC_DEVICE='hw:CARD=CODEC,DEV=0'
DEVICE_IP='192.168.100.77'
REC_PREFIX='SiriusXM_'
REC_DIR='/home/pi/rec'

# Post Proccessing
# NOTE: You must provide your own metadata generation system that will write files in the fomat
#       .REC_DATE_TIME.txt next to the recordings - You should call this in sync with the rec start
#       no later then 1 min after its started. 
FFMPEG_OPTS='-vn -ar 44100 -ac 2 -b:a 192k'
FFMPEG_FORMAT='mp3'
BACKUP_DIR='/mnt/Music/SiriusXM'
UPLOAD_DIR='/mnt/Kanmi/Recordings'

# Notification System
ENABLE_NOTIFY=0
SYSID=''
WSSKey=''
APIServer=''

echo "Lizumi-Kanmi Radio/Audio Recorder for UNIX and Linux v8.1"

if [ "$1" = 'rec' ]; then
	if [ "$(ping ${DEVICE_IP} -c 1 > /dev/null && echo 'true' || echo 'false')" = 'true' ]; then
		if [ $ENABLE_NOTIFY = 1]; then
			timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
			--post-data message="Started Recording the Radio!&channel=info&event=undefined" ${APIServer}/endpoint/sendNotification &
		fi
		echo "Start Recording...."
		arecord -f cd -t raw -D "${REC_DEVICE}" | oggenc - -r -o ${REC_DIR}/${REC_PREFIX}_`date +"%b-%d-%Y_%H%M"`.ogg
	else
		if [ $ENABLE_NOTIFY = 1]; then
			timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
			--post-data message="ALARM! Radio is not conected to the craddle, I think?&channel=crit&event=undefined" ${APIServer}/endpoint/sendNotification &
		fi
		echo "ALARM! Radio is not conected to the craddle, I think?"
	fi
elif [ "$1" = 'stop' ]; then
	#PID=$(ps -ef --sort=start_time -U pi | grep arecord | grep -v grep | head -1 | awk '{print $2}')
	OPTIONS=''
	
	if [ "$2" = 'enc' ]; then
		echo "Encode Only, will not stop recorder"
		OPTIONS='-loglevel verbose -stats -hide_banner'
	else
		echo "Stop Recording..."
		if [ $ENABLE_NOTIFY = 1]; then
			timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
			--post-data message="Stopped Recording the Radio!&channel=info&event=undefined" ${APIServer}/endpoint/sendNotification &
		fi
		OPTIONS='-loglevel fatal -nostats -hide_banner'
		pkill -4 arecord
		sleep 90
	fi

	for file in $(find ${REC_DIR}/*.ogg -mmin +1); do
		SIDECAR=`cat "${REC_DIR}/.REC_$(basename $file .ogg | awk -F'__' '{print $2}').txt"`
		NEWNAME=$(echo $file | awk -F'_' '{print $1}')_${SIDECAR}_$(echo $file | awk -F'_' '{print $3}')_$(echo $file | awk -F'_' '{print $4}')
		echo "ENCODE: ${file} -> ${NEWNAME}"
		ffmpeg $OPTIONS -i "$file" ${FFMPEG_OPTS} "${REC_DIR}/$(basename $NEWNAME .ogg).${FFMPEG_FORMAT}"
		echo "Moving orginal recording file..."
		mv "${file}" "${BACKUP_DIR}/$(basename $NEWNAME .ogg).ogg"
		if [ $ENABLE_NOTIFY = 1]; then
			timeout 15 wget -qO- -d --header="X-WSS-Key: ${WSSKey}" --header="User-Agent: KanmiMessager/${SYSID}" \
			--post-data message="New Recording Completed from SiriusSM! - ${SIDECAR}&channel=message&event=undefined" ${APIServer}/endpoint/sendNotification &
		fi
	done

	echo 'Moving Remuxed Recordings...'
	for file in /home/pi/rec/*.${FFMPEG_FORMAT}; do
		# Prefixed with HOLD to prevent proccessing by Kanmi until network transfer is completed
		mv "${file}" "${UPLOAD_DIR}/HOLD-$(basename $file .${FFMPEG_FORMAT}).${FFMPEG_FORMAT}"
		mv "${UPLOAD_DIR}/HOLD-$(basename $file .${FFMPEG_FORMAT}).${FFMPEG_FORMAT}" "${UPLOAD_DIR}/$(basename $file .${FFMPEG_FORMAT}).${FFMPEG_FORMAT}"
	done
	echo 'Goodbye'
	sleep 15
else
	echo "Unknwon Option!"
	echo "  rec - Start Record"
	echo "  stop - Stop Recording and Encode"
	echo "  stop enc - Only Encode Recordings"
fi
