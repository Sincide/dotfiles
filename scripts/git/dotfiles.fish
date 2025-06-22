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
    
    set prompt "You are a git commit message generator. Generate ONLY a single line commit message, no explanation or extra text.

Files changed: $files_changed

Use conventional commit format: type(scope): description
- Types: feat, fix, chore, docs, style, refactor
- Keep under 60 characters  
- Use present tense
- Be specific

Example: fix(waybar): correct volume widget spacing

Commit message:"

    # Run AI with timeout 
    set ai_output (timeout 15s ollama run $model $prompt 2>/dev/null | head -1 | string trim | sed 's/[^a-zA-Z0-9:().,!? -]//g')
    
    debug "AI generated: '$ai_output'" >&2
    
    # Use AI output if it looks decent, otherwise fallback
    if test -n "$ai_output" -a (string length "$ai_output") -gt 15 -a (string length "$ai_output") -lt 72
        echo $ai_output
    else
        debug "AI failed or output too short/long, using fallback" >&2
        generate_fallback_commit
    end
end

# Generate fallback commit message
function generate_fallback_commit
    set files_changed (git diff --cached --name-only)
    set file_count (count $files_changed)
    
    if test $file_count -eq 0
        echo "chore: update dotfiles"
        return
    end
    
    # Categorize files by directory structure
    set config_dirs ""
    set script_dirs ""
    set doc_files ""
    set other_files ""
    
    for file in $files_changed
        if string match -q "*/config*" $file; or string match -q ".*rc" $file
            set config_dirs $config_dirs (dirname $file | cut -d/ -f1)
        else if string match -q "scripts/*" $file; or string match -q "*.fish" $file; or string match -q "*.sh" $file
            set script_dirs $script_dirs (dirname $file | cut -d/ -f1)
        else if string match -q "*.md" $file; or string match -q "docs/*" $file; or string match -q "README*" $file
            set doc_files $doc_files $file
        else
            set other_files $other_files $file
        end
    end
    
         # Generate smart commit based on what changed
     if test (count $script_dirs) -gt 0
         set unique_scripts (printf '%s\n' $script_dirs | sort -u | head -3)
         if test (count $unique_scripts) -eq 1 -a "$unique_scripts[1]" != ""
             echo "scripts($unique_scripts[1]): update automation tools"
         else
             echo "scripts: update automation and tools"
         end
     else if test (count $config_dirs) -gt 0
         set unique_configs (printf '%s\n' $config_dirs | sort -u | head -3)
         if test (count $unique_configs) -eq 1 -a "$unique_configs[1]" != ""
             echo "config($unique_configs[1]): update settings"
         else
             echo "config: update configuration files"
         end
     else if test (count $doc_files) -gt 0
         echo "docs: update documentation"
     else if test $file_count -eq 1
         set basename_file (basename $files_changed[1])
         set dir_name (dirname $files_changed[1] | cut -d/ -f1)
         if test "$dir_name" != "." -a "$dir_name" != ""
             echo "chore($dir_name): update $basename_file"
         else
             echo "chore: update $basename_file"
         end
     else
         echo "chore: update $file_count files"
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
            error "⚠️  Connection test failed!"
            echo
            
            if test "$new_type" = "SSH"
                # SSH-specific troubleshooting
                if string match -q "*github.com*" $new_remote
                    error "🔧 GitHub SSH Setup Required:"
                    echo "   1. Generate SSH key: ssh-keygen -t ed25519 -C \"your-email@example.com\""
                    echo "   2. Start ssh-agent:   eval \"\$(ssh-agent -s)\""
                    echo "   3. Add key:          ssh-add ~/.ssh/id_ed25519"
                    echo "   4. Copy public key:  cat ~/.ssh/id_ed25519.pub"
                    echo "   5. Add to GitHub:    https://github.com/settings/ssh/new"
                    echo "   6. Test connection:  ssh -T git@github.com"
                else if string match -q "*gitlab.com*" $new_remote
                    error "🔧 GitLab SSH Setup Required:"
                    echo "   1. Generate SSH key: ssh-keygen -t ed25519 -C \"your-email@example.com\""
                    echo "   2. Start ssh-agent:   eval \"\$(ssh-agent -s)\""
                    echo "   3. Add key:          ssh-add ~/.ssh/id_ed25519"
                    echo "   4. Copy public key:  cat ~/.ssh/id_ed25519.pub"
                    echo "   5. Add to GitLab:    https://gitlab.com/-/profile/keys"
                    echo "   6. Test connection:  ssh -T git@gitlab.com"
                end
                echo
                warn "💡 If you have existing keys, try: ssh-add ~/.ssh/id_rsa or ssh-add ~/.ssh/id_ed25519"
                warn "💡 To see your keys: ls -la ~/.ssh/"
                warn "💡 To check ssh-agent: ssh-add -l"
            else
                # HTTPS-specific troubleshooting
                if string match -q "*github.com*" $new_remote
                    error "🔧 GitHub HTTPS Authentication Required:"
                    echo "   1. Create Personal Access Token:"
                    echo "      → Go to: https://github.com/settings/tokens"
                    echo "      → Generate new token (classic)"
                    echo "      → Select scopes: repo, workflow"
                    echo "   2. Configure git credentials:"
                    echo "      git config --global credential.helper store"
                    echo "   3. Next git command will prompt for username/token"
                    echo "      Username: your-github-username"
                    echo "      Password: your-personal-access-token"
                else if string match -q "*gitlab.com*" $new_remote
                    error "🔧 GitLab HTTPS Authentication Required:"
                    echo "   1. Create Personal Access Token:"
                    echo "      → Go to: https://gitlab.com/-/profile/personal_access_tokens"
                    echo "      → Create token with 'read_repository' and 'write_repository' scopes"
                    echo "   2. Configure git credentials:"
                    echo "      git config --global credential.helper store"
                    echo "   3. Next git command will prompt for username/token"
                    echo "      Username: your-gitlab-username"
                    echo "      Password: your-personal-access-token"
                end
                echo
                warn "💡 Token will be stored securely after first use"
                warn "💡 Alternative: Use 'git config --global credential.helper cache' for temporary storage"
            end
            echo
            warn "🔄 After setup, test with: git fetch origin"
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