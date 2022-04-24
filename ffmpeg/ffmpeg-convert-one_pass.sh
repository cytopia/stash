#!/usr/bin/env bash

set -e
set -u
set -o pipefail



###
### ffmpeg definitions
###
CRF=23          # End file size in MB
AUDIO_KB=128    # Desired audio bitrate
RESOLUTION=480  # Desired output resolution
FRAMES=30       # Output frame rate
PRESET=slow     # FFMPEG preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow)


###
### Check required tools
###
if ! command -v ffmpeg >/dev/null 2>&1; then
	>&2 echo "Error, 'ffmpeg' binary required, but not found."
	exit 1
fi
if ! command -v ffprobe >/dev/null 2>&1; then
	>&2 echo "Error, 'ffprobe' binary required, but not found."
	exit 1
fi


###
### Check command line arguments
###
if [ "${#}" -ne "1" ]; then
	>&2 echo "Error, you must specify a directory."
	>&2 echo "Usage ${0} <dir>"
	exit 1
fi
if [ ! -d "${1}" ]; then
	>&2 echo "Error, ${1} not a directory."
	>&2 echo "Usage ${0} <dir>"
	exit 1
fi

DIRECTORY="${1}"


###
### Loop over files in directory and convert
###
/bin/ls -1 "${DIRECTORY}" | grep -iE '\.(mov|avi|mp4)$' | while read -r filename; do

	# Show info
	echo "${filename} [len: ${SECONDS}sec | resolution: ${RESOLUTION}x | crf: ${CRF} | frames: ${FRAMES}]"

	ffmpeg -nostdin -y \
		-i "${filename}" \
		-c:v libx265 \
		-preset ${PRESET} \
		-vf scale=${RESOLUTION}:-1 \
		-crf "${CRF}" \
		\
		-c:a aac \
		-b:a ${AUDIO_KB}k \
		\
		-movflags faststart \
		-filter:a "volume=30dB" \
		-filter:v fps=fps=${FRAMES} \
		\
		"${filename}-${RESOLUTION}-crf${CRF}-fps${FRAMES}.mp4"
done
