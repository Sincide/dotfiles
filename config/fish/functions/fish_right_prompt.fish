function fish_right_prompt
    set -l cmd_duration $CMD_DURATION
    set -l duration_str ""

    if test $cmd_duration -gt 1000
        set duration_str (set_color yellow)(math -s2 "$cmd_duration/1000")"s"(set_color normal)
    end

    set_color brblack
    echo -n "[$duration_str "
    date "+%H:%M:%S"
    echo -n "]"
    set_color normal
end 