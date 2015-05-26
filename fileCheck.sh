# Linux monitoring app for scanning changes

# binary file check
# get list of binaries. check that binary list file is ok. Get chksum for each binary. 
# scan system for binaries. If new ones,  alert user. update list if user ok. generate md5sum for new files. 
# perform md5 checks on files and compare to current. 
# do this by soritng both lists and preforming diff.

# File watcher variables
# list of your essential config files
fileList="files.conf" 

# auto generated file of binaries on your system
lastBinariesList="$LOMcacheDir/binaries-last.lst"
newBinariesList="$LOMcacheDir/binaries-current.lst"
appData="$LOMcacheDir/appChk.data"

if [[ ! -e $lastBinariesList ]]
then
	find / -type f -exec file {} \; >/tmp/last.bins
	grep ELF /tmp/last.bins | awk -F: '{print $1}' | sort  >$lastBinariesList

	# add chksum for this file to appChk.data
	md5sum $lastBinariesList > $appData
	
	# set md5 values and store in $lastBinariesList.md5
	for filename in $(cat $lastBinariesList)
	do
		md5sum $filename
	done >${lastBinariesList}.md5
else
	# check that appChk.data is genuine
	if (( $(md5sum $lastBinariesList) != $(<$appData) ))
	then
		echo "Binaries list has been tampered with, exiting."
		echo "System has either been hacked or you need to remove the appChk.data file"
		exit 1
	fi
	
	# check for new binaries
	find / -type f -exec file {} \; >/tmp/current.bins
	grep ELF /tmp/current.bins | awk -F: '{print $1}' | sort  >$newBinariesList
	rm  /tmp/current.bins
	
	# diff $newBinariesList $lastBinariesList to see if there are new files
	newFiles=$(diff $newBinariesList $lastBinariesList | grep '<')
	if [[ -n $newFiles ]]
	then
		echo "New binaries detected,  please check and verify they are ok. "
		echo "$newFiles"
		echo ""
		echo "Are these files ok (y/n): "
		read reponse
		
		if [[ "$response" == [nN]* ]]
		then
			echo "Exciting,  you should consider removing one of the new binaries or ask for further assistance from an administrator"
			exit 2
		fi
		
		echo "Adding new files to the list"
		for filename in $(echo "$newBinariesList")
		do
			md5sum $filename
		done >>${lastBinariesList}.md5
		sort ${lastBinariesList}.md5 >/tmp/tmpbin.lst
		mv /tmp/tmpbin.lst ${lastBinariesList}.md5
	fi
	
	# perform binaries check
	while read fileData
	do
		listedFile=$(echo "$fileData" | awk '{print $2}')
		chkSum=$(echo $"fileData" | awk '{print $1}' | sed 's/  *//g')
		if [[ $(md5 $listedFile | awk '{print $1}' | sed 's/  *//g') != $(chkSum) ]]
		then
			changedFiles="$changedFiles
$listedFile"
		fi
	done <${lastBinariesList}.md5
	changedFiles=$(echo "$changedFiles" | sed 's/[ 	]*//g')
fi

#show changed files
echo "The following files have changed since last run.  Please check the list; "
echo "$changedFiles"
echo -n "If all of the files above are ok then press 'y' else press any other key: "
read reponse
if [[ $response != [yY] ]]
then
	echo "You need to remove the files or reinstall software for the file or files that should not have changed in your list and then rerun this program. "
	exit 3
fi

if [[ -n $changedFiles ]]
then
	# update file list and md5s, cycle through existing md5 file and replace
	# ${lastBinariesList}.md5 must be updated
	for curFile in $(cat ${lastBinariesList}.md5)
	do
		listedFile=$(echo "$curFile" | awk '{print $2}')
		chkSum=$(echo $"curFile" | awk '{print $1}' | sed 's/  *//g')
		if echo "$changedFiles" | grep $listedFile >/dev/null 2>&1
		then
			md5 "$curFile"
		else
			echo "$curFile"
		done
	done >/tmp/lb.tmp.md5
	mv /tmp/lb.tmp.md5 ${lastBinariesList}.md5
fi
