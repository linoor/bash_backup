#!/bin/bash
# Michał Pomarański
# grupa nr 3

# A script doing a backup of /home folder, keeping up to 7 backups (for each day of the week) as history.
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
day_of_week="$(date +'%A')"
destination_with_week="${DESTINATION}$(basename $DESTINATION)_${day_of_week}"
echo $destination_with_week
mkdir -p $destination_with_week

rsync -ra --delete $SOURCE $destination_with_week
echo "Backup finished."
