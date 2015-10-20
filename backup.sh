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
day_of_week="$(date +'%A')"
destination_directory="$DESTINATION"
full_destination="$destination_directory$(basename $DESTINATION)_$date"
mkdir -p $full_destination

rsync -ra --delete $SOURCE $full_destination
echo "Backup saved in $full_destination" 

# remove all of the other backups made on the same day (except the one made now)
for i in "$destination_directory$(basename $DESTINATION)_$day_of_week*"; do
	for file in $i; do
		if [[ $file != "$full_destination" ]]
		then
			rm -r $file
		fi
	done
done

echo "Backup finished."
