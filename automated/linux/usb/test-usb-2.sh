#!/bin/bash
TEST_CASE_NAME=$(basename "$0" .sh)

PATH_DEV="/dev/sda1"
PATH_MOUNT="/mnt/lava_usb_test"

if lsblk | grep sda1;
then
    #Flash disk will be formatted
    if mke2fs -F -t ext4 "$PATH_DEV";
    then
        if [ ! -d "$PATH_MOUNT" ]
        then
            mkdir "$PATH_MOUNT"
        fi

        if mount "$PATH_DEV" "$PATH_MOUNT";
        then
            dd if=/dev/urandom of=/tmp/testfile bs=512 count=1k
            md5sum /tmp/testfile > md5

            cp /tmp/testfile "$PATH_MOUNT"
            cp md5 "$PATH_MOUNT"
            
            if cd "$PATH_MOUNT" && md5sum -c md5;
            then
                lava-test-case "$TEST_CASE_NAME-md5sum" --result pass
            else
                lava-test-case "$TEST_CASE_NAME-md5sum" --result fail
            fi
        else
            lava-test-case "$TEST_CASE_NAME-mount" --result fail
        fi
        cd /
        umount "$PATH_MOUNT"
        rm -r "$PATH_MOUNT"
    else
        lava-test-case "$TEST_CASE_NAME-format" --result fail
    fi
else
    lava-test-case "$TEST_CASE_NAME-flash-disk" --result fail
fi
