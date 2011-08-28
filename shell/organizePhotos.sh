#!/bin/bash
# Requires bash 3.0
# usage organizePhotos.sh [-m] [-r] [-d] [-x jpg|png|jpeg] [-i] [-p] source-path dest-path
# Switch usages
# 	-m  move files instead of copy (copy is the default) Optional
# 	-d  create directories  Optional
#	-r  rename files  Optional
#	-x  extension (this can be any extension to match your pictures defaults to jpg) Optional
#	-i  case insensitive on the extension, incase of a JPG jpg etc. Optional
#	-p  directory pattery, see strftime for valid pattern, if spaces surround in quotes.  Optional
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
      -p  directory pattery, see strftime for valid pattern, if spaces surround in quotes.  Optional

If spaces are in the directory, remember to use double quote around the full path IE: \"/path/to/photos of me/\" and always include ending slash.

Warning, use are your own risk. I take no responsability for any deleted or lost pictures. Always backup your data.
Also note that this has no error checking / testing. Again, use at your own risk!"
}

# Let's gather all the items and see what needs to be done.
for a
do 
	if [ $EXTEN ]; then
		EXT=$a
		EXTENSION=true
		EXTEN=false
		continue
	fi

	if [ $PAT ]; then
		PATTERN=true
		PATT=$a
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
		*)
			help
			exit 0
		;;
	esac
done

SOURCE_DIR=${BASH_ARGV[1]}
DEST_DIR=${BASH_ARGV[0]}

echo $SOURCE_DIR
echo $DEST_DIR
exit 0
 
# The date pattern for the destination dir (see strftime)
DEST_DIR_PATTERN="%Y_%m_%d"
 
# Move all files having this extension
EXTENSION=jpg
 
for f in `find "$SOURCE_DIR" -iname "*.$EXTENSION" -type f -mtime -10`; do
	# Obtain the creation date from the EXIF tag
	f_date=`exiftool $f -CreateDate -d $DEST_DIR_PATTERN | cut -d ':' -f 2 | sed -e 's/^[ \t]*//;s/[ \t]*$//'`;
 
	# Construct and create the destination directory
	f_dest_dir=$DEST_DIR/$f_date
	if [ ! -d $f_dest_dir ]; then
		echo "Creating directory $f_dest_dir"
		mkdir $f_dest_dir
	fi
 
	mv "$f" "$f_dest_dir"
	echo "Copied $f to $f_dest_dir"
done
