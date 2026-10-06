#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "Starting the script with administrator privileges.."
    exec sudo "$0" "$@"
    echo "Failed to start with administrator privileges, exiting.."
    exit 127
fi

if [ ! -f "cron.env" ]; then
    echo "Could not find cron.env in the current working directory"
    exit 1
fi

if ! command -v >/dev/null 2>&1; then
    apt install cron
fi

if ! [ "$(systemctl is-active cron)" = "active" ]; then
    systemctl enable cron
    systemctl start cron
fi



if [ "$1" = "--uninstall" ]; then
    (crontab -l 2>/dev/null | grep -v './antivirus$') | crontab -
    echo "Uninstalled the antivirus cron job"
else
    source ./cron.env
    NEWJOB="$INTERVAL $PRE_RUN cd /opt/antivirus/ && ./antivirus $MONITOR_DIR $QUARANTINE_DIR"
    (crontab -l 2>/dev/null | grep -v './antivirus.*./quarantine$'; echo "$NEWJOB") | crontab -
    echo "Installed/ updated the antivirus cron job"
fi