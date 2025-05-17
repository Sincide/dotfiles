#!/usr/bin/env bash

# File preview script for Yazi
# Handles different file types with appropriate tools
file="$1"
width="$2"
height="$3"
x="$4"
y="$5"

# Function to check if command exists
has() {
    command -v "$1" > /dev/null 2>&1
}

# Get mimetype
mimetype=$(file --mime-type -b "$file")

# Image preview
if [[ "$mimetype" =~ ^image/ ]]; then
    if has ueberzug; then
        ueberzug layer --silent --parse bash < <(
            echo -e "update\nid=$id\nx=$x\ny=$y\npath=$file\nheight=$height\nwidth=$width\n"
        )
        exit 1
    elif has kitty; then
        kitty +kitten icat --silent --clear --transfer-mode file --place "${width}x${height}@${x}x${y}" "$file"
        exit 1
    elif has viu; then
        viu -w "$width" -h "$height" "$file"
        exit 0
    fi
fi

# Video thumbnail
if [[ "$mimetype" =~ ^video/ ]]; then
    if has ffmpegthumbnailer; then
        thumbnail=$(mktemp /tmp/yazi-thumb.XXXXX.jpg)
        ffmpegthumbnailer -i "$file" -o "$thumbnail" -s 0 -q 5
        if has kitty; then
            kitty +kitten icat --silent --clear --transfer-mode file --place "${width}x${height}@${x}x${y}" "$thumbnail"
            rm "$thumbnail"
            exit 1
        elif has ueberzug; then
            ueberzug layer --silent --parse bash < <(
                echo -e "update\nid=$id\nx=$x\ny=$y\npath=$thumbnail\nheight=$height\nwidth=$width\n"
            )
            rm "$thumbnail"
            exit 1
        elif has viu; then
            viu -w "$width" -h "$height" "$thumbnail"
            rm "$thumbnail"
            exit 0
        fi
    fi
fi

# Audio metadata
if [[ "$mimetype" =~ ^audio/ ]]; then
    if has exiftool; then
        exiftool "$file"
        exit 0
    elif has mediainfo; then
        mediainfo "$file"
        exit 0
    fi
fi

# Text preview with syntax highlighting
if [[ "$mimetype" =~ ^text/ ]] || [[ "$mimetype" == "application/json" ]] || [[ "$file" =~ \.(md|conf|ini|yaml|yml|toml)$ ]]; then
    if has bat; then
        bat --color=always --style=plain --line-range :200 "$file"
        exit 0
    elif has highlight; then
        highlight -O ansi --line-range=1-200 "$file"
        exit 0
    elif has cat; then
        cat "$file"
        exit 0
    fi
fi

# Archive preview
if [[ "$mimetype" =~ ^application/(zip|x-rar|x-tar|x-gzip|x-bzip2) ]] || [[ "$file" =~ \.(zip|tar|gz|bz2|xz)$ ]]; then
    if has atool; then
        atool --list -- "$file"
        exit 0
    elif has als; then
        als "$file"
        exit 0
    elif has bsdtar; then
        bsdtar --list --file "$file"
        exit 0
    elif has tar; then
        tar -tvf "$file"
        exit 0
    elif has unzip; then
        unzip -l "$file"
        exit 0
    fi
fi

# PDF preview
if [[ "$mimetype" == "application/pdf" ]]; then
    if has pdftotext; then
        pdftotext -l 10 -nopgbrk -q -- "$file" -
        exit 0
    elif has exiftool; then
        exiftool "$file"
        exit 0
    fi
fi

# Office documents
if [[ "$mimetype" =~ ^application/(msword|vnd.openxmlformats-officedocument|vnd.oasis.opendocument) ]]; then
    if has pandoc; then
        pandoc -s -t markdown -- "$file"
        exit 0
    elif has exiftool; then
        exiftool "$file"
        exit 0
    fi
fi

# Fallback to file command if nothing worked
file -b "$file"
exit 0 