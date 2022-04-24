#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### Check required tools
###
if ! command -v ffmpeg >/dev/null 2>&1; then
	>&2 echo "Error, 'ffmpeg' binary required, but not found."
	exit 1
fi


###
### Check command line arguments
###
if [ "${#}" -ne "1" ]; then
	>&2 echo "Usage ${0} <path/to/video>"
	exit 1
fi
if [ ! -f "${1}" ]; then
	>&2 echo "Usage ${0} <path/to/video>"
	exit 1
fi

VIDEO="${1}"
EXT="$( echo "${VIDEO}" | awk -F'.' '{print $NF}' )"

# Reduce noise
ffmpeg -nostdin -y \
	-i "${VIDEO}" \
	-af "afftdn=nf=-25" \
	-c:v copy \
	"${VIDEO}-reduced-noise.${EXT}"
