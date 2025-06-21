function dashboard --description "Start the Evil Space Dashboard"
    set current_dir (pwd)
    
    # Navigate to dotfiles directory
    if test -d ~/dotfiles
        cd ~/dotfiles
        
        if test -f dashboard/start_dashboard.fish
            echo "🚀 Starting Evil Space Dashboard from $current_dir..."
            fish dashboard/start_dashboard.fish
        else
            echo "❌ Dashboard not found in ~/dotfiles/dashboard/"
            cd $current_dir
            return 1
        end
    else
        echo "❌ Dotfiles directory not found at ~/dotfiles"
        return 1
    end
    
    # Return to original directory when dashboard stops
    cd $current_dir
end 