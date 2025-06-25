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
    
    # Priority models for coding tasks - llama3.2 is better for commit messages than codegemma
    set priority_models qwen2.5-coder:14b qwen2.5-coder:7b llama3.2:3b mistral:7b-instruct mistral:7b codegemma:7b
    
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

# Generate smart commit message using opencommit-inspired approach
function generate_smart_commit
    set files_changed (git diff --cached --name-only)
    
    if test -z "$files_changed"
        echo "chore: update dotfiles"
        return
    end
    
    # Filter out unwanted files
    set real_files ""
    for file in $files_changed
        if not string match -q "*__pycache__*" $file; and not string match -q "*.pyc" $file; and not string match -q "*.log" $file
            set real_files $real_files $file
        end
    end
    
    if test (count $real_files) -eq 0
        echo "chore: cleanup cache files"
        return
    end
    
    # Get comprehensive diff analysis
    set diff_content (git diff --cached -- $real_files)
    set file_count (count $real_files)
    
    # Extract meaningful context from diff
    set added_functions (echo "$diff_content" | grep "^+.*function " | head -3 | sed 's/^+//' | string trim)
    set removed_functions (echo "$diff_content" | grep "^-.*function " | head -3 | sed 's/^-//' | string trim)
    set config_changes (echo "$diff_content" | grep "^[+-].*=" | grep -v "function" | head -5 | sed 's/^[+-]//' | string trim)
    set import_changes (echo "$diff_content" | grep "^[+-].*(import\|require\|source)" | head -3 | sed 's/^[+-]//' | string trim)
    
    # Get summary stats
    set total_additions (echo "$diff_content" | grep "^+" | wc -l)
    set total_deletions (echo "$diff_content" | grep "^-" | wc -l)
    
    info "🔍 Analyzing changes: $file_count files (+$total_additions -$total_deletions)" >&2
    
    # Try AI with opencommit-style approach
    set model (detect_ollama_model)
    if test $status -eq 0
        info "🤖 Using $model for semantic analysis..." >&2
        
        # Create opencommit-inspired prompt with better context
        set context_prompt "You are a commit message generator. Analyze the code changes and generate a conventional commit message.

CHANGED FILES ($file_count):
$(string join ', ' $real_files)

SUMMARY: +$total_additions -$total_deletions lines

CODE CONTEXT:"

        # Add function context if available
        if test -n "$added_functions"
            set context_prompt "$context_prompt
FUNCTIONS ADDED:
$added_functions"
        end
        
        if test -n "$removed_functions"
            set context_prompt "$context_prompt
FUNCTIONS REMOVED:
$removed_functions"
        end
        
        if test -n "$config_changes"
            set context_prompt "$context_prompt
CONFIG CHANGES:
$(echo $config_changes | head -3)"
        end
        
        set context_prompt "$context_prompt

Generate a conventional commit message that describes the PURPOSE and IMPACT of these changes.

Format: type(scope): description
Types: feat, fix, chore, docs, style, refactor, perf, test
Scopes: git, scripts, hypr, waybar, theming, setup, config

Focus on WHAT was accomplished, not HOW it was implemented.

Examples:
- feat(git): implement semantic commit message generation
- refactor(scripts): restructure automation workflow logic  
- chore(config): update development environment settings

Commit message:"

        # Try multiple models with fallback
        for attempt_model in (detect_ollama_model) llama3.2:3b codegemma:7b
            if ollama list | grep -q $attempt_model
                debug "Trying model: $attempt_model" >&2
                set ai_output (timeout 12s ollama run $attempt_model $context_prompt 2>/dev/null | head -1 | string trim)
                
                # Clean and validate response
                set ai_output (echo "$ai_output" | sed 's/^[^a-z]*//' | sed 's/^\(Based on\|Here\|I would\).*//' | string trim)
                
                if test -n "$ai_output"; and string match -q "*:*" $ai_output; and test (string length "$ai_output") -lt 100; and not string match -q "*suggest*" $ai_output
                    success "AI generated: $ai_output" >&2
                    echo $ai_output
                    return
                else
                    debug "Model $attempt_model failed: '$ai_output'" >&2
                end
            end
        end
        
        warn "All AI models failed, using pattern analysis" >&2
    end
    
    # Fallback to intelligent pattern analysis (opencommit style)
    generate_pattern_commit $real_files $diff_content $total_additions $total_deletions
