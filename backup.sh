#!/bin/bash
# Michał Pomarański
# grupa nr 3

# writing a report showing start time, end time and quantity of data copied.
# offering a choice of tar or rsync.
# comparing the size of today's backup to yesterdays and sending the user an email of it changed significantly.
# provide source and destination as arguments

SOURCE=~/Dev/Studia/
DESTINATION=~/backup/Studia/

# check for the available space before doing the backup
available_space=$(df -k . --block-size=1K | sed -n '2p' | tr -s ' ' | cut -d ' ' -f 4)
backup_space_needed=$(du -sb $SOURCE | cut -f1)
if [[ "$backup_space_needed" -gt "$available_space" ]]
then
	zenity --error --text "There is not enough space left to do the backup of $SOURCE"
	exit
fi

# backup
echo "Making a backup of $SOURCE in ${DESTINATION}..."
date="$(date +'%A-%Y-%m-%d:%H:%M:%S')"
day_of_week="$(date +'%A')"
destination_directory="$DESTINATION"
full_destination="$destination_directory$(basename $DESTINATION)_$date"
mkdir -p $full_destination

# actual backup
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
