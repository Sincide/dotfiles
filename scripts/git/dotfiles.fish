#!/usr/bin/fish

# Dotfiles Manager - Fish Script
# Clean, fast, and Fish-native

# Colors using Fish's set_color (much better than ANSI codes!)
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
    set_color cyan; echo -n "[d]"; set_color normal; echo " $argv"
end

# Check if we're in a git repository
function check_git_repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        error "Not in a git repository!"
        exit 1
    end
    
    # Move to repo root
    set repo_root (git rev-parse --show-toplevel)
    cd $repo_root
    debug "Using repo: $repo_root"
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
    set_color yellow; echo "Commands:"; set_color normal
    echo "  sync [message]    - Smart sync with AI commits"
    echo "  status           - Show repository status"
    echo "  diff             - Show changes"
    echo "  ai-test          - Test AI commit generation"
    echo "  help             - Show this help"
    
    echo
    set_color yellow; echo "Features:"; set_color normal
    echo "  🤖 AI commit messages (Ollama)"
    echo "  🔄 Smart git sync"
    echo "  🐟 Native Fish shell"
    echo "  🎨 Beautiful colors"
    
    echo
    set_color yellow; echo "Examples:"; set_color normal
    echo "  dotfiles.fish sync"
    echo "  dotfiles.fish sync \"custom message\""
    echo "  dotfiles.fish status"
end

# Detect best available Ollama model
function detect_ollama_model
    if not command -v ollama >/dev/null 2>&1
        return 1
    end
    
    if not ollama list >/dev/null 2>&1
        return 1
    end
    
    # Priority models for coding
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

# Generate AI commit message
function generate_ai_commit
    set files_changed (git diff --cached --name-only)
    set diff_summary (git diff --cached --stat)
    
    if test -z "$files_changed"
        generate_fallback_commit
        return
    end
    
    set model (detect_ollama_model)
    if test $status -ne 0
        warn "Ollama not available, using fallback"
        generate_fallback_commit
        return
    end
    
    info "🤖 Generating commit with $model..."
    
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

    # Run AI with timeout and capture output
    set ai_output (timeout 25s ollama run $model $prompt 2>/dev/null | head -1 | string trim)
    
    if test $status -eq 0 -a -n "$ai_output" -a (string length "$ai_output") -gt 5 -a (string length "$ai_output") -lt 150
        echo $ai_output
    else
        warn "AI generation failed, using fallback"
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
        return 1
    end
    
    success "Found model: $model"
    
    # Test with fake changes
    info "Testing with sample prompt..."
    set test_message (echo "Generate a commit message for: Updated fish shell configuration" | ollama run $model)
    
    if test -n "$test_message"
        success "AI is working!"
        set_color cyan; echo "Sample: $test_message"; set_color normal
    else
        error "AI test failed"
        return 1
    end
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

# Main script logic
function main
    # Ensure we're in a git repo for most commands
    set git_commands sync status diff ai-test
    set command $argv[1]
    
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
        case help h --help -h ""
            show_help
        case "*"
            error "Unknown command: $command"
            echo "Run 'dotfiles.fish help' for usage"
            exit 1
    end
end

# Run main function with all arguments
main $argv