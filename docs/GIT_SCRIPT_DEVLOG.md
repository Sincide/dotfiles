# Git Dotfiles Script Development Log

## 2025-01-14 - AI Commit Message Generation Fixes

### Issue Identified
The dotfiles.fish script was generating poor AI commit messages due to hallucination issues:
- AI was generating verbose explanations instead of clean commit messages
- Output processing was too aggressive, removing valid messages
- Validation was too strict, causing fallback to generic messages
- Result: Generic messages like "feat(scripts): update automation tools" instead of specific ones

### Root Causes
1. **Overly complex prompt** - Too much context confused the AI
2. **Aggressive text cleaning** - Regex was removing valid characters and formats
3. **Wrong model selection** - Large coding models over-explain simple tasks
4. **Strict validation** - Rejected good messages due to format requirements

### Solutions Implemented

#### 1. Simplified AI Prompt
```fish
# Before: Long, complex prompt with excessive context
# After: Simple, focused prompt
set prompt "Write a git commit message for these changes:
$files_changed

Requirements:
- Use format: type(scope): description  
- Types: feat, fix, chore, docs, style
- Be specific about what changed
- One line only

Example: fix(git): improve commit message generation

Message:"
```

#### 2. Better Model Selection
- Prioritized smaller, faster models (llama3.2:3b, llama3.2:1b)
- These work better for simple tasks than large coding models
- Added fallback to smallest available model

#### 3. Improved Output Processing
- Removed aggressive character filtering
- Preserved conventional commit format (type(scope): description)
- Better extraction of actual commit message from verbose responses
- Handle periods and explanatory text more carefully

#### 4. Relaxed Validation
```fish
# Before: Strict pattern matching that rejected good messages
# After: Simple length and content check
if test -n "$ai_output" -a (string length "$ai_output") -gt 10 -a (string length "$ai_output") -lt 80
    echo $ai_output
    return
end
```

### Results
- ✅ AI now generates focused, single-line commit messages
- ✅ No more verbose explanations or multiple options  
- ✅ Better extraction of actual commit content from AI responses
- ✅ Preserved conventional commit formatting
- ✅ Faster processing with smaller models
- ✅ More reliable AI commit generation

### Testing
- `./scripts/git/dotfiles.fish ai-test` - Test AI functionality
- `./scripts/git/dotfiles.fish ai-debug` - Detailed debugging with output
- `./scripts/git/dotfiles.fish sync` - Full sync with AI commits

### Next Steps
- Monitor AI commit quality in real usage
- Consider adding more model options
- Potentially add commit type detection based on file patterns 