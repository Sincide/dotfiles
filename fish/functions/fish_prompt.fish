function fish_prompt --description 'Evil Space custom fish prompt'
    # Save the return status of the previous command
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.

    # Define Evil Space colors (will be overridden by dynamic theme)
    set -l normal (set_color normal)
    set -l magenta (set_color magenta)
    set -l yellow (set_color yellow)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l gray (set_color -o black)
    set -l cyan (set_color cyan)
    set -l blue (set_color blue)

    # Color variables
    set -l suffix
    if fish_is_root_user
        set suffix (set_color $fish_color_cwd_root)
    else
        set suffix (set_color $fish_color_cwd)
    end

    # Git status
    set -l git_info
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch_name (git symbolic-ref --quiet --short HEAD 2>/dev/null; or git describe --all --exact-match HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        set -l git_dirty
        if not git diff --quiet --ignore-submodules 2>/dev/null
            set git_dirty "*"
        end
        set git_info " $cyan($branch_name$git_dirty$normal)"
    end

    # Build the prompt
    echo -n -s $magenta '🌌 ' $normal
    echo -n -s $blue (prompt_hostname) $normal ' '
    echo -n -s $suffix (prompt_pwd) $normal
    echo -n -s $git_info
    echo -n -s $normal ' '
    
    # Status indicator
    if not test $last_pipestatus[-1] -eq 0
        set -l status_color (set_color $fish_color_error)
        echo -n -s $status_color '✗' $normal ' '
    end
    
    echo -n -s $magenta '❯' $normal ' '
end 