#!/bin/bash

# Check for attempted log ons
grep sshd /var/log/secure | grep 'Accepted password for' | sed 's/^.*: Accepted/Accepted/' | sed 's/port.*$//' | sort | uniq > $LOMcacheDir/loggedin.dat
grep sshd /var/log/secure | grep 'Failed password for' | sed 's/^.*: Failed/Failed/' | sed 's/port.*$//' | sort | uniq > $LOMcacheDir/failedlogin.dat
