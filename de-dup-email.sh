#!/bin/bash

# Copyright (C) 2015 Dawn M. Foster
# Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt

# CAVEAT: Because sed isn't particularly portable (sigh), this only works on Linux, not MacOS right now.

# The purpose of this script is to make sure I have one email address per person in my mlstats
# output, so for people using multiple email addresses, replace one email address with a 
# single main email address.

# Note: this is NOT a general purpose script. I am using this with mlstats and this script
#       is being used to sanitize the output. I will only work in certain cases, and maybe only for me :)

# -i, --inputfile	FILE: Set the input filename (CSV file) where you want to do the search and replace
#			This file should be of a form (per line), similar to: thread subect,email,date,message_id
#			Most importantly, the file must be comma separated and contain email addresses.
#			CAUTION: if you have any other fields that contain email addresses, like mlstats message_id
#				This will clobber that field as well. You may need to tweak the sed command in this case.
# -o, --outputfile	OUTFILE: Set the filename for the output file as OUTFILE where 
#			you want to store clean text. Note: sed also creates a .bak while editing this file
# -e, --email-aliases	ALIASES: The file where the email aliases are stored. 
#			Each line should contain: old@example.com,new@example.com,# optional comment	

# Read arguments from the command line and store them in variables

while [[ $# > 0 ]]
do
key="$1"

case $key in
     -e|--email-aliases)
     ALIASES="$2"
     shift
     ;;
     -i|--inputfile)
     FILE="$2"
     shift
     ;;
     -o|--outputfile)
     OUTFILE="$2"
     shift
     ;;
        *)
            # unknown option
    ;;
esac

shift
done

# output message to make sure user has the correct details

echo "Reading input from $FILE"
echo "Transforming using $ALIASES"
echo "Output stored in $OUTFILE"

# copying the original to the output file which will edited by this script
# to change email addresses

cp $FILE $OUTFILE

# use comma as separator, but first store original IFS to restore it later.

OIFS=$IFS
IFS=,

# loop through email-aliases file, look for people with multiple email addresses
# and set them to a single email address in the output file. 
# email-aliases file contains mappings of email addresses.

while read EMAIL1 EMAIL2 COMMENT; do
   sed -i -e "s/$EMAIL1/$EMAIL2/g" $OUTFILE
done < $ALIASES

# reset IFS back to original setting

IFS=$OIFS
