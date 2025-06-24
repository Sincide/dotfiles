#!/usr/bin/env fish

set suffix "[H264]"
set device "/dev/dri/renderD128"
set bitrate "3000k"
set cwd (pwd)

echo "🎬 Scanning for .mkv files in: $cwd"

for file in (find "$cwd" -type f -iname "*.mkv")
    echo "🔍 Checking: $file"

    if string match -q "*$suffix*" "$file"
        echo "⏭️  Skipping already converted: $file"
        continue
    end

    set dir (dirname "$file")
    set base (basename "$file" .mkv)
    set output "$dir/$base $suffix.mkv"

    echo "🎞️  Converting: $file"
    ffmpeg -y \
      -hwaccel vaapi -vaapi_device $device \
      -i "$file" \
      -vf 'format=nv12,hwupload' \
      -c:v h264_vaapi -b:v $bitrate \
      -c:a copy \
      "$output"

    echo "✅ Finished: $output"
end

echo "🎉 All files in $cwd processed!"
