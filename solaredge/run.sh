#!/usr/bin/with-contenv bashio

$(bashio::log.notice "Welcome to Solaredge Data Capture!")

capture_path="/data/traffic/"
se_logger_service="/opt/se-logger/se-logger-service.sh"

#Create capture path
mkdir -p $capture_path

#Write the SE-Logger's config file out
$(bashio::log.info "Writing config file...")
cat > /opt/se-logger/config.py <<- EOF
#!/usr/bin/env python
inverter_private_key = b'$(bashio::config 'inverter_private_key')'
db_user = "$(bashio::config 'database_user')"
db_pass = "$(bashio::config 'database_password')"
db_name = "$(bashio::config 'database_name')"
db_host = "$(bashio::config 'database_host')"
db_port = $(bashio::config 'database_port')
EOF

#Write the SE-Logger's daemon file settings
$(bashio::log.info "Writing service file...")
cat > $se_logger_service <<- EOF
#!/usr/bin/with-contenv bashio
# SETTINGS
interface=$(bashio::config 'capture_interface')
filter=tcp
captdir=$capture_path
prefix=solaredge-
EOF

#Write the SE-Logger's daemon file code
cat >> $se_logger_service << "EOF"

$(bashio::log.info "Start capturing traffic..")

#Recycle log files..
rm -f ${captdir}../tcpdump.log
rm -f ${captdir}../liveupdate.log

#wait for the time to get set
while [ `date -u +%Y` == "1970" ]
do
	$(bashio::log.info "Waiting for correct time..")
	sleep 1
done

#/usr/bin/python3 -u /opt/se-logger/liveupdate2.py /opt/se-logger/solaredge-20200420210737.pcap
#exit

/usr/bin/stdbuf -i0 -o0 -e0 /usr/sbin/tcpdump -i $interface -U -w - ${filter} | \
	tee $captdir$prefix`date -u +%Y%m%d%H%M%S`.pcap | \
	/usr/bin/python3 -u /opt/se-logger/liveupdate2.py - 
EOF

#Give access permissions
chmod a+x $se_logger_service

#Write RemoveMeasurements Script
# $(bashio::log.info "Writing helper scripts...")
# cat >> $se_logger_service << "EOF"
# 	#!/bin/bash

# 	host=localhost
# 	db='home_assistant'

# 	measurements=$1
# 	measurements=($(influx --host $host --execute 'show measurements' --database=$db | grep "$1"))

# 	if (( ${#measurements[@]} ))
# 	then

# 		echo "Found following measurements: "
# 		echo

# 		for m in ${measurements[*]}
# 		do
# 			echo " - $m"
# 		done

# 		echo
# 		read -p "Are you sure you want to drop these from database? (y/N)" -n 1 -r
# 		echo
# 		if [[ $REPLY =~ ^[Yy]$ ]]
# 		then
# 			for m in ${measurements[*]}
# 			do
# 				echo "Dropping $m..."
# 				influx --host $host --database=$db --execute "drop measurement \"$m\";"
# 			done
# 		else
# 			echo "OK, leaving it alone..."
# 		fi

# 	else
# 		echo "Did not found any measurements matching your query. Exiting."
# 	fi
# 	EOF

# Create a function to kill the logger every midnight (when the inverters are idle)
# The first argument is the PID to kill
killOnMidnight() {
	today=`date -u +%Y%m%d`
	while true
	do
		# echo "Waiting for date to flip.. $today" 
		if [ `date -u +%Y%m%d` != $today ]
		then
			$(bashio::log.info "Past midnight. Stopping $1")
			kill $1 2>/dev/null
			today=`date -u +%Y%m%d`
			return
		fi
		sleep 300
	done
}

while true
do
	#Start capturing in the background and save PID
	$se_logger_service & pid="$!"
	killOnMidnight $pid &
	
	# Wait for the script to finish or terminated..
	wait $pid || true
	$(bashio::log.info "Restarting logger..")
done
