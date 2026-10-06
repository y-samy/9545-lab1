# Lab 2 - OS Course - CCE @ Alex. Uni.

## Folder Outline

| File/ Folder Name   | Purpose |
| ------------------- | ------- |
| `antivirusd.sh`     | Polling-based antivirus script |
| `restore.sh`        | Quarantined file restoration script |
| `Makefile`          | Centralized setup and runner Makefile |
| `allowlist`*        | Text file for tracking whitelisted/ restored files |
| `test/`*            | Testing folder |
| `antivirus-cron.sh` | One-shot antivirus script |
| `service-setup.sh`  | Advanced pre-setup script for the cron job |
| `cron.env`          | Settings for the cron job setup script |
| `README.md`         | Repository documentation |
| `LICENSE`**         | BSD 3-Clause License |
| `.gitignore`**      | gitignore |

\* runtime files, ignored from git tracking\
\*\* repository-specifc files

## Requirements

### Linux

This project assumes a full install of any mainstream Linux distribution.

Precisely speaking, the project requires:
- `bash` at `/bin/bash`
- a POSIX-compatible shell at `/bin/sh`
- cron installed for the `crontab` command
- a systemd-enabled system
- optionally `make` for using the Makefile

In case `cron` (or equivalent, ex: `cronie`) isn't installed, the scripts will attempt to install it using `apt` - which will only work on Debian-based systems.

