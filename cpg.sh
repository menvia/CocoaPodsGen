#!/bin/sh

# Script to generate Cocoapods new lib versions and submit to your Cocoapods Spec repo 
# Copyright (C) 2016 Menvia - All Rights Reserved
# Permission to copy and modify is granted under the Apache License, Version 2.0
# Version 0.0.2 - Last revised 2016.07.12

# Parse YAML files for CocoaPodsGen config file
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# read yaml file
eval $(parse_yaml cpg.yml "config_")

# Check COCOAPODS_DIR local environment
 if [ -z ${COCOAPODS_DIR+x} ]; then
	printf "You need to first setup your CocoaPods Specs dir to run CocoaPodsGen.\nPlease enter the full path for your CocoaPods Specs repo: "
	read COCOAPODS_DIR
	export COCOAPODS_DIR
	printf "\n\n#CocoaPods Specs directory to be used by CocoaPodsGen script\nexport COCOAPODS_DIR=\"${COCOAPODS_DIR}\"\n" >>~/.bash_profile
fi

# Get directories and files path
PROJECT_DIR=$config_plist_dir
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLIST_FILE="${CURRENT_DIR}/${PROJECT_DIR}/Info.plist"
COCOAPODS_PROJ_DIR="${COCOAPODS_DIR}/${PROJECT_DIR}/"

# TODO: Find the .plist file automatically
# find . -name '*Info.plist' -print

# Get current lib version
git pull
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PLIST_FILE}")
echo "Your current library version is: ${VERSION}"

# Generate new lib version
printf "Are you generating a MAJOR[0], MINOR[1] or FIX[2] version? -> "
read NEW_VERSION_TYPE
NEW_VERSION=""
IFS='.' read -ra VERSION_N <<< "$VERSION"
for i in "${!VERSION_N[@]}"; do
	# Increment all numbers accordingly
    if [[ $i < $NEW_VERSION_TYPE ]]; then
    	NEW_VERSION_N=${VERSION_N[$i]}
	elif  [[ $i == $NEW_VERSION_TYPE ]]; then
    	NEW_VERSION_N=$((${VERSION_N[$i]}+1))
	else
    	NEW_VERSION_N=0
	fi

	# Contcat numbers
    if [[ $i != 0 ]]; then
		NEW_VERSION_N=".${NEW_VERSION_N}"
    fi
	NEW_VERSION="${NEW_VERSION}${NEW_VERSION_N}"

done
echo "Your new library version will be: ${NEW_VERSION}"

# Ensure the version is the right one
printf "Type YES to generate the new Cocoapods version -> "
read YES
if [[ ${YES} == "YES" ]]; then
	#Update your code, open the project definition and increment the lib version (e.g.: 0.4.11)
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" "${PLIST_FILE}"

	#Push your code to the remote repo
	git add "${PLIST_FILE}"
	git commit -m"Version ${NEW_VERSION}"
	git push

	#Add a git tag with the same name of the new version
	git tag ${NEW_VERSION}

	#Push the tag to the repo
	git push origin ${NEW_VERSION}

	#Now open the local repo for the Menvia cocoa-pods-specs
	#Open the folder corresponding to the lib you just updated (e.g.: cd FarolEventsSDK)
	#Copy the last version folder for the new version you just released (e.g.: )
	git -C ${COCOAPODS_DIR} pull
	cp -r "${COCOAPODS_PROJ_DIR}0.0.0/" "${COCOAPODS_PROJ_DIR}${NEW_VERSION}/"

	#Open the folder you just created and open the .podspec file  (e.g.: FarolEventsSDK.podspec)
	#Update the s.version attribute to the new version (e.g.: s.version = "0.4.11")
	SEARCH="s.version = \"0.0.0\""
	REPLACE="s.version = \"${NEW_VERSION}\""
	sed -i "" "s|${SEARCH}|${REPLACE}|g" "${COCOAPODS_PROJ_DIR}${NEW_VERSION}/${PROJECT_DIR}.podspec"

	#It is also possible to validate the podspec file created (e.g.: pod repo lint .) 
	#Save Podspec file and add to the repo pod (e.g.: repo push FarolEventsSDK FarolEventsSDK.podspec)
	git -C ${COCOAPODS_DIR} add "${COCOAPODS_PROJ_DIR}${NEW_VERSION}/"
	git -C ${COCOAPODS_DIR} commit -m"[Update] ${PROJECT_DIR} (${NEW_VERSION})"
	git -C ${COCOAPODS_DIR} push

	#Done, now you can pod update, pod install your lib version on any project
	printf "Done!\n"
else 
	printf "Abort mission!\n"
fi
