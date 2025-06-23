#!/usr/bin/env fish

set dryrun 0
set debug 0

# Parse command line arguments
for arg in $argv
    switch $arg
        case "--dry-run"
            set dryrun 1
        case "--debug"
            set debug 1
        case "*"
            echo "❌ Unknown argument: $arg"
            echo "Usage: $argv[0] [--dry-run] [--debug]"
            exit 1
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

function debug_log
    if test $debug -eq 1
        echo "🔍 DEBUG: $argv"
        log "DEBUG: $argv"
    end
end

function debug_section
    if test $debug -eq 1
        echo ""
        echo "🔍 === DEBUG SECTION: $argv ==="
        log "DEBUG SECTION: $argv"
    end
end

# Show debug info at start
if test $debug -eq 1
    echo "🔍 DEBUG MODE ENABLED"
    echo "🔍 Root directory: $root_dir"
    echo "🔍 Staging directory: $tmp_dir"
    echo "🔍 Log file: $logfile"
    echo "🔍 Dry run: $dryrun"
    echo ""
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

debug_log "Dependency check completed. Missing libs: $missing_libs"

# Init
log "Cleaning up media volume..."
mkdir -p $tmp_dir
debug_log "Created staging directory: $tmp_dir"

# Find and move new media/subtitle files (min size 150MB)
debug_section "SEARCHING FOR MEDIA FILES"
set moved 0
set found_files

debug_log "Searching for media files in: $root_dir (maxdepth 4)"
debug_log "Excluding paths: Movies/*, TV Shows/*, $tmp_dir/*"