end

# Pattern-based commit generation (inspired by opencommit's fallback logic)
function generate_pattern_commit
    set files $argv[1..-4]
    set diff_content $argv[-3]
    set additions $argv[-2]  
    set deletions $argv[-1]
    set file_count (count $files)
    
    # Single file - detailed analysis
    if test $file_count -eq 1
        set file $files[1]
        set basename_file (basename $file)
        
        # Specific file type handling
        if string match -q "*dotfiles.fish" $file
            if echo "$diff_content" | grep -q "opencommit\|semantic\|context"
                echo "feat(git): implement opencommit-inspired semantic commit generation"
            else if echo "$diff_content" | grep -q "function.*generate.*commit"
                echo "refactor(git): restructure commit message generation with AI fallback"
            else if echo "$diff_content" | grep -q "prompt.*context"
                echo "feat(git): enhance AI prompts with better code context analysis"
            else if test $additions -gt 100
                echo "feat(git): major overhaul of commit message generation system"
            else if test $additions -gt 50
                echo "feat(git): significantly improve automated commit generation"
            else
                echo "feat(git): enhance commit message generation logic"
            end
            return
        else if string match -q "scripts/setup/*" $file
            set script_name (basename $file .sh)
            echo "feat(setup): enhance $script_name installation automation"
            return
        else if string match -q "scripts/theming/*" $file
            echo "feat(theming): improve theme management functionality"
            return
        else if string match -q "scripts/*" $file
            echo "feat(scripts): update automation tools"
            return
        else if string match -q "hypr/*" $file
            echo "chore(hypr): update window manager configuration"
            return
        else if string match -q "waybar/*" $file
            echo "chore(waybar): update status bar configuration"
            return
        else if string match -q "*.gitignore" $file
            echo "chore: update gitignore patterns"
            return
        else if string match -q "*.md" $file
            echo "docs: update $(basename $file .md) documentation"
            return
        end
        
        echo "chore: update $basename_file"
        return
    end
    
    # Multiple files - categorize impact
    set has_scripts 0
    set has_configs 0 
    set has_docs 0
    
    for file in $files
        if string match -q "scripts/*" $file
            set has_scripts (math $has_scripts + 1)
        else if string match -q "*.conf" $file; or string match -q "hypr/*" $file; or string match -q "waybar/*" $file
            set has_configs (math $has_configs + 1)
        else if string match -q "*.md" $file
            set has_docs (math $has_docs + 1)
        end
    end
    
    # Generate message based on dominant change type
    if test $has_scripts -gt 0; and test $additions -gt 50
        echo "feat(scripts): major improvements to automation workflows"
    else if test $has_scripts -gt 0
        echo "feat(scripts): update automation tools and utilities"
    else if test $has_configs -gt 2
        echo "chore(config): update multiple system configurations"
    else if test $has_docs -gt 0
        echo "docs: update project documentation"
    else
        echo "chore: update $file_count configuration files"
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
    
    # Check for changes and stage them (excluding unwanted files)
    set changes (git status --porcelain)
    if test -n "$changes"
        # Stage all changes except cache files and other unwanted files
        git add -A
        git reset HEAD -- '*.pyc' '**/*.pyc' '**/__pycache__/**' 2>/dev/null || true
        
        # Check if we have any real files staged after filtering
        set staged_files (git diff --cached --name-only)
        set real_staged_files ""
        for file in $staged_files
            if not string match -q "*__pycache__*" $file; and not string match -q "*.pyc" $file
                set real_staged_files $real_staged_files $file
            end
        end
        
        if test (count $real_staged_files) -eq 0
            info "Only cache files changed, nothing to commit"
            return 0
        end
        
        # Generate commit message
        if test -n "$custom_message"
            set commit_msg $custom_message
        else
            set commit_msg (generate_smart_commit)
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