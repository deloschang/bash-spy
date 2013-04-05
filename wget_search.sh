#!/bin/sh
# Script name: wget_search.sh
#
# Description: Processes a text file (first argument)
# and 1+ arguments and searches for occurrences of the word(s)
# in the webpages found at the listed URLs.
#
# Command line options: No extra command line options with script
#
# Input: 1st argument:file with list of URLs to search for
# additional arguments: words to search for
# e.g. ./wget_search.sh url.txt word1 word2
#
# Output: Word that was searched along with URLs
# and the occurrences of words (including substring)
#
# Special considerations:  scripts run multiple 
# times will overwrite existing html pages like
# 0.html, 1.html, 2.html etc. The script will
# also include substrings in the string (not an
# exact match).
#
# Pseudocode: First check for sufficient arguments (at least 2).
# Loop through every word provided as arguments. For each one
# of those words, loop through the URLs in the URL.txt:
# Wget each html file from the URL and then search for the
# occurrence of the word. Increment the filename counter so the
# next file will be named as a progressive integer.
#

# check for sufficient arguments (one for URL and at least 
# one for words to search for 
if (( $# < 2 )); then
  echo "Insufficient arguments. At least 2 required"
  exit 1
fi

# first argument will be the url text file
input=$1

# for every word in the provided arguments..
# (skip the first because it is the url file)
for ((i=2;i<=$#;i++))
do
  echo ${!i} # word to search for

  # for every URL in the url.txt file
  # files will be rewritten on the second run
  num=1
  for line in `cat "$1"`; do
    echo -ne $line " "   

    ## do the searching and concatenate
    # -O renames the file
    # -q makes wget quiet
    wget -q -O $num.html $line 

    # grep for the line
    # -o | wc-l will count occurrences (incl
    # multiple occurrences in the same line)
    cat $num.html | grep "${!i}" -o | wc -l 
    (( num++ ))
  done

  echo -e "\n"  # formatting

done
exit 0


