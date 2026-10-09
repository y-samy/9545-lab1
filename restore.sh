#!/bin/bash
set -e

SCRIPT_NAME=${0##*/}

if [[ $# -lt 2 ]]; then
    if [[ "$1" == "--help" ]]; then
        echo "Restore tool for quarantined files by the antivirus daemon"
        echo "Usage: $SCRIPT_NAME <dir> <malicious_dir>"
        echo "<dir> is the user's files directory"
        echo "<malicious_dir> is the quarantined files directory"
        exit 0
    else
        echo "Insufficient arguments provided."
        echo "Usage: $SCRIPT_NAME <dir> <malicious_dir> <interval-secs>"
        echo "For more information, use $SCRIPT_NAME --help"
        exit 127
    fi
fi

if ! [[ -d "$1" ]]; then
    echo "Argument $1 provided is not a directory."
    echo "Refer to <dir> in usage manual or use $SCRIPT_NAME --help"
    exit 1
fi

if ! [[ -d "$2" ]]; then
    echo "Argument $2 provided is not a directory."
    echo "Refer to <malicious_dir> in usage manual or use $SCRIPT_NAME --help"
    exit 1
fi

DIR=${1%/}/
QUARANTINE_DIR=${2%/}/

ALLOWLIST_FILE=allowlist
OLD_INFO_FILE=directory-info.last
NEW_INFO_FILE=directory-info.new


while true; do
    readarray -t FILE_LIST < <(ls "$QUARANTINE_DIR")

    if [[ ${#FILE_LIST[@]} -eq 0 ]]; then
        echo "No malicious files to review."
        exit 0
    fi

    clear

    # File listing
    for (( i = 0; i < ${#FILE_LIST[@]}; i++ )); do
        echo $(($i + 1)): "${FILE_LIST[$i]}"
    done

    # File picker validation
    CHOICE=""
    while [[ -z "$CHOICE" ]]; do
        if [[ ${#FILE_LIST[@]} -eq 1 ]]; then
            printf "Choose file (1): "
        else
            printf "Choose file (1-%s): " ${#FILE_LIST[@]}
        fi
        read CHOICE
        if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || [[ $CHOICE -gt ${#FILE_LIST[@]} ]] || [[ $CHOICE -le 0 ]]; then
            CHOICE=""
            printf "\033[A\33[2K"
            continue
        fi
    done

    # Actions
    echo "Actions"
    echo "1: Restore this file back into" "$DIR" "(it was a false positive)"
    echo "2: Permanently delete this file from" "$QUARANTINE_DIR" "(it was genuinely malicious)"
    echo "3: Leave this file as-is and go back to the list"

    ACTION=""
    while [[ -z "$ACTION" ]]; do
        printf "Choose action (1-3): "
        read ACTION
        if [[ ! "$ACTION" =~ ^[0-9]+$ ]] || [[ $ACTION -gt 3 ]] || [[ $ACTION -lt 1 ]]; then
            ACTION=""
            printf "\033[A\33[2K"
            continue
        fi
    done

    CHOICE=$(($CHOICE - 1))
    FILE=${FILE_LIST[$CHOICE]}
    if [[ "$ACTION" -eq 1 ]]; then
        mv "$QUARANTINE_DIR""$FILE" "$DIR""$FILE"
        echo Restored "$FILE" to "$DIR".
        echo "$FILE" >> "$ALLOWLIST_FILE"
    fi

    if [[ "$ACTION" -eq 2 ]]; then
        rm "$QUARANTINE_DIR""$FILE"
        echo "$FILE" permanently deleted.
    fi

    if [[ "$ACTION" -eq 3 ]]; then
        continue
    fi

    printf "Go back? Choose no to exit (Y/n) "
    read BACK
    if [[ "$BACK" =~ ^(N|No|n|no)$ ]]; then
        exit 0
    fi
done