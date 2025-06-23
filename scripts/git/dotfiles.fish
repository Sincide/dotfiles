#!/usr/bin/fish

# ============================================================================
# DOTFILES MANAGER - FISH EDITION
# ============================================================================
# Smart dotfiles management with AI-powered commit messages
# Author: Fish Script
# Version: 1.0
# 
# Features:
# - AI-generated commit messages using Ollama
# - Smart git sync (pull, commit, push)
# - Interactive menu interface
# - Beautiful Fish-native colors
# - Fallback commit messages when AI fails
#
# Requirements:
# - Fish shell
# - Git repository
# - Ollama (optional, for AI features)
#
# Usage:
#   ./dotfiles.fish           # Interactive menu
#   ./dotfiles.fish sync      # Quick sync with AI
#   ./dotfiles.fish status    # Show repo status
# ============================================================================

# Colors using Fish's native set_color
function info
    set_color blue; echo -n "[*]"; set_color normal; echo " $argv"
end

function success
    set_color green; echo -n "[✓]"; set_color normal; echo " $argv"
end

function error
    set_color red; echo -n "[✗]"; set_color normal; echo " $argv"
end

function warn
    set_color yellow; echo -n "[!]"; set_color normal; echo " $argv"
end

function debug
    if test -n "$DEBUG"
        set_color cyan; echo -n "[d]"; set_color normal; echo " $argv" >&2
    end
end

# Check if we're in a git repository
function check_git_repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        error "Not in a git repository!"
        error "Navigate to your dotfiles directory first"
        exit 1
    end
    
    # Move to repo root
    set repo_root (git rev-parse --show-toplevel)
    cd $repo_root
    debug "Using repo: $repo_root"
end

# Detect best available Ollama model
function detect_ollama_model
    if not command -v ollama >/dev/null 2>&1
        return 1
    end
    
    if not ollama list >/dev/null 2>&1
        return 1
    end
    
    # Priority models for coding tasks
    set priority_models qwen2.5-coder:14b qwen2.5-coder:7b codegemma:7b mistral:7b-instruct mistral:7b
    
    set available_models (ollama list | tail -n +2 | awk '{print $1}')
    
    for model in $priority_models
        if contains $model $available_models
            echo $model
            return 0
        end
    end
    
    # Fallback to first available
    if test (count $available_models) -gt 0
        echo $available_models[1]
        return 0
    end
    
    return 1
end

# Generate AI-powered commit message
function generate_ai_commit
    set files_changed (git diff --cached --name-only)
    set diff_summary (git diff --cached --stat)
    set diff_content (git diff --cached --unified=1)
    
    if test -z "$files_changed"
        generate_fallback_commit
        return
    end
    
    set model (detect_ollama_model)
    if test $status -ne 0
        warn "Ollama not available, using fallback" >&2
        generate_fallback_commit
        return
    end
    
    info "🤖 Generating commit with $model..." >&2
    
    # Analyze what actually changed
    set file_types ""
    set directories ""
    set has_config false
    set has_scripts false
    set has_docs false
    
    for file in $files_changed
        set dir (dirname $file | cut -d/ -f1)
        set ext (string split -r -m1 . $file)[2]
        
        set directories $directories $dir
        
        # Categorize by file type and location
        if string match -q "*.fish" $file; or string match -q "*.sh" $file; or string match -q "scripts/*" $file
            set has_scripts true
            set file_types $file_types "script"
        else if string match -q "*.conf" $file; or string match -q "*.ini" $file; or string match -q "*.json" $file; or string match -q "*.toml" $file; or string match -q "*.yaml" $file; or string match -q "*.yml" $file
            set has_config true
            set file_types $file_types "config"
        else if string match -q "*.md" $file; or string match -q "docs/*" $file; or string match -q "README*" $file
            set has_docs true
            set file_types $file_types "doc"
        else if string match -q "*.css" $file; or string match -q "*.scss" $file
            set file_types $file_types "style"
        else if string match -q "*.lua" $file; or string match -q "*.vim" $file; or string match -q "init.lua" $file
            set file_types $file_types "neovim"
        else if string match -q "hypr/*" $file; or string match -q "waybar/*" $file; or string match -q "dunst/*" $file
            set has_config true
            set file_types $file_types "wm-config"
        else if string match -q "gtk*/*" $file; or string match -q "themes/*" $file
            set file_types $file_types "theme"
        else
            set file_types $file_types "other"
        end
    end
    
    set unique_dirs (printf '%s\n' $directories | sort -u | grep -v '^\.$' | head -3)
    set unique_types (printf '%s\n' $file_types | sort -u | head -3)
    
    # Create a more specific prompt based on what changed
    set context ""
    if test $has_scripts = true
        set context "$context - Scripts/automation files were modified"
    end
    if test $has_config = true
        set context "$context - Configuration files were modified"
    end
    if test $has_docs = true
        set context "$context - Documentation was updated"
    end
    
    set prompt "You are a git commit message generator for a dotfiles repository. Generate ONLY a single line commit message.

