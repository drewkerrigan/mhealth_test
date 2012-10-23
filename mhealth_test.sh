#!/bin/bash

source $(dirname $0)/lib/functions.sh

#----------------------------------------------------------------------
# initialize
#----------------------------------------------------------------------
CONFIG=""
DEBUG=""
TIME=""
WORKERS=""
OPERATION=""
RESULTSDIR=""

#----------------------------------------------------------------------
# populate values from command line options and validate
#----------------------------------------------------------------------
while getopts ":c:t:w:o:r:d" opt; do
  case $opt in
    c) CONFIG="${OPTARG}";;
    t) TIME="${OPTARG}";;
    w) WORKERS="${OPTARG}";;
    o) OPERATION="${OPTARG}";;
    r) RESULTSDIR="${OPTARG}";;
    d) DEBUG=TRUE;;
  esac
done

if [ "$CONFIG" == "" ] || 
   [ "$TIME" == "" ] ||
   [ "$WORKERS" == "" ] ||
   [ "$OPERATION" == "" ]
then
	print_usage $0
	exit 1
fi

duration=$TIME

print_debug "time= $duration seconds"
print_debug "number of workers= $WORKERS"
print_debug "operation= $OPERATION"

#----------------------------------------------------------------------
# include / create required files
#----------------------------------------------------------------------
source $(dirname $0)/$CONFIG
source $(dirname $0)/lib/driver.sh

if [ "$RESULTSDIR" == "" ]
then
	results_dir="./results/$TIME-s-$WORKERS-wr-$OPERATION"
else
	results_dir="$RESULTSDIR"
fi

if [ -e "$results_dir" ]
then
	echo "found $results_dir"
else
	echo "creating $results_dir"
	mkdir $results_dir
	mkdir $results_dir/backup
fi

#----------------------------------------------------------------------
# cleanup or leave old data
#----------------------------------------------------------------------
if [ -e "$results_dir/exception.txt" ]
then
	mv $results_dir/exception.txt{,.bak}
fi

if [ -e "$results_dir/stats.txt" ] && [ "$RESULTSDIR" == "" ]
then
	mv $results_dir/stats.txt{,.bak}
fi

#----------------------------------------------------------------------
# spawn worker threads if there is more than one
#----------------------------------------------------------------------
if [ "$WORKERS" -gt 1 ]
then
	if [ -e "$results_dir/worker_output1.txt" ]
	then
		echo "moving files to backup"
		mv $results_dir/worker_output* $results_dir/backup/
	fi
	
	d=""
	if [ "$DEBUG" == TRUE ]; then d="-d"; fi
	
	for (( i=1; i<=$WORKERS; i++ ))
	do
		print_debug "Starting worker $i"
		$0 -c $CONFIG -t $TIME -w 1 -o $OPERATION -r $results_dir $d &> $results_dir/worker_output$i.txt & 
	done
	
	echo "Check $results_dir/stats.txt for performance results"
	echo "Check $results_dir/worker_ouput1-$WORKERS.txt for individual worker information"

	sleep 1

	if [ -e "$results_dir/worker_output1.txt" ]
	then
		echo "Tailing $results_dir/worker_ouput1.txt to show progress, control-c to stop"
		tail -f $results_dir/worker_output1.txt
	fi
	
	exit 0
fi

#----------------------------------------------------------------------
# run the test
#----------------------------------------------------------------------
nowtime=$(date '+%s')
endtime=$((nowtime + duration))
re="^(.*)\|(.*)\|(.*)\|(.*)$"

print_debug "Nowtime: $nowtime, Endtime: $endtime "

echo "Starting test..."
while [ $nowtime -lt $endtime ]
do
	while read line; do
		[[ $line =~ $re ]] && current_email="${BASH_REMATCH[1]}" && current_uid="${BASH_REMATCH[2]}" && current_name="${BASH_REMATCH[3]}" && current_authtoken="${BASH_REMATCH[4]}"
		t=$( { time op_$OPERATION > /dev/null; } 2>&1 )
		echo $t >> $results_dir/stats.txt
	done < ./$inputfile

	if [ "$DEBUG" == TRUE ]; then break; fi

	timeleft=$((endtime - nowtime))

	echo -ne "    Time Left: $timeleft seconds\r"

	nowtime=$(date '+%s')
done

echo "    Time Left: 0 seconds, done!"
echo "Check $results_dir/stats.txt for performance results"

exit 0