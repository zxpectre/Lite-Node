#!/bin/bash

# Global configuration
VERSION=v1.0
NAME="admin tool"
# Get the full path of the current script's directory
script_dir=$(dirname "$(realpath "$BASH_SOURCE")")
# Remove the last folder from the path and rename it to KLITE_HOME
KLITE_HOME=$(dirname "$script_dir")
path_line="export PATH=\"$script_dir:\$PATH\""
CURL_TIMEOUT=5

# Append path_line to shell configuration files
append_path_to_shell_configs() {
    for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$file" ] && ! grep -Fxq "$path_line" "$file"; then
            echo "$path_line" >> "$file"
        fi
    done
}

# Function definitions
install_dependencies() {

    # Check if the dependencies were already installed
    if [ -f "./.dependency_installation_status" ]; then
        # echo "Dependencies already installed."
        echo " "
        return 0
    fi

    os_name="$(uname -s)"
    case "${os_name}" in
        Linux*)
            . /etc/os-release
            case "${ID}" in
                ubuntu|debian)
                    gum spin --spinner dot --title "Updating..." -- echo && sudo apt-get update
                    gum spin --spinner dot --title "Installing..." -- echo && sudo apt-get install -y curl awk gum
                    ;;
                fedora|rhel)
                    gum spin --spinner dot --title "Installing..." -- echo && sudo dnf install -y curl awk gum &> /dev/null
                    ;;
                arch|manjaro)
                    gum spin --spinner dot --title "Installing..." -- echo && sudo pacman -S curl awk gum &> /dev/null
                    ;;
                alpine)
                    gum spin --spinner dot --title "Installing..." -- echo && sudo apk add curl awk gum &> /dev/null
                    ;;
                *)
                    echo "Unsupported Linux distribution for automatic installation."
                    return 1
                    ;;
            esac
            ;;
        Darwin*)
            gum spin --spinner dot --title "Installing..." -- echo && brew install curl awk gum &> /dev/null
            ;;
        MINGW*|MSYS*|CYGWIN*)
            gum spin --spinner dot --title "Installing..." -- echo && winget install curl awk gum &> /dev/null
            ;;
        *)
            echo "Unsupported operating system."
            return 1
            ;;
    esac

    # Create a file to indicate successful installation
    touch "./.dependency_installation_status"
    echo "Dependencies installed successfully."
}

# Check Docker function
check_docker() {
    # Check if docker command is available
    if ! command -v docker > /dev/null 2>&1; then
        echo -e "\nDocker not installed.\n"
        if gum confirm --unselected.foreground 231 --unselected.background 39 --selected.bold --selected.background 121 --selected.foreground 231 "Would you like to install Docker now?"; then
            docker_install
        else
            return 1
        fi
    # Check if docker-compose command is available
    elif ! command -v docker-compose > /dev/null 2>&1; then
        echo -e "\ndocker-compose not installed.\n"
        return 1
    # Check if Docker is running by executing a test container
    else
        # Check if Docker is running
        if ! docker run --rm hello-world > /dev/null 2>&1; then
            echo -e "\nDocker is not running.\n"

            if gum confirm --unselected.foreground 231 --unselected.background 39 --selected.bold --selected.background 121 --selected.foreground 231 "Would you like to try starting Docker now?"; then
                echo "Attempting to start Docker..."
                # Starting Docker based on OS
                os_name="$(uname -s)"
                case "${os_name}" in
                    Linux*)
                        gum spin --spinner dot --title "Starting Docker..." -- echo && sudo systemctl start docker
                        ;;
                    Darwin*)
                        gum spin --spinner dot --title "Starting Docker..." -- echo && Open -a Docker
                        ;;
                    *)
                        echo "Cannot start Docker automatically on this OS."                  
                        return 1
                        ;;
                esac

                # Recheck if Docker starts successfully
                sleep 30  # Wait a bit before rechecking
                if ! docker info > /dev/null 2>&1; then
                    echo -e "\nFailed to start Docker.\n"
                    return 1
                else
                    echo "Docker started successfully."
                fi
            else
                return 1
            fi
        fi
    fi
    # echo "Docker is running."
    return 0
}