Context: This is a Linux dotfiles repo with Hyprland, Fish shell, Neovim, and various configs.$context

Files changed: $files_changed
Directories affected: $unique_dirs
File types: $unique_types

Rules:
- Use conventional commit format: type(scope): description
- Types: feat, fix, chore, docs, style, refactor, perf, test
- Scope: specific component (fish, hypr, nvim, waybar, etc.)
- Keep under 60 characters
- Use present tense
- Be specific about what changed
- Focus on the most important change

Examples:
- fix(waybar): correct volume widget spacing
- feat(fish): add new alias for git operations
- chore(hypr): update window rules for new apps
- docs: update installation instructions
- style(gtk): improve dark theme colors

Commit message:"

    # Run AI with timeout and better error handling
    set ai_output (timeout 20s ollama run $model $prompt 2>/dev/null | head -1 | string trim | sed 's/[^a-zA-Z0-9:().,!? -]//g')
    
    debug "AI generated: '$ai_output'" >&2
    
    # Validate AI output more strictly
    if test -n "$ai_output" -a (string length "$ai_output") -gt 10 -a (string length "$ai_output") -lt 72
        # Check if it follows conventional commit format
        if string match -q "*(*):*" $ai_output; or string match -q "docs:*" $ai_output; or string match -q "chore:*" $ai_output; or string match -q "feat:*" $ai_output; or string match -q "fix:*" $ai_output; or string match -q "style:*" $ai_output; or string match -q "refactor:*" $ai_output; or string match -q "perf:*" $ai_output; or string match -q "test:*" $ai_output
            echo $ai_output
            return
        end
    end
    
    debug "AI failed or output invalid, using fallback" >&2
    generate_fallback_commit
end

