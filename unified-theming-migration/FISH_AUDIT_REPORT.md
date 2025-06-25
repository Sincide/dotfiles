# Fish Shell Git Shortcuts Audit Report

## Executive Summary
**Status:** ⚠️ MAJOR CONFLICTS FOUND  
**Total Conflicts:** 10 Git shortcuts with triple definitions  
**Impact:** Unpredictable behavior, muscle memory confusion  
**Recommendation:** Immediate cleanup required

---

## Conflict Analysis

### 🔴 CRITICAL: Triple-Defined Git Shortcuts

All of these shortcuts are defined in **THREE different ways**, causing unpredictable behavior:

| Shortcut | Alias (lines 145-159) | Function (aliases.fish) | Abbreviation (lines 289-301) |
|----------|----------------------|------------------------|------------------------------|
| `gs` | `git status` | `git status $argv` | `git status` |
| `ga` | `git add` | `git add $argv` | `git add` |
| `gc` | `git commit` | `git commit $argv` | `git commit` |
| `gp` | `git push` | `git push $argv` | `git push` |
| `gl` | `git log --oneline` | `git log --oneline $argv` | `git log --oneline --graph --decorate` |

### 🟡 MODERATE: Double-Defined Shortcuts

These have conflicts between aliases and abbreviations:

| Shortcut | Alias Definition | Abbreviation Definition |
|----------|-----------------|------------------------|
| `gaa` | `git add --all` | `git add --all` |
| `gcm` | `git commit -m` | `git commit -m` |
| `gd` | `git diff` | `git diff` |
| `gb` | `git branch` | `git branch` |
| `gco` | `git checkout` | `git checkout` |

### 🟢 INCONSISTENT: Different Behaviors

Some shortcuts have **different behaviors** depending on which definition takes precedence:

- **`gl`**: 
  - Alias: `git log --oneline` (simple)
  - Abbreviation: `git log --oneline --graph --decorate` (enhanced)
- **`gst`**: 
  - Alias: `git status --short` 
  - Abbreviation: `git stash` (COMPLETELY DIFFERENT!)

---

## Current File Locations

### 1. **Aliases in `fish/config.fish`** (lines 145-159)
```fish
alias gs='git status'
alias ga='git add'
alias gc='git commit'
# ... 15 total aliases
```

### 2. **Functions in `fish/functions/aliases.fish`** (lines 44-60)
```fish
function gs
    git status $argv
end
function ga
    git add $argv
end
# ... 5 total functions
```

### 3. **Abbreviations in `fish/config.fish`** (lines 289-301)
```fish
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
# ... 13 total abbreviations
```

---

## Recommended Resolution Strategy

### 🎯 **Adopt Abbreviations-Only Approach** 
**Rationale:** As per migration plan, prefer abbreviations for interactive use because:
- Visual expansion (you see what they become)
- More Fish-idiomatic
- Better for learning and transparency
- No argument handling issues

### 🗑️ **Remove Conflicts**
1. **Delete all Git aliases** from `fish/config.fish` (lines 145-159)
2. **Delete all Git functions** from `fish/functions/aliases.fish` (lines 44-60)
3. **Keep enhanced abbreviations** (lines 289-301) with some improvements

### 🔧 **Enhance Abbreviations**
Improve the abbreviation definitions with best-of-all-worlds approach:

```fish
# Enhanced Git abbreviations (keeping best features from all versions)
abbr -a gs 'git status'
abbr -a gst 'git status --short'           # Keep the short status
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gl 'git log --oneline --graph --decorate --all'  # Enhanced version
abbr -a gd 'git diff'
abbr -a gb 'git branch'
abbr -a gco 'git checkout'
abbr -a gco- 'git checkout -'              # Keep the useful dash version
abbr -a gstash 'git stash'                 # Rename from gst to avoid confusion
abbr -a gsp 'git stash pop'
```

---

## Implementation Plan

### Step 1: Backup Current State
- [x] Document all current conflicts
- [ ] Test current behavior of each shortcut
- [ ] Create backup of working configurations

### Step 2: Clean Removal
- [ ] Remove Git aliases from `fish/config.fish` (lines 145-159)
- [ ] Remove Git functions from `fish/functions/aliases.fish` (lines 44-60)
- [ ] Keep enhanced abbreviations only

### Step 3: Enhanced Abbreviations
- [ ] Update abbreviation definitions with best features
- [ ] Resolve `gst` conflict (status vs stash)
- [ ] Add missing useful shortcuts (like `gco-`)

### Step 4: Testing
- [ ] Test all Git shortcuts in fresh Fish session
- [ ] Verify no conflicts remain
- [ ] Document final shortcut reference

---

## Risk Assessment

### 🟢 **Low Risk**
- No impact on theming system
- Easy to revert changes
- Isolated to shell behavior

### 🟡 **Medium User Impact**
- Muscle memory adjustment period
- Some shortcuts might behave slightly differently
- Need to learn new `gstash` instead of `gst`

### 🟢 **High Benefit**
- Consistent, predictable behavior
- No more confusion about what command will run
- Clean foundation for migration work
- Better Fish shell experience

---

## Next Steps

1. **Get user approval** for abbreviations-only approach
2. **Implement clean removal** of aliases and functions
3. **Update abbreviations** with enhanced definitions
4. **Test and validate** all Git shortcuts work correctly
5. **Update migration devlog** with completed task

**Ready to proceed with cleanup?** 