for f in (find $root_dir -mindepth 1 -maxdepth 4 \
    \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \
     -o -iname "*.flac" -o -iname "*.mp3" -o -iname "*.srt" \) \
    -size +150M -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*" -not -path "$tmp_dir/*")
    
    set found_files $found_files "$f"
    debug_log "Found file: $f"
end

debug_log "Total files found: "(count $found_files)

for f in $found_files
    debug_log "Moving: $f -> $tmp_dir"
    if mv -vn "$f" "$tmp_dir"
        set moved 1
        debug_log "✅ Successfully moved: $f"
    else
        debug_log "❌ Failed to move: $f"
    end
end

# Fallback: lone subtitles in folders with a single SRT
debug_section "SEARCHING FOR LONE SUBTITLES"
set subtitle_dirs
for dir in (find $root_dir -mindepth 1 -maxdepth 4 -type d \
    -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*" -not -path "$tmp_dir/*")
    set subtitle_dirs $subtitle_dirs "$dir"
end

debug_log "Checking "(count $subtitle_dirs)" directories for lone subtitles"

for dir in $subtitle_dirs
    set srts (find $dir -maxdepth 1 -iname "*.srt")
    if test (count $srts) -eq 1
        debug_log "Found lone subtitle in $dir: $srts[1]"
        if mv -vn $srts[1] "$tmp_dir"
            set moved 1
            debug_log "✅ Successfully moved subtitle: $srts[1]"
        else
            debug_log "❌ Failed to move subtitle: $srts[1]"
        end
    end
end

# Delete junk files (trailers, images, etc)
debug_section "CLEANING JUNK FILES"
set junk_patterns "*.nfo" "*.sfv" "*.txt" "*.url" "*.jpg" "*.jpeg" "*.png" "*.sample*" "*.rar"
debug_log "Searching for junk files with patterns: $junk_patterns"

set junk_files (find $root_dir -mindepth 1 -maxdepth 4 \
    \( -iname "*.nfo" -o -iname "*.sfv" -o -iname "*.txt" -o -iname "*.url" \
     -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.sample*" \
     -o -iname "*.rar" \) \
    -not -path "$root_dir/Movies/*" -not -path "$root_dir/TV Shows/*" -not -path "$tmp_dir/*")

debug_log "Found "(count $junk_files)" junk files to delete"

for junk in $junk_files
    debug_log "Deleting junk: $junk"
    rm -f "$junk"
end

# Delete empty folders
debug_section "CLEANING EMPTY FOLDERS"
set empty_dirs (find $root_dir -mindepth 1 -maxdepth 4 -type d -empty \
    -not -path "$root_dir/Movies" -not -path "$root_dir/TV Shows" -not -path "$tmp_dir")

debug_log "Found "(count $empty_dirs)" empty directories to delete"

for empty_dir in $empty_dirs
    debug_log "Deleting empty directory: $empty_dir"
    rmdir "$empty_dir"
end

if test $moved -eq 0
    notify "No new media files found. Nothing to process."
    debug_log "No files moved to staging, exiting"
    exit 0
end

debug_section "ANALYZING STAGING FILES"
# Show what's in staging
set staging_files (find "$tmp_dir" -type f)
debug_log "Files in staging directory:"
for f in $staging_files
    debug_log "  - $f"
end

# Separate TV shows from movies
set tv_files
set movie_files
set audio_files

debug_log "Analyzing file types..."

for f in (find "$tmp_dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \))
    set filename (basename "$f")
    debug_log "Analyzing video file: $filename"
    
    # Check for TV show patterns (S##E##, ##x##, etc.)
    if string match -rq '(?i).*[.\s_-](s\d{1,2}e\d{1,2}|\d{1,2}x\d{1,2}|season[.\s_-]?\d+|episode[.\s_-]?\d+)' "$filename"
        set tv_files $tv_files "$f"
        debug_log "  → Classified as TV SHOW: $filename"
    else
        set movie_files $movie_files "$f"
        debug_log "  → Classified as MOVIE: $filename"
    end
end

# Audio files (music)
set audio_files (find "$tmp_dir" -type f \( -iname "*.flac" -o -iname "*.mp3" \))
for f in $audio_files
    debug_log "Found audio file: "(basename "$f")
end

debug_log "Classification complete:"
debug_log "  TV Shows: "(count $tv_files)
debug_log "  Movies: "(count $movie_files)
debug_log "  Audio: "(count $audio_files)

# Set action based on dry run
if test $dryrun -eq 1
    set action "test"
    debug_log "Using FileBot action: test (dry run)"
else
    set action "move"
    debug_log "Using FileBot action: move"
end

# Process TV Shows
if test (count $tv_files) -gt 0
    debug_section "PROCESSING TV SHOWS"
    notify "📺 Processing TV Shows..."
    
    # Process in batches of 10 files
    set batch_size 10
    set total_tv_files (count $tv_files)
    set processed 0
    set failed 0
    
    debug_log "Processing $total_tv_files TV files in batches of $batch_size"
    
    for i in (seq 1 $batch_size $total_tv_files)
        set end_index (math "min($i + $batch_size - 1, $total_tv_files)")
        set current_batch $tv_files[$i..$end_index]
        set batch_number (math "($i - 1) / $batch_size + 1")
        set batch_count (count $current_batch)
        
        debug_log "Processing batch $batch_number ($batch_count files):"
        for f in $current_batch
            debug_log "  - "(basename "$f")
        end
        
        debug_log "FileBot command for TV batch $batch_number:"
        debug_log "  filebot -rename $current_batch --output $root_dir --action $action --db TheTVDB --format 'TV Shows/{n}/Season {s}/{n} - {s00e00} - {t}'"
        
        filebot -rename $current_batch \
            --output "$root_dir" \
            --action $action \
            --conflict auto \
            --db TheTVDB \
            --format "TV Shows/{n}/Season {s}/{n} - {s00e00} - {t}" \
            --log-file "$logfile" \
            --mode interactive \
            --apply prune
        
        set batch_status $status
        debug_log "FileBot TV batch $batch_number exit status: $batch_status"
        
        if test $batch_status -eq 0
            set processed (math "$processed + $batch_count")
            debug_log "✅ TV batch $batch_number processed successfully ($batch_count files)"
        else
            set failed (math "$failed + $batch_count")
            debug_log "❌ TV batch $batch_number failed with status: $batch_status"
        end
    end
    
    debug_log "TV Show processing summary: $processed processed, $failed failed out of $total_tv_files total"
    
    if test $failed -eq 0
        notify "✅ TV Shows processed successfully ($processed files)"
    else
        notify "⚠️  TV Shows partially processed: $processed/$total_tv_files files successful, $failed failed"
    end
end

# Process Movies
if test (count $movie_files) -gt 0
    debug_section "PROCESSING MOVIES"
    notify "🎬 Processing Movies..."
    
    # Process in batches of 10 files
    set batch_size 10
    set total_movie_files (count $movie_files)
    set processed 0
    set failed 0
    
    debug_log "Processing $total_movie_files movie files in batches of $batch_size"
    
    for i in (seq 1 $batch_size $total_movie_files)
        set end_index (math "min($i + $batch_size - 1, $total_movie_files)")
        set current_batch $movie_files[$i..$end_index]
        set batch_number (math "($i - 1) / $batch_size + 1")
        set batch_count (count $current_batch)
        
        debug_log "Processing movie batch $batch_number ($batch_count files):"
        for f in $current_batch
            debug_log "  - "(basename "$f")
        end
        
        debug_log "FileBot command for movie batch $batch_number:"
        debug_log "  filebot -rename $current_batch --output $root_dir --action $action --db TheMovieDB --format 'Movies/{n} ({y})/{n} ({y})'"
        
        filebot -rename $current_batch \
            --output "$root_dir" \
            --action $action \
            --conflict auto \
            --db TheMovieDB \
            --format "Movies/{n} ({y})/{n} ({y})" \
            --log-file "$logfile" \
            --mode interactive \
            --apply prune
        
        set batch_status $status
        debug_log "FileBot movie batch $batch_number exit status: $batch_status"
        
        if test $batch_status -eq 0
            set processed (math "$processed + $batch_count")
            debug_log "✅ Movie batch $batch_number processed successfully ($batch_count files)"
        else
            set failed (math "$failed + $batch_count")
            debug_log "❌ Movie batch $batch_number failed with status: $batch_status"
        end
    end
    
    debug_log "Movie processing summary: $processed processed, $failed failed out of $total_movie_files total"
    
    if test $failed -eq 0
        notify "✅ Movies processed successfully ($processed files)"
    else
        notify "⚠️  Movies partially processed: $processed/$total_movie_files files successful, $failed failed"
    end
end

# Process Audio Files
if test (count $audio_files) -gt 0
    debug_section "PROCESSING AUDIO FILES"
    notify "🎵 Processing Audio Files..."
    
    # Process in batches of 10 files
    set batch_size 10
    set total_audio_files (count $audio_files)
    set processed 0
    set failed 0
    
    debug_log "Processing $total_audio_files audio files in batches of $batch_size"
    
    for i in (seq 1 $batch_size $total_audio_files)
        set end_index (math "min($i + $batch_size - 1, $total_audio_files)")
        set current_batch $audio_files[$i..$end_index]
        set batch_number (math "($i - 1) / $batch_size + 1")
        set batch_count (count $current_batch)
        
        debug_log "Processing audio batch $batch_number ($batch_count files):"
        for f in $current_batch
            debug_log "  - "(basename "$f")
        end
        
        debug_log "FileBot command for audio batch $batch_number:"
        debug_log "  filebot -rename $current_batch --output $root_dir --action $action --db AudioDB --format 'Music/{artist}/{album}/{artist} - {t}'"
        
        filebot -rename $current_batch \
            --output "$root_dir" \
            --action $action \
            --conflict auto \
            --db AudioDB \
            --format "Music/{artist}/{album}/{artist} - {t}" \
            --log-file "$logfile" \
            --mode interactive \
            --apply prune
        
        set batch_status $status
        debug_log "FileBot audio batch $batch_number exit status: $batch_status"
        
        if test $batch_status -eq 0
            set processed (math "$processed + $batch_count")
            debug_log "✅ Audio batch $batch_number processed successfully ($batch_count files)"
        else
            set failed (math "$failed + $batch_count")
            debug_log "❌ Audio batch $batch_number failed with status: $batch_status"
        end
    end
    
    debug_log "Audio processing summary: $processed processed, $failed failed out of $total_audio_files total"
    
    if test $failed -eq 0
        notify "✅ Audio files processed successfully ($processed files)"
    else
        notify "⚠️  Audio files partially processed: $processed/$total_audio_files files successful, $failed failed"
    end
end

# Cleanup if staging is empty
debug_section "CLEANUP STAGING DIRECTORY"
if test -d "$tmp_dir"
    set remaining_files (find "$tmp_dir" -mindepth 1 2>/dev/null)
    debug_log "Files remaining in staging: "(count $remaining_files)
    
    if test (count $remaining_files) -eq 0
        log "Cleaning up empty staging dir..."
        debug_log "Staging directory is empty, removing it"
        rm -rf "$tmp_dir"
        echo "✅ Staging directory cleaned"
        debug_log "Staging directory removed successfully"
    else
        echo "⚠️  Staging not empty – left untouched: $tmp_dir"
        debug_log "Staging directory not empty, leaving it untouched"
        for f in $remaining_files
            debug_log "  Remaining file: $f"
        end
    end
else
    echo "✅ Staging directory already cleaned up"
    debug_log "Staging directory doesn't exist (already cleaned)"
end

debug_section "SCRIPT COMPLETION"
notify "✅ Done."
debug_log "Script execution completed"
