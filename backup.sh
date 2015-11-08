#!/bin/bash
# Michał Pomarański
# grupa nr 3

usage="$(basename "$0") [-h] [--help] [--remote-dest] [--remote-src] [--source] [--dest] -- Program robiący kopię zapasową podanego folderu.\n
Jako argumenty proszę podać folder, który ma zostać skopiowany oraz folder docelowy.
Program sprawdza czy na dysku jest wystarczająco dużo wolnego miejsca, w przeciwnym wypadku powiadamia o tym użytkownika.

Program może zostać uruchomiony jako zadanie cron (np.  0 22 * * * ./backup --source=folder --dest=folder2).
Dzięki temu, skrypt będzie uruchamiany raz dziennie. Skrypt nadpisuje kopię zrobioną tego samego dnia (zachowuje jedną kopię na jeden dzień tygodnia).

Przykład kopiowania z serwera zewnętrznego:
— ./backup.sh --remote-src localhost --source /home/some_folder --dest /home/backups
— ./backup.sh --remote-dest localhost --dest /home/backup --source /home/some_folder

Proszę używać pełnych ścieżek w przypadku serwerów zewnętrznych.

użycie:
    -h, --help → pomoc
	--source → folder, który ma zostać skopiowany.
	--dest → folder, do którego ma być zrobiony backup.
	--remote-src → adres serwera, na którym znajdziemy folder źródłowy
	--remote-dest → adres serwera, na którym znajdziemy folder docelowy
"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
source $DIR/helper.sh

is_remote=false
is_remote_src=false
is_remote_dest=false

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

remote_command_src=""
remote_command_dest=""
if $is_remote_src
then
	remote_command_src="ssh $remote_src"
fi

if $is_remote_dest
then
	remote_command_dest="ssh $remote_dest"
fi

echo $src

if ! $is_remote_src
then
	SOURCE="$(readlink -f $src)"
else
	SOURCE="$src"
fi

if ! $is_remote_dest
then
	DESTINATION="$(readlink -f $dest)/"
else
	DESTINATION="$dest/"
fi

echo "SOURCE $SOURCE"
echo "DESTINATION $DESTINATION"

if $is_remote_src
then
	if ($remote_command_src "test -d $src")
	then
		echo ""
	else
		printf "BŁĄD! Katalog źródłowy nie istnieje." >&2
		exit 1
	fi
else
	if [ ! -d "$SOURCE"  ]
	then
		printf "BŁĄD! Katalog źródłowy nie istnieje." >&2
		exit 1
	fi
fi

start_time_nano=$(get_time_nanoseconds)
start_time=$(get_time)
echo "Rozpoczęcie kopiowania o godz. $start_time"

# backup
echo "Tworzenie kopii zapasowej $SOURCE w ${DESTINATION}..."
date="$(date +'%A-%Y-%m-%d:%H:%M:%S')"
day_of_week="$(date +'%A')"
destination_directory="$DESTINATION"
full_destination="$destination_directory$(basename $DESTINATION)_$date"

# tworzenie katalogu docelowego jeżeli nie istnieje
$remote_command_dest mkdir -p $full_destination

# check for the available space before doing the backup
backup_available_space=$($remote_command_dest df $DESTINATION | sed -n '2p' | awk '{print $4}')
backup_space_needed=$($remote_command_src du -sb $SOURCE | cut -f1)
backup_space_in_mb=$($remote_command_src du -sb $SOURCE --block-size=1M | cut -f1)
if [[ "$backup_space_needed" -gt "$backup_available_space" ]]
then
	zenity --error --text "Na dysku nie ma wystarczającej ilości wolnego miejsca w $SOURCE"
	exit
fi

full_destination_rsync=$full_destination

if $is_remote_src
then
	SOURCE="${remote_src}:$SOURCE"
fi

if $is_remote_dest
then
	full_destination_rsync="$remote_dest:$full_destination"
fi

pattern="$($remote_command_dest basename $DESTINATION)_$day_of_week*"
$remote_command_dest find $dest -path "*$pattern*" -delete # >> /dev/null 2>&1
$remote_command_dest find $dest -type d -name "$pattern" -delete # >> /dev/null 2>&1

# actual backup
rsync -ra --delete $SOURCE $full_destination_rsync --quiet
echo "Kopia zapasowa zapisana w $full_destination" 

end_time_nano=$(get_time_nanoseconds)
end_time=$(get_time)
elapsed=`echo "scale=8; $(($end_time_nano-$start_time_nano)) / 1000000000" | bc`
echo "Tworzenie kopii zakończone. Czas zakończenia kopiowania: $end_time. Czas kopiowania:  ${elapsed} sekund."
echo "Skopiowano $backup_space_in_mb MB"
