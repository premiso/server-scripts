#!/bin/bash
 
# The directory where the photos are
SOURCE_DIR=/home/<username>/Pictures
 
# The destination directory
DEST_DIR=/home/<username>/Pictures/organized
 
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
