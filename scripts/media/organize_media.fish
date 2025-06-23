#!/usr/bin/env fish

set dryrun 0
if test (count $argv) -gt 0
    if test "$argv[1]" = "--dry-run"
        set dryrun 1
    end
end

set root_dir "/mnt/Media"
set tmp_dir "$root_dir/.staging"
set logfile "$HOME/filebot.log"

function log
    echo (date "+%F %T")" – $argv" >> $logfile
end

function notify
    echo "💬 $argv"
    log "$argv"
end

# Ensure critical libs for FileBot
set missing_libs ""
if not test -e /usr/lib/libmediainfo.so -o -e /usr/lib64/libmediainfo.so -o -e /usr/lib/x86_64-linux-gnu/libmediainfo.so
    set missing_libs "$missing_libs libmediainfo"
end
if not command -v filebot >/dev/null
    echo "❌ FileBot not found in PATH"
    exit 1
end
if not test -e /usr/lib/libzen.so -o -e /usr/lib64/libzen.so -o -e /usr/lib/x86_64-linux-gnu/libzen.so
    set missing_libs "$missing_libs libzen"
end
if test -n "$missing_libs"
    echo "⚠️  Missing:$missing_libs. FileBot might fail. Run: yay -S$missing_libs"
end

# Init
log "Cleaning up media volume..."
mkdir -p $tmp_dir

# Find and move new media/subtitle files (min size 200MB)
set moved 0
for f in (find $root_dir -mindepth 1 -maxdepth 4 \
    \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \
     -o -iname "*.flac" -o -iname "*.mp3" -o -iname "*.srt" \) \
    -size +200M -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*")
    mv -vn "$f" "$tmp_dir" && set moved 1
end

# Fallback: lone subtitles in folders with a single SRT
for dir in (find $root_dir -mindepth 1 -maxdepth 4 -type d \
    -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*")
    set srts (find $dir -maxdepth 1 -iname "*.srt")
    if test (count $srts) -eq 1
        mv -vn $srts[1] "$tmp_dir" && set moved 1
    end
end

# Delete junk files (trailers, images, etc)
find $root_dir -mindepth 1 -maxdepth 4 \
    \( -iname "*.nfo" -o -iname "*.sfv" -o -iname "*.txt" -o -iname "*.url" \
     -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.sample*" \
     -o -iname "*.rar" \) \
    -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*" -delete

# Delete empty folders
find $root_dir -mindepth 1 -maxdepth 4 -type d -empty \
    -not -path "$root_dir/Movies" -not -path "$root_dir/TV Shows" -delete

if test $moved -eq 0
    notify "No new media files found. Nothing to process."
    exit 0
end

# Separate TV shows from movies
set tv_files
set movie_files
set audio_files

for f in (find "$tmp_dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \))
    # Check for TV show patterns (S##E##, ##x##, etc.)
    if string match -rq '(?i).*[.\s_-](s\d{1,2}e\d{1,2}|\d{1,2}x\d{1,2}|season[.\s_-]?\d+|episode[.\s_-]?\d+)' (basename "$f")
        set tv_files $tv_files "$f"
    else
        set movie_files $movie_files "$f"
    end
end

# Audio files (music)
set audio_files (find "$tmp_dir" -type f \( -iname "*.flac" -o -iname "*.mp3" \))

# Set action based on dry run
if test $dryrun -eq 1
    set action "test"
else
    set action "move"
end

# Process TV Shows
if test (count $tv_files) -gt 0
    notify "📺 Processing TV Shows..."
    filebot -rename $tv_files \
        --output "$root_dir" \
        --action $action \
        --conflict auto \
        --db TheTVDB \
        --format "TV Shows/{n}/Season {s}/{n} - {s00e00} - {t}" \
        --log-file "$logfile" \
        --mode interactive \
        --apply prune
    
    if test $status -ne 0
        notify "❌ TV Show processing failed"
    else
        notify "✅ TV Shows processed successfully"
    end
end

# Process Movies
if test (count $movie_files) -gt 0
    notify "🎬 Processing Movies..."
    filebot -rename $movie_files \
        --output "$root_dir" \
        --action $action \
        --conflict auto \
        --db TheMovieDB \
        --format "Movies/{n} ({y})/{n} ({y})" \
        --log-file "$logfile" \
        --mode interactive \
        --apply prune
    
    if test $status -ne 0
        notify "❌ Movie processing failed"
    else
        notify "✅ Movies processed successfully"
    end
end

# Process Audio Files
if test (count $audio_files) -gt 0
    notify "🎵 Processing Audio Files..."
    filebot -rename $audio_files \
        --output "$root_dir" \
        --action $action \
        --conflict auto \
        --db AudioDB \
        --format "Music/{artist}/{album}/{artist} - {t}" \
        --log-file "$logfile" \
        --mode interactive \
        --apply prune
    
    if test $status -ne 0
        notify "❌ Audio processing failed"
    else
        notify "✅ Audio files processed successfully"
    end
end

# Cleanup if staging is empty
if test -d "$tmp_dir"
    if not test (find "$tmp_dir" -mindepth 1 2>/dev/null | head -1)
        log "Cleaning up empty staging dir..."
        rm -rf "$tmp_dir"
        echo "✅ Staging directory cleaned"
    else
        echo "⚠️  Staging not empty – left untouched: $tmp_dir"
    end
else
    echo "✅ Staging directory already cleaned up"
end

notify "✅ Done."
