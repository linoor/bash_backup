#!/bin/bash
# Michał Pomarański
# grupa nr 3

usage="$(basename "$0") [-h] [--help] [--source] [--dest] -- Program robiący kopię zapasową podanego folderu.\n
Jako argumenty proszę podać folder, który ma zostać skopiowany oraz folder docelowy.
Program sprawdza czy na dysku jest wystarczająco dużo wolnego miejsca, w przeciwnym wypadku powiadamia o tym użytkownika.

Program może zostać uruchomiony jako zadanie cron (np.  0 22 * * * ./backup --source=folder --dest=folder2).
Dzięki temu, skrypt będzie uruchamiany raz dziennie. Skrypt nadpisuje kopię zrobioną tego samego dnia (zachowuje jedną kopię na jeden dzień tygodnia).

użycie:
    -h, --help - pomoc
	--source - folder, który ma zostać skopiowany.
	--dest - folder, do którego ma być zrobiony backup.
"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
source $DIR/helper.sh

option="$1"
for option in "$@"
do
	case "$option" in
	--help) printf "$usage"
		exit
		;;
	-h) printf "$usage"
		exit
		;;
	--h) printf "$usage"
		exit
		;;
	--remote-src)
		is_remote=true
		is_remote_src=true
		remote_src="$(echo "$@" | grep -Po "\-\-remote-src [^\s]+" | grep -Po "(?<=\s).+")"
		;;
	--remote-dest)
		is_remote=true
		is_remote_dest=true
		remote_dest="$(echo "$@" | grep -Po "\-\-remote-dest [^\s]+" | grep -Po "(?<=\s).+")"
		;;
	--source*) 
		src="$(echo "$@" | grep -Po "\-\-source [^\s]+" | grep -Po "(?<=\s).+")"
		;;
	--dest*)
		dest="$(echo "$@" | grep -Po "\-\-dest [^\s]+" | grep -Po "(?<=\s).+")"
		;;
	-*) printf "Niepoprawne argumenty\n\n" >&2
	   printf "$usage" >&2
	   exit 1
	   ;;
	esac
done

SOURCE="$(readlink -f $src)"
DESTINATION="$(readlink -f $dest)/"

if [ ! -d "$SOURCE"  ]
then
	printf "BŁĄD! Katalog źródłowy nie istnieje." >&2
	exit 1
fi

start_time_nano=$(get_time_nanoseconds)
start_time=$(get_time)
echo "Rozpoczęcie kopiowania o godz. $start_time"

# check for the available space before doing the backup
available_space=$(df -k . --block-size=1K | sed -n '2p' | tr -s ' ' | cut -d ' ' -f 4)
backup_space_needed=$(du -sb $SOURCE | cut -f1)
backup_space_in_mb=$(du -sb $SOURCE --block-size=1M | cut -f1)
if [[ "$backup_space_needed" -gt "$available_space" ]]
then
	zenity --error --text "Na dysku nie ma wystarczającej ilości wolnego miejsca w $SOURCE"
	exit
fi

# backup
echo "Tworzenie kopii zapasowej $SOURCE w ${DESTINATION}..."
date="$(date +'%A-%Y-%m-%d:%H:%M:%S')"
day_of_week="$(date +'%A')"
destination_directory="$DESTINATION"
full_destination="$destination_directory$(basename $DESTINATION)_$date"
mkdir -p $full_destination

# actual backup
rsync -ra --delete $SOURCE $full_destination
echo "Kopia zapasowa zapisana w $full_destination" 

# remove all of the other backups made on the same day (except the one made now)
for i in "$destination_directory$(basename $DESTINATION)_$day_of_week*"; do
	for file in $i; do
		if [[ $file != "$full_destination" ]]
		then
			rm -r $file
		fi
	done
done

end_time_nano=$(get_time_nanoseconds)
end_time=$(get_time)
elapsed=`echo "scale=8; $(($end_time_nano-$start_time_nano)) / 1000000000" | bc`
echo "Tworzenie kopii zakończone. Czas zakończenia kopiowania: $end_time. Czas kopiowania:  ${elapsed} sekund."
echo "Skopiowano $backup_space_in_mb MB"