For use in containers or WSL, make sure the host is systemd-enabled and see [Container Interface - systemd](https://systemd.io/CONTAINER_INTERFACE/).

### MacOS

The project can be adapted to work with MacOS without any additional installs:
- `bash` -> `zsh`
- cron installed for the `crontab` command ✅
- `systemd` -> usage removed
- a POSIX-compatible shell at `/bin/sh` ✅
- optionally `make` (from XCode or brew) for using the Makefile

### Windows

Incompatible.

## Setup

Make sure to run all the following commands from the repository's root folder.

### Using the Makefile

#### Test Run - AV Daemon

```sh
make test-av
```

#### Test Run - Restore Tool

```sh
make test-rs
```

#### Test Runs - Cleanup

```sh
make clean
```

#### Install AV Daemon

To install:
```sh
make install
```

To run:
```sh
/opt/antivirus/antivirusd </path/to/monitor/> </path/to/quarantined/> <interval-secs>
```

#### Install AV as a Cron Job

Modify `cron.env`:
- `INTERVAL` contains the interval
- `PRE_RUN` contains the pre-run command, must have a trailing chaining operator
- `MONITOR_DIR` contains the directory to monitor
- `QUARANTINE_DIR` contains the directory to move malicious files into

By default, it is set to: run at a 1min 23s interval, monitor `/opt/` and quarantine files to `/opt/antivirus/quarantine/`.

To install, run:
```sh
make install-svc
```

#### Uninstall AV

```sh
make uninstall
```

### Manually Running the Scripts

#### Antivirus Daemon

First, make sure the script is executable:

```sh
chmod +x ./antivirusd.sh
```

Then run:
```sh
./antivirusd.sh </path/to/monitor/> </path/to/quarantined/> <interval-secs>
```

Replacing each of the required parameter placeholders with actual arguments.

#### Restore Tool

First, make sure the script is executable:

```sh
chmod +x ./restore.sh
```

Then run:
```sh
./restore.sh </path/to/monitor/> </path/to/quarantined/>
```

Replacing each of the required parameter placeholders with actual arguments.


#### One-shot Scan (Cron Script)

First, make sure the script is executable:

```sh
chmod +x ./antivirus-cron.sh
```

Then run:
```sh
./antivirus-cron.sh </path/to/monitor/> </path/to/quarantined/>
```

Replacing each of the required parameter placeholders with actual arguments.

#### Cron Job

First, make sure the script is executable:

```sh
chmod +x ./antivirus-cron.sh
```

Make sure `cron` or `cronie` is installed and its service is running, for Ubuntu systems:
```sh
sudo apt install cron
sudo systemctl enable cron
sudo systemctl start cron
```

Optionally, add your user to the `/etc/cron.allow` file
```sh
(grep -v '^'"$(id -u --name)"'$' /etc/cron.allow; echo $(id -u --name)) | sudo tee /etc/cron.allow
```

Prepare the installation folder at `/opt/antivirus/`
```sh
sudo mkdir -p /opt/antivirus/quarantine
sudo cp ./antivirus-cron.sh /opt/antivirus/antivirus
```

Optionally add the allow-listing behavior:

```sh
chmod +x ./restore.sh
sudo cp ./restore.sh /opt/antivirus/restore
```

Optionally, add `/opt/antivirus/` to `PATH`.

Then open the crontab editor:
```sh
sudo crontab -e
```

You may omit `sudo` if the permissions of the install location allow `rwx` for your user.

Finally, add the cron job based on the install location (`/opt/antivirus/` in this case):
```sh
* * * * * cd /opt/antivirus && ./antivirus </path/to/monitor/> ./quarantine
```


## Flagging Rules

Inside the antivirus shell scripts, the following snippet exists to serve as the base for the flagging logic:

```sh
FLAGGED_EXT=("exe" "bat" "vbs" "scr" "ps1")
FLAGGED_CONTENT=("virus" "trojan" "malware" "worm" "ransomware")
FLAGGED_EXT_REGEX="\.($(IFS="|"; echo "${FLAGGED_EXT[*]}"))$"
FLAGGED_CONTENT_REGEX="($(IFS="|"; echo "${FLAGGED_CONTENT[*]}"))"
```

These define two arrays: `FLAGGED_EXT` and `FLAGGED_CONTENT`, and a regex for detecting them.

`FLAGGED_EXT` is a list of extensions to detect if a file is malicious.\
`FLAGGED_CONTENT` is a list of strings to search for inside files to detect if it's malicious.

The regex strings use bash's array substitution and token joining using the `IFS` variable defined to inject the extended regex OR operator `|` between tokens instead of the default whitespace.

For the filename extensions, a single escaped dot `\.` precedes the actual extensions placed in an OR'd pattern.


## Cron Job Interval Setup

The default `cron.env` for the install script is fitted with an interval that runs every 1min 23s by running every minute then sleeping for 23s as part of the run command before continuing with the execution. These variables are then used by the setup script:
```sh
INTERVAL="* * * * *"
PRE_RUN="sleep 23 &&"
```

> [!Important]
> The lab requires answering this question: "What the cron expression should be to run this scan every 3rd Friday of the month at 12:31 am?"

The answer is the interval can be `31 0 * * 5` which will satisfy all the requiremenets except "**3rd** Friday". According to https://croncalculator.com/?cron=31+0+15-21+*+5, to achieve this effect one of the day checks should be delegated to the running command or script. 

Each of the two checks is a simple use of `date` and an early exit, i.e either:
- `31 0 * * 5 if [ $(date +%e) -lt 15 ] || [ $(date +%e) -gt 21 ]; then exit; fi; <COMMAND>`: runs every Friday (4 times), exits if it's not the third Friday (within the 15th and 21st of the month); or
- `31 0 15-21 * * if [ $(date +%w) -ne 5 ]; then exit; fi; <COMMAND>`: runs every day within the third week (7 times), exists if it's not a Friday (the 5th day from Sunday as the 0th day)

## Allowlist Checking

The antivirus scripts expect a file `allowlist` under the current working directory, containing a newline-separated list of all allow-listed files. The list is appended to by the restore tool.

While looping on files that got flagged to take action on them, the antivirus scripts first check if the file is allow-listed to skip that iteration instead.

The check looks like this:
```sh
if [[ -r "$ALLOWLIST_FILE" ]]; then
    if grep -Fqx "$file" < "$ALLOWLIST_FILE"; then continue; fi
fi
```

It first checks if the `allowlist` file exists and is readable, then checks if its contents contain a match against the current iteration's `$file` with the following rules:
- `-x`: whole line match - `test.vbs` should not match `login_test.vbs`
- `-q`: quiet to avoid dumping matches in running shell
- `-F`: string match mode - to not treat file name characters as part of a regular expression (e.g a dot `.` is now matched at a literal level)

This check is done every loop iteration as a pre-emptive measure to a more concurrent operation mode implementation, even though the lab manual specifically mentioned separate scripts' operation is assumed to be non-concurrent.