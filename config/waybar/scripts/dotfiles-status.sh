#!/bin/bash

# Change to the dotfiles directory
cd ~/dotfiles

# Initialize variables
STATUS="OK"
CLASS="clean"
TOOLTIP="Dotfiles are up to date"

# Check if there are any changes (modified, untracked, staged)
if [[ -n $(git status --porcelain) ]]; then
    STATUS="Modified"
    CLASS="modified"
    TOOLTIP="You have uncommitted changes"
fi

# Check for unpushed commits
if [[ -n $(git log @{push}.. 2>/dev/null) ]]; then
    STATUS="Unpushed"
    CLASS="unpushed"
    TOOLTIP="You have unpushed commits"
fi

# Check for unpulled changes
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null)
BASE=$(git merge-base @ @{u} 2>/dev/null)

if [[ $REMOTE != $LOCAL && $REMOTE = $BASE ]]; then
    STATUS="Pull"
    CLASS="unpulled"
    TOOLTIP="You have changes to pull"
fi

# Output JSON for Waybar
echo "{\"text\": \"$STATUS\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}" 