#!/bin/sh
# Jemal Mohammed 06/07/2024
#
# The plugin shows the uptime and optionally
# compares it against MIN and MAX uptime thresholds
#######################################################################
VERSION="check_uptime v1.04"

# Exit-Codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage()
{
cat << EOF
usage: $0 [-c OPTION]|[-w OPTION] [-C OPTION]|[-W OPTION] [ -V ]

This script checks uptime and optionally verifies if the uptime
is below MINIMUM or above MAXIMUM uptime thresholds

OPTIONS:
   -h   Help
   -c   CRITICAL MIN uptime (minutes)
   -w   WARNING  MIN uptime (minutes)
   -C   CRITICAL MAX uptime (minutes)
   -W   WARNING  MAX uptime (minutes)
   -V   Version
EOF
}

while getopts "c:w:C:W:Vh" OPTION
do
     case $OPTION in
        c)
           MIN_CRITICAL="$OPTARG"
           ;;
        w)
           MIN_WARNING="$OPTARG"
           ;;
        C)
           MAX_CRITICAL="$OPTARG"
           ;;
        W)
           MAX_WARNING="$OPTARG"
           ;;
        V)
           echo "$VERSION"
           exit $STATE_OK
           ;;
        h)
           usage
           exit $STATE_OK
           ;;
        *)
           usage
           exit $STATE_UNKNOWN
           ;;
     esac
done

# Get uptime report and parse the uptime values
UPTIME_REPORT=$(uptime | tr -d ",")

# Extract days, hours, and minutes from the uptime report
if echo "$UPTIME_REPORT" | grep -i day > /dev/null; then
    DAYS=$(echo "$UPTIME_REPORT" | awk '{ print $3 }')
    HOURS=$(echo "$UPTIME_REPORT" | awk '{ print $5 }' | cut -f1 -d":")
    MINUTES=$(echo "$UPTIME_REPORT" | awk '{ print $5 }' | cut -f2 -d":")
else
    HOURS=$(echo "$UPTIME_REPORT" | awk '{ print $3 }')
    MINUTES=$(echo "$UPTIME_REPORT" | awk '{ print $5 }')
fi

# Calculate total uptime in minutes
UPTIME_MINUTES=$((0$DAYS * 1440 + 0$HOURS * 60 + 0$MINUTES))
UPTIME_MSG="${DAYS:+$DAYS Days, }${HOURS:+$HOURS Hours, }$MINUTES Minutes"

# Check against configured thresholds and output appropriate messages
if [ -n "$MIN_CRITICAL" ] && [ "$UPTIME_MINUTES" -lt "$MIN_CRITICAL" ]; then
    echo "CRITICAL - System rebooted $UPTIME_MSG ago"
    exit $STATE_CRITICAL
elif [ -n "$MIN_WARNING" ] && [ "$UPTIME_MINUTES" -lt "$MIN_WARNING" ]; then
    echo "WARNING - System rebooted $UPTIME_MSG ago"
    exit $STATE_WARNING
elif [ -n "$MAX_CRITICAL" ] && [ "$UPTIME_MINUTES" -gt "$MAX_CRITICAL" ]; then
    echo "CRITICAL - System has not rebooted for $UPTIME_MSG"
    exit $STATE_CRITICAL
elif [ -n "$MAX_WARNING" ] && [ "$UPTIME_MINUTES" -gt "$MAX_WARNING" ]; then
    echo "WARNING - System has not rebooted for $UPTIME_MSG"
    exit $STATE_WARNING
else
    echo "OK - Uptime is $UPTIME_MSG"
    exit $STATE_OK
fi