docker_status(){
    # Prepare the Docker status message
    docker_status=$(if check_docker; then
        echo "$(gum style --foreground 121 --margin 1  "🐳  Docker Installed and Working")";
    else
        echo "🐳 🔻";
    fi)

    # Function to check the status of a Docker container
    check_container_status() {
    local container_name="$1"
    local up_icon="$2"
    local down_icon="$3"

    if [[ ! -z $(docker ps -qf "name=${container_name}") ]]; then
        echo "${up_icon} $(gum style --foreground 121 " ${container_name}") $(gum style --bold --foreground 121 UP)";
    else
        echo "${down_icon} $(gum style --foreground 160 " ${container_name}") $(gum style --faint --foreground 160 DOWN)";
    fi
    }

    # Check for specific Docker containers
    node_container=$(check_container_status "cardano-node" "🧊 " "🔻 ")
    postgres_container=$(check_container_status "postgress" "🔹 " "🔻 ")
    db_sync_container=$(check_container_status "cardano-db-sync" "🥽 " "🔻 ")
    postgrest_container=$(check_container_status "postgrest" "🪢 " "🔻 ")
    haproxy_container=$(check_container_status "haproxy" "🧢 " "🔻 ")


    # Combine elements into one layout
    combined_layout=$(gum join --vertical --align center\
        "$docker_status " \
        "$node_container" \
        "$postgres_container " \
        "$db_sync_container " \
        "$postgrest_container " \
        "$haproxy_container " \
        "$(echo)")

    gum style \
        --border none \
        --border-foreground 121 \
        --margin "1 0" \
        --padding "0 10" \
        --background black \
        --foreground 121 \
        "$combined_layout"    

}

# Docker Innstall function
docker_install() {
    # Check if Docker was already installed
    if command -v docker > /dev/null 2>&1; then
        echo "Docker is already installed."
        return 0
    fi

    os_name="$(uname -s)"
    case "${os_name}" in
        Linux*)
            . /etc/os-release
            case "${ID}" in
                ubuntu|debian)
                    gum spin --spinner dot --title "Updating..." -- echo && sudo apt-get update
                    gum spin --spinner dot --title "Installing Docker..." -- echo && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                    ;;
                fedora|rhel)
                    gum spin --spinner dot --title "Installing Docker..." -- echo && sudo dnf -y install dnf-plugins-core && sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && sudo dnf install docker-ce docker-ce-cli containerd.io
                    ;;
                arch|manjaro)
                    gum spin --spinner dot --title "Installing Docker..." -- echo && sudo pacman -Syu docker
                    ;;
                alpine)
                    gum spin --spinner dot --title "Installing Docker..." -- echo && sudo apk add docker
                    ;;
                *)
                    echo "Unsupported Linux distribution for automatic Docker installation."
                    return 1
                    ;;
            esac
            ;;
        Darwin*)
            gum spin --spinner dot --title "Installing Docker..." -- echo && brew install --cask docker
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "For Windows, please install Docker Desktop manually."
            return 1
            ;;
        *)
            echo "Unsupported operating system."
            return 1
            ;;
    esac

    # Starting Docker service based on OS
    os_name="$(uname -s)"
    case "${os_name}" in
    Linux*)
        if gum spin --spinner dot --title "Starting Docker..." -- echo && sudo systemctl start docker; then
            echo "Docker installed and started successfully."
        else
            echo "Failed to start Docker on Linux."
            return 1
        fi
        ;;
    Darwin*)
        if gum spin --spinner dot --title "Starting Docker..." -- echo && Open -a Docker; then
            echo "Docker installed and started successfully."
        else
            echo "Failed to start Docker on macOS."
            return 1
        fi
        ;;
    *)
        echo "Cannot start Docker automatically on this OS."
        return 1
        ;;
    esac
}

