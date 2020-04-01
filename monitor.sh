#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "Working dir: $DIR"

log=""
last_time=0
merge=false
time=$(date +%s)
start=true
update_curr_files=true
folder=/volumes/SCANNER/DCIM/200DOC

if [ -f "/tmp/last_files" ]; then
    echo "MONITOR: Loading cached current file list ..."
    last_files=$(cat /tmp/last_files)
else
    echo "MONITOR: Starting ... waiting for folder to become available ..."
    while [[ ! -d $folder ]]; do
        sleep 0.5
    done

    echo "MONITOR: Initializing current file list ..."
    if [ -d "$folder" ]; then
        last_files=$(ls $folder)
        #last_files=""
    fi
fi

if [ ! -f $DIR/.env ]; then
    echo "Copy .env File"
    cp /media/SCANNER/.env $DIR
fi
if [ "$SMTP_SERVER" = "" ]; then
    export $(cat $DIR/.env | xargs)
fi

echo "MONITOR: Starting monitoring ..."

while true; do
    if [ -d "$folder" ]; then
        sleep 5
    fi
    if [ -d "$folder" ]; then
        #curr_files=$(ls -l --time-style=+%s /volumes/SCANNER/DCIM/200DOC | awk OFS='\t' '{print $7 ";" $6}')
        curr_files=$(ls -1 $folder)
        new_files_list=`diff <(echo "$last_files") <(echo "$curr_files") | grep ">" | cut -c3-`
        new_files=()
        IFS_SAV=$IFS
        IFS=$'\n'
        for item in $new_files_list; do
            #echo $new_files_list
            #echo "New Item: $item"
            new_files+=( "$item" )
        done
        #IFS=$IFS_SAV
    else
        sleep 5
    fi

    if [ "${#new_files[@]}" -gt "0" -a -d "$folder" ]; then
        #echo New Files: ${new_files[*]}
        merge_list=()
        for ((i=0;i<${#new_files[@]};i++)); do
            new_file=${new_files[i]}
            if [ "$new_file" != "" ]; then
                new_file_date=$(stat -c %Y "$folder/$new_file")
                #echo File: ${new_file}

                next_file=${new_files[((i+1))]}
                #echo Nextfile: $next_file
                next_file_date=$(stat -c %Y "$folder/$next_file")
                if [ "$new_file_date" = "" ]; then new_file_date=0; fi
                if [ "$next_file_date" = "" ]; then next_file_date=0; fi
                ((diff=$next_file_date-${new_file_date}))
                #echo "Difference to next file: $diff"
                if [ "$diff" -lt "25" -a "$diff" -ge "0" ]; then
                    echo "MONITOR: Adding file to merge list: ${new_file}"
                    merge_list+=( "${new_file}" )
                    #echo "Merge List: ${merge_list[@]}"
                else
                    last_file=${new_files[((i-1))]}
                    last_file_date=$(stat -c %Y "$folder/$last_file")

                    if [ "$new_file_date" = "" ]; then new_file_date=0; fi
                    if [ "$last_file_date" = "" ]; then last_file_date=0; fi
                    ((diff=${new_file_date}-${last_file_date}))
                    #echo "Difference to last file: $diff"
                    if [ "$diff" -lt "25" ]; then
                        echo "MONITOR: Adding last file to merge list: ${new_file}"
                    fi
                    merge_list+=( "${new_file}" )
                    $DIR/upload.sh ${merge_list[@]} &
                    pid=$!

                    echo "MONITOR: Uploading (PID $pid): ${merge_list[@]}"
                    merge_list=()
                    last_files=$curr_files
                    echo $last_files > /tmp/last_files
                fi
            fi
        done
    #else
        #echo "no Files"
    fi
done
