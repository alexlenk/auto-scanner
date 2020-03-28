#!/bin/bash

#log=()
log=""
last_time=0
merge=false
time=$(date +%s)
start=true

if [ -d "/volumes/SCANNER/DCIM/200DOC" ]; then
    last_files=$(ls /volumes/SCANNER/DCIM/200DOC)
fi

pipe=/tmp/scannerpipe

trap "rm -f $pipe" EXIT

if [[ ! -p $pipe ]]; then
    mkfifo $pipe
fi

#inotifywait -m /volumes/ -e create -e moved_to -e delete | 
#while read dir action file; do
while true; do
    #if [ "$file" = "SCANNER" -o "$file" = "6462-3834" ]; then 
    if read file action <$pipe; then
        time=$(date +%s)
        ((time_diff=time-last_time))

        sleep 0.2
        if [ "$action" = "CREATE,ISDIR" ]; then
            # Started
            if [ "$last_files" == "" ]; then
                echo "MONITOR: Resetting Last Files"
                last_files=$(ls /volumes/SCANNER/DCIM/200DOC)
            fi

            if [ "$backlog_time" != "" ]; then  
                backlog_time=""
                backlog_action=""
                skip=false

                last_file=$pdffile

                #TODO: if more than one, it should be a merging case, check merge variable
                if [ -d /volumes/SCANNER/DCIM/200DOC ]; then
                    pdffile=`diff <(echo "$last_files") <(echo "$(ls /volumes/SCANNER/DCIM/200DOC)") | grep ">" | cut -c3-`
                    echo "MONITOR: New File in Folder: $pdffile"
                    
                    time_last=$time
                    if [ "$merge" == "true" ]; then
                        if [ "${#merge_files[@]}" -eq "0" ]; then
                            echo "MONITOR: Creating merge list with $last_file"
                            merge_files=( $last_file )
                        fi
                        echo "MONITOR: Adding file to merge list: $pdffile"
                        merge_files+=( $pdffile )
                    else
                        merge_files=( $pdffile )
                    fi
                    
                    /tmp/upload.sh ${merge_files[@]} &
                    pid=$!

                    echo "MONITOR: Uploading (PID $pid): ${merge_files[@]}"
                else
                    echo "MONITOR: Skipping upload - New Scan in Progress"
                    skip=true
                fi
            fi

            if [ "$skip" = "false" ]; then
                echo "MONITOR: Updating Last Files"
                last_files=$(ls /volumes/SCANNER/DCIM/200DOC)
            fi
            last_time=$(date +%s)
        else
            if [ "$time_diff" -le "3" -a "$start" != "true" ]; then
                #killall upload.sh
                kill -9 $pid
                merge=true
                echo "MONITOR: Upload stopped (PID: $pid)"
            else
                if [ "$merge" == "true" ]; then
                    echo "MONITOR: Ending Previous Merging Process"
                    merge=false
                fi

                echo "MONITOR: Resetting merge list"
                merge_files=()
                last_file=""
            fi

            backlog_time=$time
            backlog_action=$action
        fi
        
        start=false
    fi
done