# Function to check and create or copy .env file
check_env_file() {
    if [ ! -f ".env" ]; then  # Check if .env does not exist
        if [ -f ".env.example" ]; then  # Check if .env.example exists
            cp .env.example .env  # Copy .env.example to .env
            echo ".env file created from .env.example."
        else
            touch .env  # Create a new .env file
            echo "New .env file created."
        fi
    fi
}

# Function to reset .env file
reset_env_file() {
    if [ -f ".env" ]; then  # Check if .env  
        if $(gum confirm --unselected.foreground 231 --unselected.background 39 --selected.bold --selected.background 121 --selected.foreground 231 "Are you sure you want to reset the .env file?"); then
            backup_name=".env.$(date +%Y%m%d%H%M%S)"  # Create a backup name with timestamp
            mv .env "$backup_name"  # Move .env to backup
            echo "Reset .env file. Backup created: $backup_name"
        else
            echo "Reset cancelled."
        fi
    else
        echo "No .env file to reset. Creating a new one with defaults..." 
        cp .env.example .env  # Copy .env.example to.env
    fi
}

# Function to handle .env file (create or edit)
handle_env_file() {
    if [ ! -f ".env" ]; then
        echo "Creating new .env file..."
        touch .env
    fi
    while true; do
        action=$(gum choose --height 15 --item.foreground 39 --cursor.foreground 121 "Add Entry" "Edit Entry" "Remove Entry" "View File" "Reset Config" $(gum style --foreground 208 "Back"))
        
        case "$action" in
            "Add Entry")
                key=$(gum input --placeholder "Enter key")
                value=$(gum input --placeholder "Enter value")

                # Check if key or value is empty
                if [[ -z "$key" || -z "$value" ]]; then
                    echo "Key or value cannot be empty. Entry not added."
                else
                   printf "%s=%s\n" "$key" "$value" >> .env
                   clear
                   gum style --border rounded --border-foreground 121 --padding "1" --margin "1" --foreground green "Current .env content:" "$(cat $KLITE_HOME/.env)"
                fi
                ;;
            "Edit Entry")
                line_to_edit=$(cat $KLITE_HOME/.env | gum filter)
                key=$(echo "$line_to_edit" | cut -d '=' -f 1)
                existing_value=$(echo "$line_to_edit" | cut -d '=' -f 2-)

                # Check if key is empty
                if [[ -z "$key" ]]; then
                    echo "No key selected for editing."
                else
                    new_value=$(gum input --placeholder "Enter new value for $key")

                    # Check if new value is empty or the same as the existing value
                    if [[ -z "$new_value" ]]; then
                        echo "New value cannot be empty. Entry not edited."
                    elif [[ "$new_value" == "$existing_value" ]]; then
                        echo "New value is the same as the existing value. Entry not edited."
                    else
                        sed -i '' "s/^$key=.*/$key=$new_value/" .env
                    fi
                fi
                ;;
            "Remove Entry")
                line_to_remove=$(cat $KLITE_HOME/.env | gum filter)
                key_to_remove=$(echo "$line_to_remove" | cut -d '=' -f 1)

                if [[ -z "$key_to_remove" ]]; then
                    echo "No key selected for removal."
                else
                    # Remove the line from .env file
                    sed -i '' "/^$key_to_remove=/d" .env
                    clear
                    gum style --border rounded --border-foreground 121 --padding "1" --margin "1" --foreground green "Current .env content:" "$(cat $KLITE_HOME/.env)"
                fi
                ;;
            "View File")
                clear
                gum style --border rounded --border-foreground 121 --padding "1" --margin "1" --foreground green "Current .env content:" "$(cat $KLITE_HOME/.env)"
                ;;
            "Reset Config")
                    # Logic for reset config
                    reset_env_file
                    ;;
            "Back")
                show_splash_screen
                break
                ;;
        esac
    done
}

