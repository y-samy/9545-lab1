#!/bin/sh
if [ ! -f "cron.env" ]; then
    echo "Could not find cron.env in the current working directory"
    exit 1
fi

if ! command -v cron >/dev/null 2>&1; then
    sudo apt install cron -y
fi

if ! [ "$(systemctl is-active cron)" = "active" ]; then
    sudo systemctl enable cron
    sudo systemctl start cron
fi

if [ "$1" = "--uninstall" ]; then
    (crontab -l 2>/dev/null | grep -v './antivirus$') | crontab -
    echo "Uninstalled the antivirus cron job"
else
    . ./cron.env
    NEWJOB="$INTERVAL $PRE_RUN cd /opt/antivirus/ && ./antivirus $MONITOR_DIR $QUARANTINE_DIR"
    (crontab -l 2>/dev/null | grep -v '\./antivirus'; echo "$NEWJOB") | crontab -
    echo "Installed/ updated the antivirus cron job"
fi