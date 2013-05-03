#!/bin/bash
# Script name: spy.sh
#
# Description: Monitors when users log in and 
# out of a machine and records when the
# time a user logs in and out. 
# The script also computes which user logged in the most often, 
# and for the longest and shortest periods of time.
#
# Command line options:  None
#
# Input: List of users to monitor in terms of 
#		 their full names such as “Charles Palmer”
#
# Output: A log of which users logged in and out
# and when. A summary of activity of all the users
# monitored with trivia like session length.
#
# Special considerations:  The script will create
# a temp file for each user. Each time the script sees
# a user as 'logged in', it will increment by 1 minute.
# Then when the user logs out, it will deduct these increments
# and add the difference between login and logout times. This
# is done so that when the script is killed, the accumulated
# login time is accurate. If the user provided is not in 
# /etc/passwd, the script will complain but continue.
# 
#
# Pseudocode:  First validate whether there are sufficient arguments.
# If so, log the starttime and startdate and then loop over each of the
# name arguments. Extract the username from the name arguments in /etc/passwd.
#
# Set up initial variables for each user. Then loop and check if the users are logged in.
# Case 1: The user was not logged in and logs in. Record the login time. 
# Update trivia like who has the longest total session, who has the shortest session, who has the longest 
# session.
# Case 2: The user was logged in and is still logged in. Increment their login period by 1 min. 
# Case 3: The user was logged in and is not logged in. Record the current time as the logout time.
# Deduct the increment times and add the difference between login and logout time to the total 
# time spent logged in (this prevents double counting). 
# Case 4: The user was not logged in and is not logged in. Do nothing.
# Update trivia like who has the longest total session, who has the shortest session, who has the longest 
# session.
#
# For each of the cases above, log this in a temp username log file.
# Set up a trap that outputs the information to spy.log when killed. Concatenate the temp username log file
# for a full report.
# 
#