# Menu function with improved UI and submenus
menu() {
    while true; do
        choice=$(gum choose --height 15 --item.foreground 121 --cursor.foreground 39 "Tools" "Monitor" "Setup" "Config" "About" $(gum style --foreground 160 "Exit"))

        case "$choice" in
            "Tools")
            setup_choice=$(gum choose --height 15 --cursor.foreground 229 --item.foreground 39 "$(gum style --foreground 82  "Enter Cardano Node")" "$(gum style --foreground 85  "Logs Cardano Node")" "$(gum style --foreground 87 "gLiveView")" "$(gum style --foreground 117 "cntools")" "$(gum style --foreground 82 "Enter Postgres")" "$(gum style --foreground 85 "Logs Postgres")" "$(gum style --foreground 87 "Enter PSQL")" "$(gum style --foreground 117 "DBs Lists")" "$(gum style --foreground 82 "Enter Dbsync")" "$(gum style --foreground 85 "Logs Dbsync")" "$(gum style --foreground 85 "Logs PostgREST")" "$(gum style --foreground 82 "Enter HAProxy")" "$(gum style --foreground 85 "Logs HAProxy")" "$(gum style --foreground 208 "Back")")
            case "$setup_choice" in
                "Enter Cardano Node")
                    # Enter
                    container_id=$(docker ps -qf "name=cardano-node")
                    if [ -z "$container_id" ]; then
                        echo "No running Node container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "bash"
                    fi
                    show_splash_screen                  
                    ;;
                "Logs Cardano Node")
                    # Enter
                    container_id=$(docker ps -qf "name=cardano-node")
                    if [ -z "$container_id" ]; then
                        echo "No running Node container found."
                    else
                        # Logs
                        docker logs "$container_id" | more
                    fi
                    show_splash_screen                  
                    ;;
                "gLiveView")
                    # Find the Docker container ID with 'postgres' in the name
                    container_id=$(docker ps -qf "name=cardano-node")
                    if [ -z "$container_id" ]; then
                        echo "No running Node container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "/opt/cardano/cnode/scripts/gLiveView.sh"
                    fi
                    show_splash_screen           
                    ;;
                "cntools")
                    # Find the Docker container ID with 'postgres' in the name
                    container_id=$(docker ps -qf "name=cardano-node")
                    if [ -z "$container_id" ]; then
                        echo "No running Node container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "/opt/cardano/cnode/scripts/cntools.sh"
                    fi
                    show_splash_screen           
                    ;;
                "Enter Postgres")
                    # Logic for Enter Postgres
                    container_id=$(docker ps -qf "name=postgress")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "bash"
                    fi
                    show_splash_screen
                    ;;
                "Logs Postgres")
                    # Logic for Enter Postgres
                    container_id=$(docker ps -qf "name=postgress")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL container found."
                    else
                        # Logs
                        docker logs "$container_id" | more
                    fi
                    show_splash_screen
                    ;;
                "Enter PSQL")
                    # Logic for Enter Postgres
                    container_id=$(docker ps -qf "name=postgress")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "/usr/bin/psql -U $POSTGRES_USER -d $POSTGRES_DB"
                    fi
                    show_splash_screen
                    ;;
                "DBs Lists")
                    # Logic for Enter Postgres
                    container_id=$(docker ps -qf "name=postgress")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL found."
                    else
                        # Executing commands in the found container
                        docker exec -it -u postgres "$container_id" bash -c "/scripts/kltables.sh > /scripts/TablesAndIndexesList.txt"
                        echo "TablesAndIndexesList.txt File created in your script folder."
                    fi
                    show_splash_screen
                    ;;
                "Enter Dbsync")
                    # Logic for Enter Dbsync
                    container_id=$(docker ps -qf "name=lite-node-cardano-db-sync")
                    if [ -z "$container_id" ]; then
                        echo "No running Dbsync container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "bash"
                    fi
                    show_splash_screen
                    ;;
                "Logs Dbsync")
                    # Logic for Enter Dbsync
                    container_id=$(docker ps -qf "name=lite-node-cardano-db-sync")
                    if [ -z "$container_id" ]; then
                        echo "No running Dbsync container found."
                    else
                        # Logs
                        docker logs "$container_id" | more
                    fi
                    show_splash_screen
                    ;;
                "Logs PostgREST")
                    # Logic for Enter PostgREST
                    container_id=$(docker ps -qf "name=lite-node-postgrest")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgREST container found."
                    else
                        # Logs
                        docker logs "$container_id" | more
                    fi
                    show_splash_screen
                    ;;
                "Enter HAProxy")
                    # Logic for Enter HAProxy
                    container_id=$(docker ps -qf "name=lite-node-haproxy")
                    if [ -z "$container_id" ]; then
                        echo "No running HAProxy container found."
                    else
                        # Executing commands in the found container
                        docker exec -it "$container_id" bash -c "bash"
                    fi
                    show_splash_screen
                    ;;
                "Logs HAProxy")
                    # Logic for Enter HAProxy
                    container_id=$(docker ps -qf "name=lite-node-haproxy")
                    if [ -z "$container_id" ]; then
                        echo "No running HAProxy container found."
                    else
                        # Logs
                        docker logs "$container_id" | more
                    fi
                    show_splash_screen
                    ;;
            esac
            ;;
            "Setup")
                # Submenu for Setup with plain text options
                setup_choice=$(gum choose --height 15 --cursor.foreground 229 --item.foreground 39 "Initialise Cardano Node"  "Initialise Postgres" "Initialise Dbsync" "Initialise PostgREST" "Initialise HAProxy" "$(gum style --foreground 208 "Back")")

            case "$setup_choice" in
                "Initialise Cardano Node")
                    # Find the Docker container ID with 'postgres' in the name
                    container_id=$(docker ps -qf "name=cardano-node")
                    if [ -z "$container_id" ]; then
                        echo "No running Node container found."
                    else
                        # Executing commands in the found container
                        docker exec "$container_id" bash -c "/scripts/lib/install_cardano_node.sh"
                    fi
                    show_splash_screen                
                    ;;
                "Initialise Postgres")
                    # Logic for installing Postgres
                    container_id=$(docker ps -qf "name=postgress")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL container found."
                    else
                        # Executing commands in the found container
                        docker exec -u posgres "$container_id" bash -c "/scripts/lib/install_postgres.sh"
                    fi
                    show_splash_screen
                    ;;
                "Initialise Dbsync")
                    # Logic for installing Dbsync
                    container_id=$(docker ps -qf "name=lite-node-cardano-db-sync")
                    docker exec "$container_id" bash -c "/scripts/lib/install_dbsync.sh"
                    ;;
                "Initialise PostgREST")
                    # Logic for installing PostgREST
                    container_id=$(docker ps -qf "name=lite-node-postgrest")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL container found."
                    else
                        # Executing commands in the found container
                        docker exec "$container_id" bash -c "echo ECCO; echo basta"
                        docker exec "$container_id" bash -c "/scripts/lib/install_postgrest.sh"
                    fi
                    show_splash_screen
                    ;;
                "Initialise HAProxy")
                    # Logic for installing HAProxy
                    container_id=$(docker ps -qf "name=lite-node-haproxy")
                    if [ -z "$container_id" ]; then
                        echo "No running PostgreSQL container found."
                    else
                        # Executing commands in the found container
                        docker exec "$container_id" bash -c "/scripts/lib/install_haproxy.sh"
                    fi
                    show_splash_screen
                    ;;
                
                "Back")
                    # Back to Main Menu
                    ;;
            esac
            ;;

            "$(gum style --foreground green "Monitor")")
            # Submenu for Monitor
            monitor_choice=$(gum choose --height 15 --item.foreground 39 --cursor.foreground 121 \
                "Docker Status" \
                "Docker Up/Reload" \
                "Docker Down" \
                $(gum style --foreground 208 "Back"))

            case "$monitor_choice" in
                "Docker Status")
                    # Logic for Docker Status
                    clear
                    show_splash_screen
                    docker_status
                    # gum style --border rounded --border-foreground 121 --padding "1" --margin "1" --foreground 121 "$(docker-compose ps | awk '{print $4, $8}')"
                    ;;
                "Docker Up/Reload")
                    # Logic for Docker Up
                    clear
                    show_splash_screen
                    gum spin --spinner dot --spinner.bold --show-output --title.align center --title.bold --spinner.foreground 121 --title.foreground 121  --title "Koios Lite Starting services..." -- echo && docker-compose -f $KLITE_HOME/docker-compose.yml up -d
                    ;;
                "Docker Down")
                    # Logic for Docker Down
                    clear
                    show_splash_screen
                    gum spin --spinner dot --spinner.bold --show-output --title.align center --title.bold --spinner.foreground 202 --title.foreground 202 --title "Koios Lite Stopping services..." -- echo && docker-compose -f $KLITE_HOME/docker-compose.yml down
                    ;;
                "Back")
                    # Back to Main Menu
                    ;;
            esac
            ;;

            "Config")
            # Submenu for Config
            handle_env_file
            ;;

            "About")
                clear
                gum style --border rounded --foreground 121 --border-foreground 121 --align center "$(gum join --vertical \
                "$(show_splash_screen)" \
                "$(gum style --align center --width 50 --margin "1 2" --padding "2 4" 'About: ' ' Koios administration tool.')" \
                "$(gum style --align center --width 50 '//github.com/koios-official/Lite-Node')")"
            ;;

            "Exit")
                clear
                echo "Thanks for using Koios Lite Node."
                exit 0  # Exit the menu loop
                ;;
        esac
    done
}

