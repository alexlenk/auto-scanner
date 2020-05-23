#!/bin/bash

files=("$@")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

filename=$(basename -- "${files[0]}")
echo "Filename: $filename"
extension="${filename##*.}"
echo "extension: $extension"
extension_small=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
echo "extension_small: $extension_small"


if [ "$extension_small" = "jpg" ]; then
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
    mogrify -normalize -level 10%,83% -sharpen 0x1 -enhance /tmp/*.$extension
    convert ${merge_files[@]} /tmp/$file
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
echo "" | s-nail -v -s "Autoscan" -S tls-rand-file=/tmp/tls-rnd -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=$SMTP_SERVER -S smtp-auth-user=$SMTP_USER -S from=$FROM_MAIL -S smtp-auth-password=$SMTP_PASS -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -a /tmp/$file $TO_MAIL >> /tmp/auto-scanner-upload.log


echo "UPLOAD<$$>: Upload done: $upload_string; Deleting temp files."

if [ ${#files[@]} -gt 1 ]; then
    rm ${merge_files[@]} /tmp/$file
else
    rm /tmp/${files[0]}
fi