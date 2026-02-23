#!/bin/bash

# ==============================
# GLOBAL CONFIG
# ==============================

PROM_VERSION="2.48.0"
GRAFANA_VERSION="10.2.0"

# ==============================
# UTILITY FUNCTIONS
# ==============================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Please run this script as root."
        exit 1
    fi
}

# ==============================
# INSTALLATION FUNCTIONS
# ==============================

install_prometheus() {
    echo "Downloading Prometheus . . ."
    wget https://github.com/prometheus/prometheus/releases/download/v3.5.1/prometheus-3.5.1.linux-amd64.tar.gz
    echo "Downloading Node exporter"
    wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz

    echo "Extracting prometheus & node exporter . . ."
    tar xvf prometheus-3.5.1.linux-amd64.tar.gz
    tar xvf node_exporter-1.10.2.linux-amd64.tar.gz

    echo "Creating user group"
    groupadd --system prometheus
    
    echo "Creating user"
    useradd --system -s /sbin/nologin -g prometheus prometheus
    
    echo "moving binary file to /usr/local/bin"
    mv prometheus-3.5.1.linux-amd64/prometheus /usr/local/bin/
    mv prometheus-3.5.1.linux-amd64/promtool /usr/local/bin/
    mv node_exporter-1.10.2.linux-amd64/node_exporter /usr/local/bin
    
    echo "Creating configuration"
    mkdir /etc/prometheus

   echo "Creating directory for database"
    mkdir /var/lib/prometheus

    echo "Changing databes directory ownership"
    chown -R prometheus:prometheus /var/lib/prometheus
    mv prometheus-3.5.1.linux-amd64/prometheus.yml /etc/prometheus/

    echo "!!! WARNING !!!"
    echo "This configuration are stock configuration, i suggest you to reconfig to your liking "
    echo " "

    echo "Setting up service . . ."
    curl -L https://raw.githubusercontent.com/SmexyHarambe/PROMETHEUS-GRAFANA-AUTOCONFIG-SCRIPT/main/prometheus.service -o /etc/systemd/system/prometheus.service
    systemctl enable --now prometheus.service

    curl -L https://raw.githubusercontent.com/SmexyHarambe/PROMETHEUS-GRAFANA-AUTOCONFIG-SCRIPT/main/node_exporter.service -o /etc/systemd/system/node_exporter.service
    systemctl enable --now node_exporter.service

	systemctl daemon-reload
    systemctl restart prometheus

    echo "Prometheus installation complete."
}

install_grafana() {
    echo "Setting up for grafana installation . . ."
    echo "Installing apt-transport-https packages. . ."
    apt-get install -y apt-transport-https wget gnupg
    
    echo "importing GPG key"
    mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
    
    echo "adding repository for stable releases"
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
    apt update


    echo "Installing grafana . . ."
    apt-get install grafana
	systemctl daemon-reload
    systemctl enable --now grafana-server.service
    echo "Grafana installation complete."
}

install_both() {
    install_prometheus
    install_grafana
}

# ==============================
# MAIN MENU
# ==============================

while true; do
    echo
    echo "===== !!! WELCOME !!! ====="
    echo
    echo "This script will help you to set up server monitoring using Prometheus and Grafana"
    echo "Choose installation:"
    echo "1) Prometheus"
    echo "2) Grafana"
    echo "3) Prometheus & Grafana"
    echo "4) Exit"
    echo

    read -p "Enter preferred installation (1/2/3/e): " choice

    case "$choice" in

        1)
            echo
            echo "This script will automatically run Prometheus installation processes"
            echo "You can install Grafana manually after this installation finished"

            while true; do
                read -p "Do you wish to continue? (y/n): " confirm

                case "$confirm" in
                    [Yy])
                        install_prometheus
                        exit 0
                        ;;
                    [Nn])
                        echo "Installation cancelled."
                        break
                        ;;
                    *)
                        echo "Invalid input. Please enter y or n."
                        ;;
                esac
            done
            ;;

        2)
            echo
            echo "This script will automatically run Grafana installation processes"
            echo "You can install Prometheus manually after this installation finished"

            while true; do
                read -p "Do you wish to continue? (y/n): " confirm

                case "$confirm" in
                    [Yy])
			install_grafana
                        exit 0
                        ;;
                    [Nn])
                        echo "Installation cancelled."
                        break
                        ;;
                    *)
                        echo "Invalid input. Please enter y or n."
                        ;;
                esac
            done
            ;;

        3)
            echo
            echo "This script will automatically run Prometheus and Grafana installation processes"

            while true; do
                read -p "Do you wish to continue? (y/n): " confirm

                case "$confirm" in
                    [Yy])
			install_both 
                        exit 0
                        ;;
                    [Nn])
                        echo "Installation cancelled."
                        break
                        ;;
                    *)
                        echo "Invalid input. Please enter y or n."
                        ;;
                esac
            done
            ;;

        e)
            echo "Exiting installer..."
            exit 0
            ;;

        *)
            echo "Invalid choice. Please select 1, 2, 3, or e."
            ;;
    esac

done
