# Linux monitoring app for scanning changes
#Global settings
export LOMworkingDirectory=/etc/Lomnitor
export LOMcacheDir=$workingDirectory/cache

# File checking
./fileCheck.sh

# Port scan
	# List of established connections

# Process scan
	# List of known running services

# Log file scan for intrusion
	# Checks ssh access, or other port access initiated
./logScan.sh