# check for sufficient arguments (at least one user specified)
if (( $# < 1 )); then
  echo "Insufficient arguments. At least 1 user required. Example: Charles C. Palmer"
  exit 1
fi

# check start time and date
starttime=`date +"%H:%M"` # format for hours:minutes
startdate=`date +"%m-%d-%y"` # format for month:date:year 

# initialize variables for trivia at end (longest / shortest session etc.)
# these variables are dummies and are updated as new login times come in. 
maxtime=0
maxuser="Nobody"
leastdiff=999999999999
leastuser="Nobody"
longestsession=0
longestuser="Nobody"

# initialize variables for each user 
# these variables track the login time, login status, amount of time incremented etc.
for ((i=1;i<=$#;i++))
do
    checkusername=`cat /etc/passwd | grep "${!i}" | cut -d: -f1` # e.g. dfchang

    # If there is no such user found in /etc/passwd, complain but continue.
    if [ -z "$checkusername" ]; then
      echo "No such user: ${!i}. Not checking for ${!i}"
      break
    fi

    echo "$checkusername added to spy list"

    eval loggedon${checkusername}=false  # login status
    eval counter${checkusername}=0       # number of times logged in 
    eval total${checkusername}=0         # total time logged in 

    # amount to be deducted when user logs out (for login times to be accurate if script is killed)
    eval added${checkusername}=0         # amount incremented before logging out
done

# main loop to check if users are logged in
while : 
do
  # loop over each user
  for ((i=1;i<=$#;i++))
  do
    checkusername=`cat /etc/passwd | grep "${!i}" | cut -d: -f1` # e.g. dfchang

    # Complain but continue if user is not found in /etc/passwd
    if [ -z "$checkusername" ]; then
      echo "No such user: ${!i}. Not checking for ${!i}"
      break
    fi

    # these variables are used to reference the dynamic variables for each user
    # used in place of arrays
    # we reference the dynamic variables like so: e.g. ${!tmpcount} 
    tmp="loggedon$checkusername"
    tmpcount="counter$checkusername"
    tmptotal="total$checkusername"

    startcalc="startcalc$checkusername"
    endcalc="endcalc$checkusername"
    diffcalc="diffcalc$checkusername"
    added="added$checkusername"

    # check if user is logged in and by exit status
    who | grep -q $checkusername 
    if (( $? == 0 )) 
    then 

      # only update if we haven't seen user logged on before
      if ! ${!tmp} 
      then
        # Change login status for the next loop
        eval loggedon${checkusername}=true

        # Increment number of times logged in 
        eval counter${checkusername}=`expr ${!tmpcount} + 1`

        # Create file to record login times
        if [ -e ${name}_temp.log ]; then
          touch ${checkusername}_temp.log
        fi

        checktime=`who | grep $checkusername | awk '{print $4}' | head -n 1 | xargs date -d`

        # Variable to record login start time
        eval startcalc${checkusername}=`who | grep $checkusername | awk '{print $4}' | head -n 1 | xargs date +%s -d`

        # Record time to file
        echo -n "${!tmpcount}) Logged on $checktime" >> ${checkusername}_temp.log
      else
        # User was seen as logged in before and is still logged in.
        # Update total time

        # add to total period and record what was just added (for updating later)
        # This is done to maintain accurate total login period if the script is killed
        # while the user is logged in
        eval total${checkusername}=`expr ${!tmptotal} + 1` 
        eval added${checkusername}=`expr ${!added} + 1` # deduct this time when the user is logged out

        # update checks for trivia (i.e. longest session / shortest session etc.)
        if (( ${!tmptotal} > $maxtime ))
        then
          maxtime=${!tmptotal}
          maxuser=$checkusername
        fi

        # make sure diffcalc is non-null first
        if [ -z ${!diffcalc} ]; then
          break
        fi

        if (( ${!diffcalc} < $leastdiff ))
        then
          leastdiff=${!diffcalc}
          leastuser=$checkusername
        fi

        if (( ${!diffcalc} > $longestsession ))
        then
          longestsession=${!diffcalc}
          longestuser=$checkusername
        fi
      fi

    # User logged out 
    elif ${!tmp}
    then
      # calculate how long the user was logged in 
      # by calculating difference between login and logout time
      offtime=`date` 
      
      # logout time variable
      eval endcalc${checkusername}=`date +%s`

      # the difference between login and logout time, expressed in minutes
      eval diffcalc${checkusername}=`expr ${!endcalc} - ${!startcalc} | awk '{printf "%d", $1/60}'`

      # add to total period BUT take out accumulated time to prevent double count
      # ${!added} is used to maintain accuracy of login period time in case script is killed while 
      # a user is logged in 
      eval total${checkusername}=`expr ${!tmptotal} + ${!diffcalc} - ${!added}`
      eval added${checkusername}=0 # already balanced so reset

      # record logout time to file
      echo "; logged off $offtime" >> ${checkusername}_temp.log

      # change login status to not logged in 
      eval loggedon${checkusername}=false

      # update checks for trivia (i.e. longest session / shortest session etc.)
      if (( ${!tmptotal} > $maxtime ))
      then
        maxtime=${!tmptotal}
        maxuser=$checkusername
      fi

      if (( ${!diffcalc} < $leastdiff ))
      then
        leastdiff=${!diffcalc}
        leastuser=$checkusername
      fi

      if (( ${!diffcalc} > $longestsession ))
      then
        longestsession=${!diffcalc}
        longestuser=$checkusername
      fi
    fi
  done

  # set up trap upon kill -10
  trap `echo spy.sh Report > spy.log
  echo started at $starttime on $startdate >> spy.log
  echo -n "stopped at $(date +%H:%M)" >> spy.log
  echo " on $(date +%m-%d-%y)">> spy.log

  echo -n arguments: >> spy.log
  for var in "$@"
  do
    echo -n ' ' >> spy.log
    echo -ne \"$var\"  >> spy.log
    echo -n ' ' >> spy.log
  done 

  echo -e "\n" >> spy.log

  # setup for each user, then concatenate the login file
  for ((i=1;i<=$#;i++))
  do
    name=$(cat /etc/passwd | grep "${!i}" | cut -d: -f1)

    tmpcount="counter$name"
    tmptotal="total$name"

    if [ -e ${name}_temp.log ]; then
      
        
      echo -n "$name logged on " >> spy.log
      echo "${!tmpcount} times for a total period of ${!tmptotal} mins. Here is the breakdown:" >> spy.log

      cat ${name}_temp.log >> spy.log

      echo -e "\n" >> spy.log
    fi
  done

  # trivia portion
  echo "$maxuser spent the most time on wildcat today - $maxtime mins in total for all his sessions." >> spy.log
  echo "$leastuser was on for the shortest session for a period of $leastdiff mins, and therefore the most sneaky." >> spy.log
  echo "$longestuser was logged on for the longest session of $longestsession mins." >> spy.log
  exit 0

  `USR1

  # sleep for a minute and then check user login statuses
  sleep 60
done