# Enhanced display UI function using gum layout
display_ui() {
    show_splash_screen
    # Wait for gum style commands to complete
    menu
}

show_splash_screen(){
    # Clear the screen before displaying UI
    clear
    combined_layout1=$(gum style --foreground 121 --align center "$(cat ./scripts/.logo)")
    
    combined_layout2=$(gum join --horizontal \
        "$(gum style --bold --align center "Koios Lite Node")" \
        "$(gum style --faint --foreground 229 --align center " - $NAME $VERSION")")

    combined_layout=$(gum join --vertical \
        "$combined_layout1 " \
        "$combined_layout2")
    
    # Display the combined layout with a border
    gum style \
    --border none \
    --border-foreground 121 \
    --margin "2" \
    --padding "2 2" \
    --background black \
    --foreground 121 \
    "$combined_layout"
}

# Function to process command line arguments
process_args() {
    case "$1" in
        --about)
            gum style --border rounded --foreground 121 --border-foreground 121 --align center "$(gum join --vertical \
                "$(show_splash_screen)" \
                "$(gum style --align center --width 50 --margin "1 2" --padding "2 4" 'About: ' ' Koios administration tool.')" \
                "$(gum style --align center --width 50 'github.com/koios-official/Lite-Node')")"
                show_ui=false
            ;;
        --install-dependencies)
            install_dependencies
            ;;
        --check-docker)
            check_docker
            ;;
        --handle-env-file)
            handle_env_file
            ;;
        --reset-env)
            reset_env_file
            ;;
        --docker-status)
            docker_status
            ;;
        --docker-up)
            docker-compose -f "$KLITE_HOME/docker-compose.yml" up -d
            ;;
        --docker-down)
            docker-compose -f "$KLITE_HOME/docker-compose.yml" down
            ;;
       --enter-node)
            container_id=$(docker ps -qf "name=cardano-node")
            [ -z "$container_id" ] && echo "No running Node container found." || docker exec -it "$container_id" bash
            ;;
        --logs-node)
            container_id=$(docker ps -qf "name=cardano-node")
            [ -z "$container_id" ] && echo "No running Node container found." || docker logs "$container_id" | more
            ;;
        --gliveview)
            container_id=$(docker ps -qf "name=cardano-node")
            [ -z "$container_id" ] && echo "No running Node container found." || docker exec -it "$container_id" /opt/cardano/cnode/scripts/gLiveView.sh
            ;;
        --cntools)
            container_id=$(docker ps -qf "name=cardano-node")
            [ -z "$container_id" ] && echo "No running Node container found." || docker exec -it "$container_id" /opt/cardano/cnode/scripts/cntools.sh
            ;;
        --enter-postgres)
            execute_in_container "postgress" "bash"
            ;;
        --logs-postgres)
            show_logs "postgress"
            ;;
        --enter-postgrest)
            execute_in_container "lite-node-postgrest" "sh"
            ;;
        --logs-postgrest)
            show_logs "lite-node-postgrest"
            ;;
        --enter-dbsync)
            execute_in_container "lite-node-cardano-db-sync" "bash"
            ;;
        --logs-dbsync)
            show_logs "lite-node-cardano-db-sync"
            ;;
        --enter-haproxy)
            execute_in_container "lite-node-haproxy" "bash"
            ;;
        --logs-haproxy)
            show_logs "lite-node-haproxy"
            ;;
        --help)
            echo "Koios Administration Tool Help Menu:"
            echo -e "------------------------------------\n"
            echo -e "Welcome to the Koios Administration Tool Help Menu.\n"
            echo -e "Below are the available commands and their descriptions:\n"
            echo -e "--about: \t\t\t Displays information about the Koios administration tool."
            echo -e "--install-dependencies: \t Installs necessary dependencies."
            echo -e "--check-docker: \t\t Checks if Docker is running."
            echo -e "--handle-env-file: \t\t Manage .env file."
            echo -e "--reset-env: \t\t\t Resets the .env file to defaults."
            echo -e "--docker-status: \t\t Shows the status of Docker containers."
            echo -e "--docker-up: \t\t\t Starts Docker containers defined in docker-compose.yml."
            echo -e "--docker-down: \t\t\t Stops Docker containers defined in docker-compose.yml."
            echo -e "--enter-node: \t\t\t Accesses the Cardano Node container."
            echo -e "--logs-node: \t\t\t Displays logs for the Cardano Node container."
            echo -e "--gliveview: \t\t\t Executes gLiveView in the Cardano Node container."
            echo -e "--cntools: \t\t\t Runs CNTools in the Cardano Node container."
            echo -e "--enter-postgres: \t\t Accesses the Postgres container."
            echo -e "--logs-postgres: \t\t Displays logs for the Postgres container."
            echo -e "--enter-postgrest: \t\t Accesses the PostgREST container."
            echo -e "--logs-postgrest: \t\t Displays logs for the PostgREST container."
            echo -e "--enter-dbsync: \t\t Accesses the DBSync container."
            echo -e "--logs-dbsync: \t\t\t Displays logs for the DBSync container."
            echo -e "--enter-haproxy: \t\t Accesses the HAProxy container."
            echo -e "--logs-haproxy: \t\t Displays logs for the HAProxy container.\n\n"
            ;;
        *)
            # Check if the number of arguments is zero
            if [ $# -eq 0 ]; then
                display_ui  # Call the display function
                check_env_file
            else
                echo "Unknown command: '$1'"
                echo "Use --help to see available commands."
                sleep 3
            fi
            ;;
    esac
}

execute_in_container() {
    local container_name=$1
    local command=$2
    local container_id=$(docker ps -qf "name=${container_name}")
    if [ -z "$container_id" ]; then
        echo "No running ${container_name} container found."
    else
        docker exec -it "$container_id" $command
    fi
}

show_logs() {
    local container_name=$1
    local container_id=$(docker ps -qf "name=${container_name}")
    if [ -z "$container_id" ]; then
        echo "No running ${container_name} container found."
    else
        docker logs "$container_id" | more
    fi
}

# To find the right color's code
show_colors(){
    for i in {0..255}; do
        printf "\e[38;5;${i}m%3d\e[0m " "${i}"
        if (( (i + 1) % 16 == 0 )); then
            echo
        fi
    done
}

# Main function to orchestrate script execution
main() {
    append_path_to_shell_configs
    cd "$KLITE_HOME" || exit
    source .env
    install_dependencies || { echo "Failed to install dependencies."; exit 1; }
    process_args "$@"  # Process any provided command line arguments
    if [ "$show_ui" = true ]; then
        display_ui
    fi
    #show_colors
}

# Execute the main function
main "$@"