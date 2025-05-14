function fish_prompt
    set -l last_status $status

    # Current directory
    set_color blue
    echo -n (prompt_pwd)
    set_color normal

    # Git information
    if command -v git >/dev/null
        set -l git_branch (git branch 2>/dev/null | grep '\*' | sed 's/\* //')
        if test -n "$git_branch"
            set_color yellow
            echo -n " ($git_branch)"
            
            # Check for git status
            if test -n "$(git status --porcelain 2>/dev/null)"
                set_color red
                echo -n " ●"
            else
                set_color green
                echo -n " ●"
            end
        end
    end

    # Error status
    if test $last_status -ne 0
        set_color red
        echo -n " [$last_status]"
    end

    # Prompt character
    if fish_is_root_user
        set_color red
        echo -n " # "
    else
        set_color cyan
        echo -n " λ "
    end
    
    set_color normal
end 