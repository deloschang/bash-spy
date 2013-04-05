#!/bin/bash
# script name: count_files.sh
#
# Description: Counts the number of files of each filetype in 
# the current dir. and its subdirectories, producing a summary
# report.
#
# Command line options:  None
#
# Input: None
#
# Output: A summary of the filetype extensions, including those 
# without file extensions.
#
# Special considerations: If a file has no '.' in its name or there
# is a '.' that has no characters following it, it is considered to be
# a 'noext' file. Current dir '.' and parent directory '..' are not counted.
#
# Pseudocode: First, search for files with the wildcard format '*.*'. Exclude
# files with only a '.' and no characters following (handle it later). From
# this list, reverse the letters and cut at the '.'. Extract the first slice 
# for the file extension. Reverse letters again to restore the original 
# filetype name. Sort and use unique to count the unique filetypes.
# To handle noext files, invert the original search but include "*." type 
# files and exclude the current directory ".". Use word count to sum up
# such no extension files. Echo this number and the name 'noext' in a 
# similarly formatted manner.

# start with finding files with extensions
# exclude the edge case with a . with no characters following
find . -type f -name '*.*' -not -name '*.' | rev \
  | cut -d'.' -f1 | rev | sort | uniq -c

# now handle the no extension files
# exclude current directory
# include edge case with a . with no character following
noext_count=`find . -type f ! -name "*.*" -o -name "*." -not -name "." | wc -l`

# format similarly
echo -e "      $noext_count noext"
exit 0
