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
    
    set prompt "Generate a concise git commit message for these dotfiles changes:

Files changed:
$files_changed

Diff summary:
$diff_summary

Requirements:
- Use conventional commit format (feat:, fix:, chore:, docs:, style:)
- Keep under 72 characters
- Be specific about what changed
- Use present tense
- Don't include 'dotfiles' unless necessary

Generate ONLY the commit message, no explanation:"

    # Run AI with timeout and capture both output and errors
    set ai_result (timeout 25s ollama run $model $prompt 2>&1)
    set ai_exit_code $status
    set ai_output (echo $ai_result | head -1 | string trim)
    
    debug "AI exit code: $ai_exit_code" >&2
    debug "AI processed: '$ai_output'" >&2
    
    if test $ai_exit_code -eq 0 -a -n "$ai_output" -a (string length "$ai_output") -gt 5 -a (string length "$ai_output") -lt 150
        echo $ai_output
    else
        if test $ai_exit_code -eq 124
            warn "AI generation timed out" >&2
        else if test $ai_exit_code -ne 0
            warn "AI failed with exit code $ai_exit_code" >&2
        else
            warn "AI generated invalid message: '$ai_output'" >&2
        end
        generate_fallback_commit
    end
end

# Generate fallback commit message
function generate_fallback_commit
    set files_changed (git diff --cached --name-only)
    set file_count (echo $files_changed | wc -l)
    
    # Categorize files
    set config_files (echo $files_changed | grep -E '^(config/|\..*rc|\..*config)')
    set script_files (echo $files_changed | grep -E '^(scripts/|bin/|.*\.sh|.*\.fish)')
    set doc_files (echo $files_changed | grep -E '^(README|.*\.md|docs/)')
    
    if test -n "$config_files"
        # Extract app names from config files
        set apps (echo $config_files | sed -E 's|^config/([^/]+)/.*|\1|;s|^\.([^.]+).*|\1|' | sort -u)
        set app_count (count $apps)
        
        if test $app_count -eq 1
            echo "config: update $apps[1] settings"
        else if test $app_count -le 3
            echo "config: update "(string join ", " $apps)
        else
            echo "config: update multiple configurations"
        end
    else if test -n "$script_files"
        echo "scripts: update automation scripts"
    else if test -n "$doc_files"
        echo "docs: update documentation"
    else
        if test $file_count -eq 1
            echo "chore: update "(basename $files_changed)
        else
            echo "chore: update $file_count files"
        end
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
        echo
        echo "  0️⃣  Exit"
        echo
        
        read -P "Enter your choice [1-5, 0 to exit]: " choice
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
            case 0 q quit exit
                info "Goodbye! 👋"
                exit 0
            case ""
                # Default to sync if just Enter is pressed
                sync_dotfiles
                break
            case "*"
                error "Invalid choice: $choice"
                echo "Please enter a number from 1-5, or 0 to exit"
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