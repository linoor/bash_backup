#!/bin/tcsh
# Michał Pomarański
# grupa nr 3

set usage =  "`basename $0` -h --help --source --dest -- Program robiący kopię zapasową podanego folderu.\n\
Jako argumenty proszę podać folder, który ma zostać skopiowany oraz folder docelowy.\n\
Program sprawdza czy na dysku jest wystarczająco dużo wolnego miejsca, w przeciwnym wypadku powiadamia o tym użytkownika.\n\
\n\
Program może zostać uruchomiony jako zadanie cron (np.  0 22 7 3 3 ./backup --source=folder --dest=folder2).\n\
Dzięki temu, skrypt będzie uruchamiany raz dziennie. Skrypt nadpisuje kopię zrobioną tego samego dnia (zachowuje jedną kopię na jeden dzień tygodnia).\n\
\n\
użycie:\n\
    -h, --help - pomoc\n\
	--source - folder, który ma zostać skopiowany.\n\
	--dest - folder, do którego ma być zrobiony backup.\n\
"

set src = ""
set dest = ""
foreach option ( $argv )
	switch ($option)
		case "--help":
			echo $usage
			exit 1
			breaksw
		case "--h":
			echo $usage
			exit 1
			breaksw
		case "-h":
			echo $usage
			exit 1
			breaksw
		case "--source*":
			set src = `echo $argv | grep -Po "\-\-source [^\s]+" | grep -Po "(?<=\s).+"`
			breaksw
		case "--dest*":
			set dest = `echo $argv | grep -Po "\-\-dest [^\s]+" | grep -Po "(?<=\s).+"`
			breaksw
		case "-*":
			echo "Niepoprawne argumenty\n\n"
			echo $usage
			exit 1
			breaksw
	endsw
end

set SOURCE="`readlink -f $src`"
set DESTINATION="`readlink -f $dest`/"

if ( ! -d "$SOURCE"  ) then
	printf "BŁĄD! Katalog źródłowy nie istnieje."
	exit 1
endif

set start_time_nano=`date +%s%N`
set start_time=`date +%H:%M:%S:%N`
echo "Rozpoczęcie kopiowania o godz. $start_time"

# check for the available space before doing the backup
set available_space=`df -k . --block-size=1K | sed -n '2p' | tr -s ' ' | cut -d ' ' -f 4`
set backup_space_needed=`du -sb $SOURCE | cut -f1`
set backup_space_in_mb=`du -sb $SOURCE --block-size=1M | cut -f1`
if ( "$backup_space_needed" >= "$available_space" ) then
	`zenity --error --text "Na dysku nie ma wystarczającej ilości wolnego miejsca w $SOURCE"`
	exit
endif

## backup
echo "Tworzenie kopii zapasowej $SOURCE w $DESTINATION..."
set date="`date +'%A-%Y-%m-%d:%H:%M'`"
set day_of_week="`date +'%A'`"
set destination_directory="$DESTINATION"
set full_destination="$destination_directory`basename $DESTINATION`_$date"
mkdir -p $full_destination

# remove all of the other backups made on the same day (except the one made now)
foreach file ("$destination_directory`basename $DESTINATION`_$day_of_week*")
	if ( $file != $full_destination ) then
		rm -r $file
	endif
end

# actual backup
rsync -ra --delete $SOURCE $full_destination
echo "Kopia zapasowa zapisana w $full_destination" 

set end_time_nano=`date +%s%N`
set end_time=`date +%H:%M:%S:%N`
set diff = `echo $end_time_nano-$start_time_nano | bc`
set elapsed=`echo "scale=8; $diff / 1000000000" | bc`
echo "Tworzenie kopii zakończone. Czas zakończenia kopiowania: $end_time. Czas kopiowania:  $elapsed sekund."
echo "Skopiowano $backup_space_in_mb MB"
