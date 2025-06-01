#!/bin/sh

# This script is called when lf exits to clean up any mess left by the preview script

# If using ueberzug for previews
if [ -n "$FIFO_UEBERZUG" ]; then
    printf '{"action": "remove", "identifier": "preview"}\n' > "$FIFO_UEBERZUG"
fi

# If there are other clean-up tasks, add them here 