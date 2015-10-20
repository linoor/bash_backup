#!/bin/bash
# Michał Pomarański
# grupa nr 3

# A script doing a backup of a given folder, keeping up to 7 backups (for each day of the week) as history.
# Using rsync to perform the backup
# checking for disk space before attempting the backup.
# sending an email alert if there's no sufficient disk space.
# writing a report showing start time, end time and quantity of data copied.
# offering a choice of tar or rsync.
# comparing the size of today's backup to yesterdays and sending the user an email of it changed significantly.

SOURCE=~/Dev/Studia/
DESTINATION=~/backup/Studia/

# backup
echo "Making a backup of $SOURCE in ${DESTINATION}..."
date="$(date +'%A-%Y-%m-%d:%H:%M:%S')"
destination_directory="$DESTINATION"
destination_with_date="$destination_directory$(basename $DESTINATION)_$date"
echo $destination_with_date
mkdir -p $destination_with_date

rsync -ra --delete $SOURCE $destination_with_date
echo "Backup saved in $destination_with_date" 
echo "Backup finished."
