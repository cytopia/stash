#!/usr/bin/env bash

set -e
set -u
set -o pipefail



###
### ffmpeg definitions
###
SIZE_MB=60      # End file size in MB
AUDIO_KB=128    # Desired audio bitrate
RESOLUTION=800  # Desired output resolution
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
	>&2 echo "Error, you must specify a file or directory."
	>&2 echo "Usage ${0} <file/dir>"
	exit 1
fi
if [ ! -f "${1}" ] && [ ! -d "${1}" ]; then
	>&2 echo "Error, '${1}' is not a file or directory."
	>&2 echo "Usage ${0} <file/dir>"
	exit 1
fi
DIRECTORY="${1}"


###
### Loop over files in directory and convert
###
/bin/ls -1 "${DIRECTORY}" | grep -iE '\.(mov|avi|mp4)$' | while read -r filename; do
	SECONDS="$( \
		ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filename}" \
		| grep -Eo '^[0-9]+' \
	)"
	KBITS=$(( SIZE_MB * 8192 / SECONDS ))
	VIDEO_KB=$(( KBITS - AUDIO_KB ))

	# Show info
	echo "${filename} [len: ${SECONDS}sec | resolution: ${RESOLUTION}x | quality: ${VIDEO_KB}Kbit/s | frames: ${FRAMES}]"

	# Pass 1
	ffmpeg -nostdin -y \
		-i "${filename}" \
		-x265-params pass=1 \
		-preset ${PRESET} \
		\
		-c:v libx265 \
		-b:v ${VIDEO_KB}k \
		\
		-c:a aac \
		-b:a ${AUDIO_KB}k \
		\
		-filter:v "scale=${RESOLUTION}:-2:flags=lanczos, fps=fps=${FRAMES}" \
		\
		-f mp4 /dev/null \

	# Pass 2
	ffmpeg -nostdin -y \
		-i "${filename}" \
		-x265-params pass=2 \
		-preset ${PRESET} \
		-movflags faststart \
		\
		-c:v libx265 \
		-b:v ${VIDEO_KB}k \
		\
		-c:a aac \
		-b:a ${AUDIO_KB}k \
		\
		-filter:a "volume=30dB" \
		-filter:v "scale=${RESOLUTION}:-2:flags=lanczos, fps=fps=${FRAMES}" \
		\
		"${filename}-${RESOLUTION}-size${SIZE_MB}-fps${FRAMES}.mp4"
done
