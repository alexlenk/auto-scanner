#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "Working dir: $DIR"

sh -c "echo 'MONITOR: Setting Restart Timer: 72000 Seconds';sleep 72000; echo 'MONITOR: Restarting.'; restart" &

log=""
last_time=0
merge=false
time=$(date +%s)
start=true
update_curr_files=true
folder=$1
if [ -d "/volumes/STICK" ]; then
    tmp_folder="/volumes/STICK"
else
    tmp_folder="/tmp"
fi

echo "MONITOR ($folder): Using temp folder '$tmp_folder'"

echo "MONITOR ($folder): Starting ... waiting for folder to become available ..."
while [[ ! -d $folder ]]; do
    sleep 0.5
done

if [ -f "$tmp_folder/last_files${folder//[\/]/-}" ]; then
    echo "MONITOR ($folder): Loading cached current file list ..."
    last_files=$(cat $tmp_folder/last_files${folder//[\/]/-} | tr " " "\n")
else
    echo "MONITOR ($folder): File $tmp_folder/last_files${folder//[\/]/-} does not exist"
    echo "MONITOR ($folder): Initializing current file list ..."
    if [ -d "$folder" ]; then
        last_files=$(ls -1 $folder | tr " " "\n")
    fi
fi

echo $last_files

if [ ! -f /tmp/.env ]; then
    echo "Copy .env File"
    cp /media/SCANNER/.env /tmp/.env
fi
if [ "$SMTP_SERVER" = "" ]; then
    export $(cat /tmp/.env | xargs)
fi

echo "MONITOR ($folder): Starting monitoring ..."

while true; do
    if [ -d "$folder" ]; then
        sleep 5
    fi
    if [ -d "$folder" ] || [ "$last_files" = ""  ]; then
        curr_files=$(ls -1 $folder | tr " " "\n")
        new_files_list=`diff <(echo "$last_files") <(echo "$curr_files") | grep ">" | cut -c3-`
        new_files=()
        IFS_SAV=$IFS
        IFS=$'\n'
        for item in $new_files_list; do
            new_files+=( "$item" )
        done

        if [ "${#new_files[@]}" -gt "50" ]; then
            echo "MONITOR ($folder): Error while loading. Resetting last file list."
            echo "MONITOR ($folder): Last uploaded file: $(cat $tmp_folder/last_uploaded_file${folder//[\/]/-})"
            new_files=()
            last_files=$(ls -1 $folder | tr " " "\n")
            echo $last_files > $tmp_folder/last_files${folder//[\/]/-}
        fi
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
                if [ "$diff" -lt "22" -a "$diff" -ge "0" -a "${#merge_list[@]}" -lt "6" ]; then
                    echo "MONITOR ($folder): Adding file to merge list: ${new_file}"
                    merge_list+=( "${new_file}" )
                    #echo "Merge List: ${merge_list[@]}"
                else
                    last_file=${new_files[((i-1))]}
                    last_file_date=$(stat -c %Y "$folder/$last_file")

                    if [ "$new_file_date" = "" ]; then new_file_date=0; fi
                    if [ "$last_file_date" = "" ]; then last_file_date=0; fi
                    ((diff=${new_file_date}-${last_file_date}))
                    #echo "Difference to last file: $diff"
                    if [ "$diff" -lt "22" ]; then
                        echo "MONITOR ($folder): Adding last file to merge list: ${new_file}"
                    fi
                    merge_list+=( "${new_file}" )
                    echo ${new_file} > $tmp_folder/last_uploaded_file${folder//[\/]/-}
                    $DIR/upload.sh ${merge_list[@]} &
                    pid=$!

                    echo "MONITOR ($folder): Uploading (PID $pid): ${merge_list[@]}"
                    merge_list=()
                    last_files=$curr_files
                    echo $last_files > $tmp_folder/last_files${folder//[\/]/-}
                fi
            fi
        done
    #else
        #echo "no Files"
    fi
done
