#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### How much volume of the audio track
###
VOLUME=0.2



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
if [ "${#}" -ne "2" ]; then
	>&2 echo "Usage ${0} <path/to/video> <path/to/audio>"
	exit 1
fi
if [ ! -f "${1}" ]; then
	>&2 echo "Usage ${0} <path/to/video> <path/to/audio>"
	exit 1
fi
if [ ! -f "${2}" ]; then
	>&2 echo "Usage ${0} <path/to/video> <path/to/audio>"
	exit 1
fi

VIDEO="${1}"
AUDIO="${2}"

EXT="$( echo "${VIDEO}" | awk -F'.' '{print $NF}' )"


# Add audio song to file
ffmpeg -nostdin -y \
	-i "${VIDEO}" \
	-i "${AUDIO}" \
	-filter_complex "[0:a]volume=1[a0];[1:a]volume=${VOLUME}[a1];[a0][a1]amerge=inputs=2[a]" \
	-map 0:v \
	-map "[a]" \
	-c:v copy \
	-ac 2 \
	-shortest \
	"${VIDEO}-song.${EXT}"
