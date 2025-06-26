# Fish completions for appwall

complete -c appwall -l apps -d "Launch application selector"
complete -c appwall -l wallpapers -d "Launch wallpaper selector"
complete -c appwall -l config -d "Path to config file" -r
complete -c appwall -l wallpaper-dir -d "Override wallpaper directory" -r
complete -c appwall -l help -d "Show help message"
complete -c appwall -l version -d "Show version"
