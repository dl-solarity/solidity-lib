#!/usr/bin/env bash

local_version=$(node -p "require('./package.json').version")
registry_version=$(npm view $(node -p "require('./package.json').name") version)

IFS='.' read -a local_version_array <<< $local_version
IFS='.' read -a registry_version_array <<< $registry_version

version_changed="NOT_CHANGED"

if [[ ${local_version_array[0]} -gt ${registry_version_array[0]} ]]; then
  version_changed="MAJOR"
elif [[ ${local_version_array[1]} -gt ${registry_version_array[1]} ]]; then
   version_changed="MINOR"
elif [[ ${local_version_array[2]} -gt ${registry_version_array[2]} ]]; then
   version_changed="PATCH"
fi

echo "::set-output name=local_version::$local_version"
echo "::set-output name=version_changed::$version_changed"
