#!/bin/bash
# Requires bash 3.0 and exiftools
# usage organizePhotos.sh [-m] [-r] [-d] [-x jpg|png|jpeg] [-i] [-p] source-path dest-path
# Switch usages
# 	-m  move files instead of copy (copy is the default) Optional
# 	-d  create directories  Optional
#	-r  rename files  Optional
#	-x  extension (this can be any extension to match your pictures defaults to jpg) Optional
#	-i  case insensitive on the extension, incase of a JPG jpg etc. Optional
#	-p  directory (if -d) and/or file pattern, see strftime for valid pattern, if spaces surround in quotes.  Optional
#
# If spaces are in the directory, remember to use double quote around the full path IE: "/path/to/photos of me/" and always include ending slash.
#
# Warning, use are your own risk. I take no responsability for any deleted or lost pictures. Always backup your data. 
# Also note that this has no error checking / testing. Again, use at your own risk!
#

# Displays cli help message
help () {
	echo "Usage organizePhotos.sh [-m] [-r] [-d] [-x jpg|png|jpeg] [-i] [-p] source-path dest-path

Switch usages:
      -m  move files instead of copy (copy is the default) Optional
      -d  create directories  Optional
      -r  rename files  Optional
      -x  extension (this can be any extension to match your pictures defaults to jpg) Optional
      -i  case insensitive on the extension, incase of a JPG jpg etc. Optional
      -p  directory pattery, see strftime for valid pattern, if spaces surround in quotes.  Optional, but will trigger -d

If spaces are in the directory, remember to use double quote around the full path IE: \"/path/to/photos of me/\" and always include ending slash.

Warning, use are your own risk. I take no responsability for any deleted or lost pictures. Always backup your data.
Also note that this has no error checking / testing. Again, use at your own risk!"
}

#Setup some defaults
EXTENSION=jpg

#Setup default pattern (see strftime)
DEST_DIR_PATTERN="%Y_%m_%d"

PAT=false
EXTEN=false
CREATEDIR=false
INSENSITIVE=false
RENAME=false
MOVE=false

# Let's gather all the items and see what needs to be done.
for a in "$@"; do	
	if $EXTEN ; then
		EXT=true
		EXTENSION="$a"
		EXTEN=false
		continue
	fi

	if $PAT ; then
		PATTERN=true
		DEST_DIR_PATTERN=$a
		PAT=false
		continue
	fi

	case $a in
		-m)
			MOVE=true
		;;
		-r)
			RENAME=true
		;;
		-d)
			CREATEDIR=true
		;;
		-x)
			EXTEN=true
		;;
		-i)
			INSENSITIVE=true
		;;
		-p)
			PAT=true
		;;
		-h | --help | -help)
			help
			exit 0
		;;
	esac
done

SOURCE_DIR=${BASH_ARGV[1]}
DEST_DIR=${BASH_ARGV[0]}

if [ ! -d "$DEST_DIR" ]; then
	echo "The directory $DEST_DIR does not exist, exiting."
	exit 1
elif [ ! -d "$SOURCE_DIR" ]; then
	echo "The directory $SOURCE_DIR does not exist, exiting."
	exit 1
fi

# Add ending slash.
if [[ $DEST_DIR != */ ]]; then
	DEST_DIR="${DEST_DIR}/"
fi

CS="-name"
if $INSENSITIVE ; then
	CS="-iname"
fi

i=0
# @todo allow for custom find options, such as mtime etc.
for f in `find "$SOURCE_DIR" $CS "*.$EXTENSION" -type f`; do
	let i=$i+1

	f_date=`exiftool $f -CreateDate -d $DEST_DIR_PATTERN | cut -d ':' -f 2 | sed -e 's/^[ \t]*//;s/[ \t]*$//'`;

	# Obtain the creation date from the EXIF tag
	if $CREATEDIR ; then
		# Construct and create the destination directory
		f_dest_dir=${DEST_DIR}$f_date
		if [ ! -d $f_dest_dir ]; then
			echo "Creating directory $f_dest_dir"
			mkdir $f_dest_dir
		fi
	else
		f_dest_dir=$DEST_DIR
	fi

	if $RENAME ; then
		x=`printf %03d $i`
		f_dest_dir="${f_dest_dir}${f_date}_${x}.$EXTENSION"
	fi 

	if $MOVE ; then
		mv "$f" "$f_dest_dir"
		echo "Moved $f to ${f_dest_dir}${f}"
	else
		cp "$f" "$f_dest_dir"
		echo "Copied $f to ${f_dest_dir}${f}"
	fi

done

echo "$i images have been processed."
