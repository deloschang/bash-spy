#!/bin/bash
# script name: birthday_match.sh
#
# Description: Takes two birthdays (or two dates in history) as
# arguments in form of MM/DD/YYYY. Then determines whether the two 
# dates occurred on the same day of the week, notifying the user.
#
# Command line options:  None
#
# Input: two dates to test if they occurred on the same day of
# the week (in the format MM/DD/YYYY). Example: 04/06/1992
#
# Output: Tests if they occurred on the same day of the week
# If so, the script will tell you. If not, the script will also tell you.
#
# Special considerations: Enter your dates in MM/DD/YYYY format. 
# Input like 'yesterday' or 'tomorrow' won't work.
#
# Pseudocode: if there more or less than 2 arguments provided in the 
# prompt, stop. Initialize the two arguments into variables. If 
# the first or second date aren't in the format of ##/##/#### where 
# '#' can be 0-9, stop because there is a formatting error. Now use
# date -d to check whether the input is a valid date. This will exclude
# invalid dates like 14/25/1992. Finally, parse for the day of week the 
# date is (using date and cut). If the day of the week matches for both dates,
# let the user know. If not, also let the user know.
#

# first check for sufficient arguments
[ "$#" -eq 2 ] || { echo "2 date arguments required but you only gave $#" 1>&2; exit 1;}

# initialize the date variables
first_date=$1
second_date=$2

# validate numbers format
# this prevents dates like 'tomorrow' that work for date -d
if echo $first_date | grep -cq '^[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]$'; then 
  if echo $second_date | grep -cq '^[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]$'; then

    # validate that they are dates
    # this prevents dates like 45/55/1992, which are not valid.
    date -d "$first_date" > /dev/null 2>&1 && date -d "$second_date" > /dev/null 2>&1

    # dates are valid; find day of week by cutting
    if [ $? -eq 0 ]; then
      first_day_of_week=`date -d $first_date | cut -d" " -f1`
      second_day_of_week=`date -d $second_date | cut -d" " -f1`

      echo "The first person was born on: $first_day_of_week"
      echo "The second person was born on: $second_day_of_week"

      # Check if the weekdays match. Tell user the result.
      if [ "$first_day_of_week" == "$second_day_of_week" ]; then
        echo "Jackpot: You were both born on the same day!"
      else
        echo "Therefore, you are not born on the same day."
      fi

    else
      echo "Date error: invalid dates. Example: 04/06/1992"
      exit 1
    fi
  else
    echo "Formatting error with $second_date: please enter in the format MM/DD/YYYY. Example: 04/06/1992"
    exit 1

  fi

else
	echo "Formatting error with $first_date: please enter in the format MM/DD/YYYY. Example: 04/06/1992"
  exit 1
fi

exit 0