# Generate fallback commit message
function generate_fallback_commit
    set files_changed (git diff --cached --name-only)
    set file_count (count $files_changed)
    
    if test $file_count -eq 0
        echo "chore: update dotfiles"
        return
    end
    
    # Analyze changes more intelligently
    set config_files ""
    set script_files ""
    set doc_files ""
    set theme_files ""
    set nvim_files ""
    set wm_files ""
    set other_files ""
    
    for file in $files_changed
        set dir (dirname $file | cut -d/ -f1)
        set basename_file (basename $file)
        
        # Categorize files more specifically
        if string match -q "*.fish" $file; or string match -q "*.sh" $file; or string match -q "scripts/*" $file
            set script_files $script_files $file
        else if string match -q "hypr/*" $file
            set wm_files $wm_files $file
        else if string match -q "waybar/*" $file
            set wm_files $wm_files $file
        else if string match -q "dunst/*" $file
            set wm_files $wm_files $file
        else if string match -q "nvim/*" $file; or string match -q "*.lua" $file; or string match -q "init.lua" $file
            set nvim_files $nvim_files $file
        else if string match -q "gtk*/*" $file; or string match -q "themes/*" $file; or string match -q "*.css" $file
            set theme_files $theme_files $file
        else if string match -q "*.conf" $file; or string match -q "*.ini" $file; or string match -q "*.json" $file; or string match -q "*.toml" $file; or string match -q "*.yaml" $file; or string match -q "*.yml" $file
            set config_files $config_files $file
        else if string match -q "*.md" $file; or string match -q "docs/*" $file; or string match -q "README*" $file
            set doc_files $doc_files $file
        else
            set other_files $other_files $file
        end
    end
    
    # Generate specific commit messages based on what changed
    if test (count $script_files) -gt 0
        if test (count $script_files) -eq 1
            set script_name (basename $script_files[1])
            set script_dir (dirname $script_files[1] | cut -d/ -f1)
            if test "$script_dir" != "." -a "$script_dir" != ""
                echo "feat($script_dir): update $script_name"
            else
                echo "feat(scripts): update $script_name"
            end
        else
            echo "feat(scripts): update automation tools"
        end
    else if test (count $wm_files) -gt 0
        set wm_dirs (printf '%s\n' (for f in $wm_files; dirname $f | cut -d/ -f1; end) | sort -u)
        if test (count $wm_dirs) -eq 1
            echo "chore($wm_dirs[1]): update configuration"
        else
            echo "chore(wm): update window manager configs"
        end
    else if test (count $nvim_files) -gt 0
        if test (count $nvim_files) -eq 1
            set nvim_file (basename $nvim_files[1])
            echo "feat(nvim): update $nvim_file"
        else
            echo "feat(nvim): update configuration"
        end
    else if test (count $theme_files) -gt 0
        if test (count $theme_files) -eq 1
            set theme_file (basename $theme_files[1])
            echo "style(theme): update $theme_file"
        else
            echo "style(theme): update styling"
        end
    else if test (count $config_files) -gt 0
        set config_dirs (printf '%s\n' (for f in $config_files; dirname $f | cut -d/ -f1; end) | sort -u)
        if test (count $config_dirs) -eq 1
            echo "chore($config_dirs[1]): update configuration"
        else
            echo "chore(config): update settings"
        end
    else if test (count $doc_files) -gt 0
        if test (count $doc_files) -eq 1
            set doc_file (basename $doc_files[1])
            echo "docs: update $doc_file"
        else
            echo "docs: update documentation"
        end
    else if test $file_count -eq 1
        set single_file (basename $files_changed[1])
        set single_dir (dirname $files_changed[1] | cut -d/ -f1)
        if test "$single_dir" != "." -a "$single_dir" != ""
            echo "chore($single_dir): update $single_file"
        else
            echo "chore: update $single_file"
        end
    else
        # Try to identify the most common directory
        set all_dirs (printf '%s\n' (for f in $files_changed; dirname $f | cut -d/ -f1; end) | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
        if test -n "$all_dirs" -a "$all_dirs" != "."
            echo "chore($all_dirs): update $file_count files"
        else
            echo "chore: update $file_count files"
        end
    end
end

# Toggle git remote between SSH and HTTPS
function toggle_remote
    set current_remote (git remote get-url origin 2>/dev/null)
    
    if test -z "$current_remote"
        error "No remote 'origin' found"
        error "Add a remote first: git remote add origin <url>"
        return 1
    end
    
    info "Current remote: $current_remote"
    
    # Extract repository info
    set repo_info ""
    if string match -q "git@github.com:*" $current_remote
        # SSH to HTTPS
        set repo_info (string replace "git@github.com:" "" $current_remote | string replace ".git" "")
        set new_remote "https://github.com/$repo_info.git"
        set new_type "HTTPS"
    else if string match -q "https://github.com/*" $current_remote
        # HTTPS to SSH
        set repo_info (string replace "https://github.com/" "" $current_remote | string replace ".git" "")
        set new_remote "git@github.com:$repo_info.git"
        set new_type "SSH"
    else if string match -q "git@gitlab.com:*" $current_remote
        # GitLab SSH to HTTPS
        set repo_info (string replace "git@gitlab.com:" "" $current_remote | string replace ".git" "")
        set new_remote "https://gitlab.com/$repo_info.git"
        set new_type "HTTPS"
    else if string match -q "https://gitlab.com/*" $current_remote
        # GitLab HTTPS to SSH
        set repo_info (string replace "https://gitlab.com/" "" $current_remote | string replace ".git" "")
        set new_remote "git@gitlab.com:$repo_info.git"
        set new_type "SSH"
    else
        error "Unsupported remote format: $current_remote"
        error "Only GitHub and GitLab SSH/HTTPS remotes are supported"
        return 1
    end
    
    info "🔄 Switching to $new_type..."
    info "New remote: $new_remote"
    
    # Confirm with user
    read -P "Switch remote URL? [Y/n]: " -n 1 confirm
    echo
    
    if test "$confirm" = "n" -o "$confirm" = "N"
        info "Remote URL unchanged"
        return 0
    end
    
    # Update remote
    if git remote set-url origin "$new_remote"
        success "✅ Remote switched to $new_type"
        success "New URL: $new_remote"
        
        # Test connectivity
        info "Testing connectivity..."
        if git ls-remote origin HEAD >/dev/null 2>&1
            success "🌐 Connection test passed!"
        else
            warn "⚠️  Connection test failed, attempting to fix SSH..."
            
            if test "$new_type" = "SSH"
                # Auto-fix SSH issues since SSH is already set up
                info "🔧 Attempting SSH auto-fix..."
                
                # Start ssh-agent and set environment variables
                if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"
                    info "Starting ssh-agent..."
                    eval (ssh-agent -c)
                    info "ssh-agent started with PID $SSH_AGENT_PID"
                end
                
                # Add platform-specific SSH keys
                set ssh_keys_added false
                set platform_key ""
                
                # Determine which platform-specific key to use
                if string match -q "*github.com*" $new_remote
                    set platform_key ~/.ssh/id_ed25519_github
                else if string match -q "*gitlab.com*" $new_remote
                    set platform_key ~/.ssh/id_ed25519_gitlab
                end
                
                # Try platform-specific key first, then fallback to generic keys
                set key_files $platform_key ~/.ssh/id_ed25519 ~/.ssh/id_rsa ~/.ssh/id_ecdsa
                
                for key_file in $key_files
                    if test -f "$key_file"
                        info "Adding SSH key: $key_file"
                        if ssh-add "$key_file" 2>/dev/null
                            set ssh_keys_added true
                            success "✓ Added $key_file to ssh-agent"
                            # If this is the platform-specific key, we can break
                            if test "$key_file" = "$platform_key"
                                break
                            end
                        else
                            warn "Failed to add $key_file (might need passphrase)"
                        end
                    end
                end
                
                if test "$ssh_keys_added" = "true"
                    info "Checking loaded keys..."
                    ssh-add -l
                    echo
                    
                    info "Retesting connection..."
                    if git ls-remote origin HEAD >/dev/null 2>&1
                        success "🎉 SSH connection fixed!"
                    else
                        error "SSH still not working. Debugging..."
                        echo
                        
                        # Test direct SSH connection
                        if string match -q "*github.com*" $new_remote
                            info "Testing GitHub SSH connection..."
                            ssh -T git@github.com
                        else if string match -q "*gitlab.com*" $new_remote
                            info "Testing GitLab SSH connection..."  
                            ssh -T git@gitlab.com
                        end
                        
                        echo
                        error "Possible solutions:"
                        echo "   1. Check if public key is added to your Git platform:"
                        if string match -q "*github.com*" $new_remote
                            echo "      → GitHub: https://github.com/settings/keys"
                            if test -f ~/.ssh/id_ed25519_github.pub
                                echo "      → Your key: cat ~/.ssh/id_ed25519_github.pub"
                            end
                        else if string match -q "*gitlab.com*" $new_remote
                            echo "      → GitLab: https://gitlab.com/-/profile/keys"
                            if test -f ~/.ssh/id_ed25519_gitlab.pub
                                echo "      → Your key: cat ~/.ssh/id_ed25519_gitlab.pub"
                            end
                        end
                        echo "   2. Check SSH config: cat ~/.ssh/config"
                        echo "   3. Re-run SSH setup: ~/dotfiles/scripts/setup/git-ssh-setup.sh"
                    end
                else
                    error "No SSH keys found or failed to add. Run SSH setup:"
                    echo "   ~/dotfiles/scripts/setup/git-ssh-setup.sh"
                end
            else
                # HTTPS-specific troubleshooting (unchanged)
                error "🔧 HTTPS Authentication Required:"
                if string match -q "*github.com*" $new_remote
                    echo "   1. Create Personal Access Token: https://github.com/settings/tokens"
                    echo "   2. Configure: git config --global credential.helper store"
                    echo "   3. Next git command will prompt for username/token"
                else if string match -q "*gitlab.com*" $new_remote
                    echo "   1. Create Personal Access Token: https://gitlab.com/-/profile/personal_access_tokens"
                    echo "   2. Configure: git config --global credential.helper store"
                    echo "   3. Next git command will prompt for username/token"
                end
                echo
                warn "🔄 After setup, test with: git fetch origin"
            end
        end
    else
        error "Failed to update remote URL"
        return 1
    end
end

# Show repository status
function show_status
    set_color purple; echo "Repository Status"; set_color normal
    echo "─────────────────"
    
    # Current branch
    set branch (git branch --show-current)
    set_color blue; echo -n "Branch: "; set_color normal; echo $branch
    
    # Check for changes
    set git_status (git status --porcelain)
    
    if test -z "$git_status"
        success "Working directory clean"
    else
        echo
        set_color yellow; echo "Changes:"; set_color normal
        
        for line in $git_status
            set status_code (string sub -l 2 $line)
            set filename (string sub -s 4 $line)
            
            switch $status_code
                case " M" "M " "MM"
                    set_color yellow; echo -n "  Modified: "; set_color normal; echo $filename
                case "A " "AM"
                    set_color green; echo -n "  Added:    "; set_color normal; echo $filename
                case "D " " D"
                    set_color red; echo -n "  Deleted:  "; set_color normal; echo $filename
                case "??"
                    set_color cyan; echo -n "  New:      "; set_color normal; echo $filename
                case "*"
                    set_color blue; echo -n "  Changed:  "; set_color normal; echo $filename
            end
        end
    end
    
    # Remote sync status
    git fetch --quiet 2>/dev/null
    set ahead_count (git rev-list --count @{u}..@ 2>/dev/null; or echo "0")
    set behind_count (git rev-list --count @..@{u} 2>/dev/null; or echo "0")
    
    echo
    if test $ahead_count -eq 0 -a $behind_count -eq 0
        success "In sync with remote"
    else if test $ahead_count -gt 0 -a $behind_count -eq 0
        warn "Ahead by $ahead_count commits"
    else if test $ahead_count -eq 0 -a $behind_count -gt 0
        warn "Behind by $behind_count commits"
    else
        warn "Diverged: +$ahead_count, -$behind_count commits"
    end
    
    # Show recent commits
    echo
    set_color purple; echo "Recent commits:"; set_color normal
    git log --oneline --color=always -3 | sed 's/^/  /'
end

# Show diff
function show_diff
    set_color purple; echo "Changes"; set_color normal
    echo "───────"
    
    set staged_changes (git diff --cached --name-only)
    set unstaged_changes (git diff --name-only)
    
    if test -z "$staged_changes" -a -z "$unstaged_changes"
        info "No changes to show"
        return
    end
    
    # Show staged changes
    if test -n "$staged_changes"
        echo
        set_color green; echo "Staged changes:"; set_color normal
        git diff --cached --color=always
    end
    
    # Show unstaged changes
    if test -n "$unstaged_changes"
        echo
        set_color yellow; echo "Unstaged changes:"; set_color normal
        git diff --color=always
    end
end

# Test AI functionality
function test_ai
    info "Testing AI commit generation..."
    
    set model (detect_ollama_model)
    if test $status -ne 0
        error "Ollama not available"
        error "Install: curl -fsSL https://ollama.ai/install.sh | sh"
        return 1
    end
    
    success "Found model: $model"
    
    # Test with sample prompt
    info "Testing with sample prompt..."
    set test_message (echo "Generate a commit message for: Updated fish shell configuration" | ollama run $model 2>/dev/null)
    
    if test -n "$test_message"
        success "AI is working!"
        set_color cyan; echo "Sample: $test_message"; set_color normal
    else
        error "AI test failed"
        return 1
    end
end

# Debug AI generation with detailed output
function debug_ai
    set -x DEBUG 1  # Enable debug output
    
    info "Debugging AI generation..."
    
    # Check if there are staged changes
    set staged_files (git diff --cached --name-only)
    if test -z "$staged_files"
        warn "No staged changes found. Staging all changes for testing..."
        git add -A
        set staged_files (git diff --cached --name-only)
    end
    
    if test -z "$staged_files"
        error "No changes to generate commit for"
        return 1
    end
    
    info "Files to commit: $staged_files"
    
    set model (detect_ollama_model)
    if test $status -ne 0
        error "Could not detect Ollama model"
        return 1
    end
    
    info "Using model: $model"
    
    # Test Ollama directly first
    info "Testing basic Ollama functionality..."
    set test_response (echo "Say hello" | ollama run $model 2>&1)
    set test_exit $status
    
    if test $test_exit -ne 0
        error "Basic Ollama test failed with exit code $test_exit"
        error "Output: $test_response"
        return 1
    else
        success "Basic Ollama test passed: $test_response"
    end
    
    # Now test commit generation
    info "Testing commit generation..."
    set commit_msg (generate_ai_commit)
    
    success "Generated commit message: '$commit_msg'"
    
    set -e DEBUG  # Disable debug output
end

# Smart sync operation
function sync_dotfiles
    set custom_message $argv[1]
    
    info "Starting sync..."
    
    # Check for changes and stage them
    set changes (git status --porcelain)
    if test -n "$changes"
        git add -A
        
        # Generate commit message
        if test -n "$custom_message"
            set commit_msg $custom_message
        else
            set commit_msg (generate_ai_commit)
        end
        
        echo
        info "📝 Commit message:"
        set_color green; echo "   \"$commit_msg\""; set_color normal
        echo
        
        # Confirm with user
        read -P "Use this message? [Y/n]: " -n 1 confirm
        echo
        
        if test "$confirm" = "n" -o "$confirm" = "N"
            read -P "Enter your message: " commit_msg
        end
        
        # Commit changes
        if git commit -m "$commit_msg"
            success "Committed: $commit_msg"
        else
            error "Commit failed"
            return 1
        end
    else
        info "No changes to commit"
    end
    
    # Sync with remote
    info "Syncing with remote..."
    
    if git pull --rebase
        success "Pulled changes"
    else
        error "Pull failed - resolve conflicts first"
        warn "Run: git status, fix conflicts, then git rebase --continue"
        return 1
    end
    
    if git push
        success "Pushed changes"
    else
        error "Push failed"
        return 1
    end
    
    success "Sync completed! 🎉"
end

# Interactive menu for dotfiles
function show_interactive_menu
    while true
        set_color purple
        echo "╭─────────────────────────────────────────╮"
        echo "│           Dotfiles Manager              │"
        echo "│            Fish Edition                 │"
        echo "╰─────────────────────────────────────────╯"
        set_color normal
        echo
        
        set_color yellow; echo "What would you like to do?"; set_color normal
        echo
        echo "  1️⃣  Sync (AI-powered commit & push)"
        echo "  2️⃣  Status (repository overview)"
        echo "  3️⃣  Diff (show changes)"
        echo "  4️⃣  AI Test (test commit generation)"
        echo "  5️⃣  AI Debug (detailed AI diagnostics)"
        echo "  6️⃣  Toggle Remote (SSH ↔ HTTPS)"
        echo
        echo "  0️⃣  Exit"
        echo
        
        read -P "Enter your choice [1-6, 0 to exit]: " choice
        echo
        
        switch $choice
            case 1
                read -P "Custom commit message (or Enter for AI): " custom_msg
                sync_dotfiles "$custom_msg"
                break
            case 2
                show_status
                break
            case 3
                show_diff
                break
            case 4
                test_ai
                break
            case 5
                debug_ai
                break
            case 6
                toggle_remote
                break
            case 0 q quit exit
                info "Goodbye! 👋"
                exit 0
            case ""
                # Default to sync if just Enter is pressed
                sync_dotfiles
                break
            case "*"
                error "Invalid choice: $choice"
                echo "Please enter a number from 1-6, or 0 to exit"
                echo
                read -P "Press Enter to continue..." dummy
                clear
        end
    end
    
    echo
    read -P "Press Enter to return to menu, or 'q' to quit: " continue
    if test "$continue" = "q" -o "$continue" = "quit"
        info "Goodbye! 👋"
        exit 0
    else
        clear
        show_interactive_menu
    end
end

# Show help
function show_help
    set_color purple
    echo "╭─────────────────────────────────────────╮"
    echo "│           Dotfiles Manager              │"
    echo "│            Fish Edition                 │"
    echo "╰─────────────────────────────────────────╯"
    set_color normal
    
    echo
    set_color yellow; echo "Usage:"; set_color normal
    echo "  ./dotfiles.fish           - Interactive menu (default)"
    echo "  ./dotfiles.fish [command] - Direct command"
    echo
    set_color yellow; echo "Commands:"; set_color normal
    echo "  sync [message]    - Smart sync with AI commits"
    echo "  status           - Show repository status"
    echo "  diff             - Show changes"
    echo "  ai-test          - Test AI commit generation"
    echo "  ai-debug         - Debug AI generation with details"
    echo "  toggle-remote    - Toggle remote between SSH and HTTPS"
    echo "  help             - Show this help"
    
    echo
    set_color yellow; echo "Features:"; set_color normal
    echo "  🤖 AI commit messages (Ollama)"
    echo "  🔄 Smart git sync"
    echo "  🐟 Native Fish shell"
    echo "  🎨 Beautiful colors"
    echo "  📱 Interactive menus"
    
    echo
    set_color yellow; echo "Examples:"; set_color normal
    echo "  ./dotfiles.fish                    # Interactive menu"
    echo "  ./dotfiles.fish sync               # Quick AI sync"
    echo "  ./dotfiles.fish sync \"fix bug\"     # Custom message"
    echo "  ./dotfiles.fish status             # Check status"
end

# Main function
function main
    # Ensure we're in a git repo for most commands
    set git_commands sync status diff ai-test ai-debug
    set command $argv[1]
    
    # If no arguments, show interactive menu
    if test (count $argv) -eq 0
        check_git_repo
        show_interactive_menu
        return
    end
    
    if contains $command $git_commands
        check_git_repo
    end
    
    # Command dispatcher
    switch $command
        case sync s
            sync_dotfiles $argv[2]
        case status st
            show_status
        case diff d
            show_diff
        case ai-test ai
            test_ai
        case ai-debug
            debug_ai
        case toggle-remote tr remote
            toggle_remote
        case interactive menu i
            show_interactive_menu
        case help h --help -h
            show_help
        case "*"
            error "Unknown command: $command"
            echo
            info "Starting interactive menu..."
            sleep 1
            check_git_repo
            show_interactive_menu
    end
end

# Run main with all arguments
main $argv