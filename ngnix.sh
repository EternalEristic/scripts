#!/bin/bash

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install Nginx if it's not already installed
if ! command -v nginx &> /dev/null
then
    echo "Nginx not found. Installing Nginx..."
    apt update
    apt install -y nginx
fi

# Create Nginx template file
cat <<EOF > /etc/nginx/nginx_template.conf
server {
    listen EXTERNAL_IP:EXTERNAL_PORT;
    server_name _;

    location / {
        proxy_pass http://localhost:LOCAL_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Function to set up Nginx configuration
setup_nginx() {
    local local_port=$1
    local external_port=$2
    local config_file="/etc/nginx/sites-available/service_$external_port.conf"

    cp /etc/nginx/nginx_template.conf "$config_file"
    sed -i "s/LOCAL_PORT/$local_port/g" "$config_file"
    sed -i "s/EXTERNAL_PORT/$external_port/g" "$config_file"
    sed -i "s/EXTERNAL_IP/$(hostname -I | cut -d' ' -f1)/g" "$config_file"

    ln -s "$config_file" /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
}

# Main logic
read -p "Enter the local port number: " local_port
read -p "Enter the external port number: " external_port

setup_nginx "$local_port" "$external_port"
