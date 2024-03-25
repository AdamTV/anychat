#!/bin/bash
path_to_pubspec="/mnt/d/source/repos/flutter/anychat/pubspec.yaml";
dos2unix $path_to_pubspec
current_version=$(awk '/^version:/ {print $2}' $path_to_pubspec);
current_version_without_build=$(echo "$current_version" | sed 's/\+.*//');
revisionoffset=9;
gitcount=`git log | grep "^commit" | wc -l | xargs`;
let gitcount = $gitcount + $revisionoffset;
new_version="$current_version_without_build+$gitcount";
echo "Setting pubspec.yaml version $current_version to $new_version";
sed -i "s/version: $current_version/version: $new_version/g" $path_to_pubspec;