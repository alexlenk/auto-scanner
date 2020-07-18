#!/bin/bash

files=("$@")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
START_TIME=$(date +%Y-%m-%d_%H-%M-%S)

if [ -d "/volumes/STICK" ]; then
    tmp_folder="/volumes/STICK"
else
    tmp_folder="/tmp"
fi

echo "UPLOAD<$$>: Starting Upload ... $(date +%Y-%m-%d_%H-%M-%S)"

filename=$(basename -- "${files[0]}")
echo "Filename: $filename"
extension="${filename##*.}"
echo "extension: $extension"
extension_small=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
echo "extension_small: $extension_small"

if [ "$ERROR_REPLAY" = "TRUE" ]; then
    file_dir=$tmp_folder/error_files
elif [ "$extension_small" = "jpg" ]; then
    file_dir=/volumes/SCANNER/DCIM/100PHOTO
else
    file_dir=/volumes/SCANNER/DCIM/200DOC
fi

if [ ! -f /tmp/.env ]; then
    echo "Copy .env File"
    cp /media/SCANNER/.env /tmp/.env
fi

if [ "$SMTP_SERVER" = "" ]; then
    export $(cat /tmp/.env | xargs)
fi

if [ ! -f "/tmp/tls-rnd" ]; then
    dd if=/dev/urandom of=/tmp/tls-rnd bs=1024 count=1
fi

merge_files=()
for i in "${files[@]}"; do
    if [ -f /tmp/$i ]; then
        file_size1=`stat -c %s "$file_dir/$i"`
    else
        file_size1=1000000000
    fi
    
    if [ -f /tmp/$i ]; then
        file_size2=`stat -c %s "$file_dir/$i"`
    else
        file_size2=0
    fi

    if [ ! -f /tmp/$i ] || [ "$file_size1" -ne "$file_size2" ]; then
        cp $file_dir/$i /tmp/$i
        echo "UPLOAD<$$>: Copied $i"
    fi
    merge_files+=( "/tmp/$i" )
done

sleep 10

if [ "$extension_small" = "jpg" ]; then
    file="${filename%.*}-merged.pdf"
    #mogrify -shave 10 -bordercolor 'rgb(216,194,111)' -border 5 -fuzz 20% -trim +repage -bordercolor white -border 10 -deskew 80% -normalize -level 10%,81% -sharpen 0x1 -enhance /tmp/*.$extension
    #mogrify -normalize -level 10%,81% -sharpen 0x1 -enhance -bordercolor 'rgb(216,194,111)' -border 10 -fuzz 20% -fill white -draw "color 2,2 floodfill" +repage -deskew 80% -shave 20x20 -bordercolor black -border 5 -fill white -draw "color 2,2 floodfill" -bordercolor white -border 5 -quiet /tmp/*.$extension

    for list_file in "${merge_files[@]}"; do
        echo "UPLOAD<$$>: Enhancing $list_file"
        convert $list_file $list_file
        convert $list_file -normalize -level 10%,81% -sharpen 0x1 -enhance -bordercolor 'rgb(216,194,111)' -border 10 -fuzz 20% -fill white -draw "color 2,2 floodfill" +repage -deskew 80% -shave 20x20 -bordercolor black -border 5 -fill white -draw "color 2,2 floodfill" -bordercolor white -border 5 -quiet $list_file
    done
    echo "UPLOAD<$$>: Converting '${merge_files[@]}' to '/tmp/$file'"
    convert ${merge_files[@]} /tmp/$file
    echo "UPLOAD<$$>: Conversion done."
    upload_string="$file"
else
    if [ ${#files[@]} -gt 1 ]; then
        file="${files[0]}-merged.pdf"
        pdfunite ${merge_files[@]} /tmp/$file
        upload_string="$file (${files[@]})"
    else
        file=${files[0]}
        upload_string="$file"
    fi
fi

echo "UPLOAD<$$>: Uploading: $upload_string"
echo "" | s-nail -v -s "Autoscan" -S tls-rand-file=/tmp/tls-rnd -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=$SMTP_SERVER -S smtp-auth-user=$SMTP_USER -S from=$FROM_MAIL -S smtp-auth-password=$SMTP_PASS -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -a /tmp/$file $TO_MAIL

if [ "$?" -eq "0" ]; then
    echo "UPLOAD<$$>: Upload done: $upload_string."
else
    if [ ! -d $tmp_folder/error_files ]; then
        mkdir $tmp_folder/error_files
    fi

    if [ ${#files[@]} -gt 1 ]; then
        cp ${merge_files[@]} /tmp/$file $tmp_folder/error_files/
        echo ${files[@]} >> $tmp_folder/error_backlog
    else
        cp /tmp/${files[0]} /tmp/$file $tmp_folder/error_files/
        echo ${files[0]} >> $tmp_folder/error_backlog
    fi
    #cp /tmp/auto-scanner-upload.log $tmp_folder/error_files/$file-auto-scanner-upload.log
    cp /tmp/auto-scanner.log $tmp_folder/error_files/$file-auto-scanner.log
    tail -n 500 /tmp/auto-scanner.log | s-nail -v -s "Autoscan Error" -S tls-rand-file=/tmp/tls-rnd -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=$SMTP_SERVER -S smtp-auth-user=$SMTP_USER -S from=$FROM_MAIL -S smtp-auth-password=$SMTP_PASS -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb $TO_MAIL_ERROR
    echo "UPLOAD<$$>: Upload failed: $upload_string."
fi

echo "UPLOAD<$$>: Ending Upload ... $(date +%Y-%m-%d_%H-%M-%S)"

echo "UPLOAD<$$>: Deleting temp files."
if [ ${#files[@]} -gt 1 ]; then
    rm ${merge_files[@]} /tmp/$file
else
    rm /tmp/${files[0]} /tmp/$file
fi