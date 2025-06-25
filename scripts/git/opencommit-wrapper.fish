#!/usr/bin/fish

# ============================================================================
# OPENCOMMIT WRAPPER - FISH EDITION  
# ============================================================================
# Uses the proven OpenCommit architecture with dotfiles-specific configuration
# Author: OpenCommit + Custom Dotfiles Integration
# Version: 1.0
#
# Features:
# - Uses OpenCommit's proven diff analysis and AI prompting
# - Configured specifically for dotfiles with custom scopes
# - Integrates with existing `dots` workflow
# - Fallback to intelligent pattern matching if OpenCommit fails
#
# Requirements:
# - Node.js and built OpenCommit in temp-opencommit/
# - Ollama with models (llama3.2:3b recommended)
# - Git repository
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
        exit 1
    end
    
    set repo_root (git rev-parse --show-toplevel)
    cd $repo_root
    debug "Using repo: $repo_root"
end

# Configure OpenCommit for dotfiles
function setup_opencommit
    set opencommit_path "$HOME/dotfiles/temp-opencommit"
    
    if not test -f "$opencommit_path/out/cli.cjs"
        error "OpenCommit not found or not built!"
        error "Run: cd $opencommit_path && npm install && npm run build"
        return 1
    end
    
    # Set up OpenCommit configuration for dotfiles
    set -x OCO_AI_PROVIDER "ollama"
    set -x OCO_MODEL "llama3.2:3b"
    set -x OCO_API_URL "http://localhost:11434/api/chat"
    set -x OCO_LANGUAGE "en"
    set -x OCO_DESCRIPTION false
    set -x OCO_EMOJI false
    set -x OCO_ONE_LINE_COMMIT true
    
    echo "$opencommit_path/out/cli.cjs"
    return 0
end

# Generate commit using OpenCommit with dotfiles context
function generate_opencommit_message
    set opencommit_cli (setup_opencommit)
    if test $status -ne 0
        return 1
    end
    
    # Check if there are staged changes
    set staged_files (git diff --cached --name-only)
    if test -z "$staged_files"
        echo "No staged changes found"
        return 1
    end
    
    info "🚀 Using OpenCommit for semantic analysis..."
    debug "Staged files: $staged_files"
    
    # Add dotfiles-specific context to help OpenCommit understand the repo
    set context "This is a sophisticated Arch Linux dotfiles repository with:
- Hyprland window manager configuration in hypr/
- Fish shell scripts and automation in scripts/
- Dynamic Material Design 3 theming system
- GPU monitoring and web dashboard
- AI-powered automation tools
- Waybar status bar configuration"
    
    # Run OpenCommit with context
    set commit_output (node $opencommit_cli -- "$context" 2>/dev/null)
    set exit_code $status
    
    debug "OpenCommit exit code: $exit_code"
    debug "OpenCommit output: '$commit_output'"
    
    if test $exit_code -eq 0; and test -n "$commit_output"
        # Extract just the commit message (OpenCommit sometimes adds extra output)
        set commit_msg (echo "$commit_output" | grep -E "^(feat|fix|chore|docs|style|refactor|perf|test)" | head -1 | string trim)
        
        if test -n "$commit_msg"
            success "OpenCommit generated: $commit_msg"
            echo "$commit_msg"
            return 0
        end
    end
    
    warn "OpenCommit failed, using fallback"
    return 1
end

# Intelligent fallback commit generation for dotfiles
function generate_fallback_commit
    set files_changed (git diff --cached --name-only)
    
    if test -z "$files_changed"
        echo "chore: update dotfiles"
        return
    end
    
    # Analyze the main file types
    set file_count (count $files_changed)
    debug "Fallback analyzing $file_count files: $files_changed"
    
    # Single file - be very specific
    if test $file_count -eq 1
        set file $files_changed[1]
        set basename_file (basename $file)
        
        # Git script improvements
        if string match -q "*dotfiles.fish" $file
            echo "feat(git): improve automated commit generation system"
            return
        else if string match -q "scripts/git/*" $file
            echo "feat(git): enhance git automation tools"
            return
        # Setup scripts
        else if string match -q "scripts/setup/*" $file
            set script_name (basename $file .sh)
            echo "feat(setup): enhance $script_name installation script"
            return
        # Theming scripts
        else if string match -q "scripts/theming/*" $file
            echo "feat(theming): improve theme management functionality"
            return
        # Other scripts
        else if string match -q "scripts/*" $file
            echo "feat(scripts): update automation tools"
            return
        # Hyprland config
        else if string match -q "hypr/*" $file
            echo "chore(hypr): update window manager configuration"
            return
        # Waybar config
        else if string match -q "waybar/*" $file
            echo "chore(waybar): update status bar configuration"
            return
        # Documentation
        else if string match -q "*.md" $file
            echo "docs: update $(basename $file .md) documentation"
            return
        # Gitignore
        else if string match -q "*.gitignore" $file
            echo "chore: update gitignore patterns"
            return
        end
        
        # Default single file
        echo "chore: update $basename_file"
        return
    end
    
    # Multiple files - categorize by dominant type
    set script_count 0
    set config_count 0
    set doc_count 0
    
    for file in $files_changed
        if string match -q "scripts/*" $file
            set script_count (math $script_count + 1)
        else if string match -q "hypr/*" $file; or string match -q "waybar/*" $file; or string match -q "*.conf" $file
            set config_count (math $config_count + 1)
        else if string match -q "*.md" $file
            set doc_count (math $doc_count + 1)
        end
    end
    
    # Generate message based on dominant change type
    if test $script_count -gt 0
        echo "feat(scripts): update automation tools and workflows"
    else if test $config_count -gt 0
        echo "chore(config): update system configuration files"
    else if test $doc_count -gt 0
        echo "docs: update project documentation"
    else
        echo "chore: update $file_count dotfiles"
    end
end

# Main commit generation function
function generate_smart_commit
    # First try OpenCommit for semantic analysis
    set commit_msg (generate_opencommit_message)
    
    if test $status -eq 0; and test -n "$commit_msg"
        echo "$commit_msg"
    else
        # Fallback to intelligent pattern matching
        debug "Using intelligent fallback generation"
        generate_fallback_commit
    end
end

# Smart sync operation using OpenCommit
function sync_dotfiles
    set custom_message $argv[1]
    
    info "Starting sync..."
    
    # Check for changes and stage them
    set changes (git status --porcelain)
    if test -n "$changes"
        # Stage all changes except cache files
        git add -A
        git reset HEAD -- '*.pyc' '**/*.pyc' '**/__pycache__/**' 2>/dev/null || true
        
        # Check if we have real changes after filtering
        set staged_files (git diff --cached --name-only)
        if test -z "$staged_files"
            info "No changes to commit after filtering"
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
            if test -z "$commit_msg"
                error "Empty commit message, aborting"
                return 1
            end
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

# Main function
function main
    check_git_repo
    
    # Parse arguments
    switch $argv[1]
        case sync s
            sync_dotfiles $argv[2]
        case commit c
            generate_smart_commit
        case test
            info "Testing OpenCommit integration..."
            generate_opencommit_message
        case "*"
            sync_dotfiles $argv[1]
    end
end

# Run main with all arguments
main $argv