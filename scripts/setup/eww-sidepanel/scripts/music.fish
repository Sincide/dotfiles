#!/usr/bin/env fish
# Music control script for EWW sidebar (Fish Shell)

switch $argv[1]
    case "title"
        # Get current song title
        if command -v playerctl >/dev/null 2>&1
            set title (playerctl metadata title 2>/dev/null)
            if test -z "$title"; or string match -q "No players found" $title
                echo "No Title"
            else
                echo $title
            end
        else
            echo "No Title"
        end
    
    case "artist"
        # Get current artist
        if command -v playerctl >/dev/null 2>&1
            set artist (playerctl metadata artist 2>/dev/null)
            if test -z "$artist"; or string match -q "No players found" $artist
                echo "No Artist"
            else
                echo $artist
            end
        else
            echo "No Artist"
        end
    
    case "status"
        # Get playback status
        if command -v playerctl >/dev/null 2>&1
            set status (playerctl status 2>/dev/null)
            switch $status
                case "Playing"
                    echo "Playing"
                case "Paused"
                    echo "Paused"
                case "*"
                    echo "Stopped"
            end
        else
            echo "Stopped"
        end
    
    case "album"
        # Get current album (bonus feature)
        if command -v playerctl >/dev/null 2>&1
            set album (playerctl metadata album 2>/dev/null)
            if test -z "$album"; or string match -q "No players found" $album
                echo "No Album"
            else
                echo $album
            end
        else
            echo "No Album"
        end
    
    case "position"
        # Get current position (bonus feature)
        if command -v playerctl >/dev/null 2>&1
            set position (playerctl position 2>/dev/null)
            if test -n "$position"
                # Convert to mm:ss format
                set position_int (string split '.' $position)[1]
                set minutes (math $position_int / 60)
                set seconds (math $position_int % 60)
                printf "%02d:%02d\n" $minutes $seconds
            else
                echo "00:00"
            end
        else
            echo "00:00"
        end
    
    case "length"
        # Get track length (bonus feature)
        if command -v playerctl >/dev/null 2>&1
            set length (playerctl metadata mpris:length 2>/dev/null)
            if test -n "$length"
                # Convert from microseconds to seconds, then to mm:ss
                set length_sec (math $length / 1000000)
                set minutes (math $length_sec / 60)
                set seconds (math $length_sec % 60)
                printf "%02d:%02d\n" $minutes $seconds
            else
                echo "00:00"
            end
        else
            echo "00:00"
        end
    
    case "*"
        echo "Usage: $argv[0] {title|artist|status|album|position|length}"
        exit 1
end