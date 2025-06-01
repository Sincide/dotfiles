#!/bin/sh

# File preview script for lf.

# Dependencies:
# - file
# - bat/cat
# - chafa/viu/catimg/timg (optional, for images)
# - ueberzug (optional, for images)
# - pistol (optional, for enhanced previews)

set -C -f
IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"

image() {
    if type chafa > /dev/null 2>&1; then
        chafa --fill=block --symbols=block -c 256 -s 80x"${HEIGHT}" "${1}"
        exit 0
    elif type viu > /dev/null 2>&1; then
        viu -t "${1}"
        exit 0
    elif type catimg > /dev/null 2>&1; then
        catimg -w 100 "${1}"
        exit 0
    elif type timg > /dev/null 2>&1; then
        timg "${1}"
        exit 0
    fi
}

# Check for Pistol
if type pistol > /dev/null 2>&1; then
    pistol "${1}"
    exit 0
fi

# Check MIME type
FILE_EXTENSION="${1##*.}"
MIME_TYPE=$(file --brief --mime-type "${1}")

case "${MIME_TYPE}" in
    image/*)
        image "${1}"
        ;;
    text/* | */xml | */json)
        if type bat > /dev/null 2>&1; then
            bat --color=always --style=plain --pager=never "${1}"
        else
            cat "${1}"
        fi
        ;;
    audio/* | video/*)
        if type mediainfo > /dev/null 2>&1; then
            mediainfo "${1}"
        else
            echo "${MIME_TYPE}"
        fi
        ;;
    application/pdf)
        if type pdftotext > /dev/null 2>&1; then
            pdftotext -l 10 -nopgbrk -q -- "${1}" -
        else
            echo "PDF file: ${1}"
        fi
        ;;
    application/zip | application/x-rar | application/x-7z-compressed | \
    application/x-tar | application/x-bzip2 | application/x-gzip | application/x-xz)
        if type als > /dev/null 2>&1; then
            als "${1}"
        elif type atool > /dev/null 2>&1; then
            atool --list -- "${1}"
        elif type bsdtar > /dev/null 2>&1; then
            bsdtar --list --file "${1}"
        else
            echo "Archive file: ${1}"
        fi
        ;;
    *)
        echo "File type: ${MIME_TYPE}"
        if type hexyl > /dev/null 2>&1; then
            hexyl --length 256 "${1}"
        fi
        ;;
esac

exit 0 