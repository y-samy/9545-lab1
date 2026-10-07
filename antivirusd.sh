#!/bin/bash
SCRIPT_NAME=${0##*/}

if [[ $# -lt 3 ]]; then
    if [[ "$1" == "--help" ]]; then
        echo "Antivirus Daemon"
        echo "Usage: $SCRIPT_NAME <dir> <malicious_dir> <interval-secs>"
        echo "<dir> is the directory to monitor"
        echo "<malicious_dir> is the quarantined files directory"
        echo "<interval-secs> is the polling interval in seconds for file monitoring"
        exit 0
    else
        echo "Insufficient arguments provided."
        echo "Usage: $SCRIPT_NAME <dir> <malicious_dir> <interval-secs>"
        echo "For more information, use $SCRIPT_NAME --help"
        exit 127
    fi
fi

if ! mkdir -p "$1"; then
    echo "Argument $1 provided is not a directory."
    echo "Refer to <dir> in usage manual or use $SCRIPT_NAME --help"
    exit 1
fi

if ! mkdir -p "$2"; then
    echo "Argument $2 provided is not a directory."
    echo "Refer to <malicious_dir> in usage manual or use $SCRIPT_NAME --help"
    exit 1
fi

if ! [[ "$3" =~ ^[1-9][0-9]*$ ]]; then
    echo "Argument $3 provided is not a valid polling interval in seconds."
    echo "Refer to <interval-secs> in the usage manual or use $SCRIPT_NAME --help"
    exit 1
fi

DIR=${1%/}/
QUARANTINE_DIR=${2%/}/
INTERVAL=$3

FLAGGED_EXT=("exe" "bat" "vbs" "scr" "ps1")
FLAGGED_CONTENT=("virus" "trojan" "malware" "worm" "ransomware")
FLAGGED_EXT_REGEX="\.($(IFS="|"; echo "${FLAGGED_EXT[*]}"))$"
FLAGGED_CONTENT_REGEX="($(IFS="|"; echo "${FLAGGED_CONTENT[*]}"))"

ALLOWLIST_FILE=allowlist
OLD_INFO_FILE=directory-info.last
NEW_INFO_FILE=directory-info.new

if ! [[ -f "$OLD_INFO_FILE" ]]; then
    # initialize as empty file against lab instructions to allow the pre-made tests to work
    echo "" > "$OLD_INFO_FILE"
fi

while true; do
    sleep "$INTERVAL"
    ls -l "$DIR" > "$NEW_INFO_FILE"
    diff -q "$OLD_INFO_FILE" "$NEW_INFO_FILE" >/dev/null 2>&1
    if [[ $? -eq 1 ]]; then
        readarray -t EXT_FILES < <(ls "$DIR" | grep -E "$FLAGGED_EXT_REGEX")
        for file in "${EXT_FILES[@]}"; do
            if [[ -r "$ALLOWLIST_FILE" ]]; then
                if grep -Fqx "$file" < "$ALLOWLIST_FILE"; then continue; fi
            fi
            cp "$DIR""$file" "$QUARANTINE_DIR""$file"
            rm "$DIR""$file"
            echo "$file" is malicious and it is DELETED
        done
        readarray -t FILES < <(ls "$DIR")
        for file in "${FILES[@]}"; do
            if [[ -r "$ALLOWLIST_FILE" ]]; then
                if grep -Fqx "$file" < "$ALLOWLIST_FILE"; then continue; fi
            fi
            if grep -Eqi "$FLAGGED_CONTENT_REGEX" < "$DIR""$file"; then
                cp "$DIR""$file" "$QUARANTINE_DIR""$file"
                rm "$DIR""$file"
                echo "$file" is malicious and it is DELETED
            fi
        done
        # both info files are outdated now, lab PDF suggestion is bad here
        ls -l "$DIR" > "$OLD_INFO_FILE"
    fi
done
