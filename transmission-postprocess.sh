#!/bin/bash

videoRegex=".*\.\(webm\|mkv\|flv\|vob\|ogv\|ogg\|avi\|mov\|qt\|wmv\|mp4\|m4p\|m4v\|mpg\|mp2\|mpeg\|mpe\|mpv\|m2v\|3gp\|3g2\)"


#Declaration des parametres
LOG_FILE="/tmp/transmission.log"
TV_DEST_DIR="/mnt/Pre/Series"
MOVIES_DEST_DIR="/mnt/Pre/Films"
SRC_FILE=""
DES_FILE=""
DES_DIRECTORY=""
OutputFormat=""
fileRegex=""
SpecifiedOuputDir=false

function  its_a_tvshow {
	if [ "$SpecifiedOuputDir" = false ] ; then
		DES_DIRECTORY=`echo "$TV_DEST_DIR"/`
	fi
	fileRegex=$videoRegex
        OutputFormat=`echo "{plex[1]}/{plex[2]}/{plex[3]} - {group}"`
}

function its_a_movie {
	if [ "$SpecifiedOuputDir" = false ] ; then
        	DES_DIRECTORY=`echo "$MOVIES_DEST_DIR"/`
	fi
	fileRegex=$videoRegex
	OutputFormat=`echo "{n} ({y})\{n} ({y})"`
}
function usage {
	echo "usage: transmission-postprocess.sh [-m file path] [-t file path]"
    	echo "  -h 			display help"
	echo "  -o output path		sepcify output directory"
    	echo "  -m file path   		specify movie file path"
    	echo "  -t file path   		specify tv show file path"
   	 exit 1
}

function rename {
	for ((i=0;i<${#SRC_FILE[@]};++i)); do
		ln "${SRC_FILE[i]}" "${DES_FILE[i]}"
		if [ "$SearchSub" = true ] ; then
			echo "linked ${SRC_FILE[i]} to ${DES_FILE[i]}" | tee -a "$SUB"
		fi
        	/usr/bin/filebot -rename "${DES_FILE[i]}"\
        	--action move\
        	-non-strict\
        	--format "$OutputFormat"
	done
}

# source file definition
if [ $# -eq 0 ]; then
	if [[ ($TR_TORRENT_DIR == "" ) || ($TR_TORRENT_NAME == "")]]; then
		usage
	else 
        	SRC_FILE=`echo "$TR_TORRENT_DIR"/"$TR_TORRENT_NAME"`
	fi

	if [[ ($TR_TORRENT_DIR == "/media/Downloads/Series")]]; then
		its_a_tvshow
	elif [[ ($TR_TORRENT_DIR == "/media/Downloads/Films")]]; then
       		its_a_movie
	fi
else
	while getopts ":m:t:o:h" opt; do
  		case $opt in
    		m)
      			SRC_FILE="$OPTARG" >&2
			its_a_movie
      		;;
    		t)
      			SRC_FILE="$OPTARG" >&2
                        its_a_tvshow 
      		;;
		o)
			DES_DIRECTORY="$OPTARG" >&2
			SpecifiedOuputDir=true
		;;
    		h)
        		usage
        	;;
    		\?)
      			echo "Invalid option: -$OPTARG" >&2
      			usage
      		;;
    		:)
      			echo "Option -$OPTARG requires an argument." >&2
        		usage
      		;;
	esac
	done
fi

# we don't know yet if the downloaded file torrent is a directory or not
# so we test if SRC_FILE is a directory

#destination file definition
if [[ -d $SRC_FILE ]]; then
	while IFS= read -r -d $'\0' file; do
		if ! [[ "$(declare -p SRC_FILE)" =~ "declare -a" ]]; then
			unset SRC_FILE
		fi
    		SRC_FILE+=("$file")
                if ! [[ "$(declare -p DES_FILE)" =~ "declare -a" ]]; then
                        unset DES_FILE
                fi
		DES_FILE+=(`echo "$DES_DIRECTORY$(basename "$file")" | sed 's/\ /_/g'`)
	done < <(find "$SRC_FILE" -regex "$fileRegex" -print0)
elif [[ -f $SRC_FILE ]]; then
	DES_FILE=`echo "$DES_DIRECTORY$(basename "$SRC_FILE")" | sed 's/\ /_/g'`
else 
	echo error
	exit 1
fi

rename
exit 1
