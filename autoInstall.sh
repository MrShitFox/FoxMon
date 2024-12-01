#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "Please run this script as root."
   exit 1
fi

echo "Starting FoxMon installation..."

# Function to check and install dependencies
install_dependency() {
    if ! command -v $1 &> /dev/null
    then
        echo "Installing dependency: $1..."
        apt-get update -y
        apt-get install -y $1
        if [ $? -eq 0 ]; then
            echo "Installing $1 - Success!"
        else
            echo "Installing $1 - Failed!"
            exit 1
        fi
    else
        echo "$1 is already installed."
    fi
}

# Install wget and unzip if necessary
install_dependency wget
install_dependency unzip

# Variables
DOWNLOAD_URL="https://github.com/MrShitFox/FoxMon/releases/download/v1.0/FoxMon-v1.0.0-linux-amd64.zip"
DOWNLOAD_DIR="/tmp/foxmon_install"
BINARY_NAME="FoxMon-v1.0.0-linux-amd64"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/foxmon.service"
USER_NAME="foxmon"
GROUP_NAME="foxmon"

# Create temporary directory for installation
mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR

# Download FoxMon archive
echo "Downloading FoxMon..."
wget -O foxmon.zip $DOWNLOAD_URL
if [ $? -eq 0 ]; then
    echo "Downloading FoxMon - Success!"
else
    echo "Downloading FoxMon - Failed!"
    exit 1
fi

# Extract the archive
echo "Extracting FoxMon..."
unzip foxmon.zip
if [ $? -eq 0 ]; then
    echo "Extracting FoxMon - Success!"
else
    echo "Extracting FoxMon - Failed!"
    exit 1
fi

# Move the binary to /usr/local/bin and rename
echo "Installing FoxMon binary..."
mv $BINARY_NAME $INSTALL_DIR/foxmon
if [ $? -eq 0 ]; then
    echo "Installing FoxMon binary - Success!"
else
    echo "Installing FoxMon binary - Failed!"
    exit 1
fi

# Set permissions
echo "Setting permissions..."
chmod 755 $INSTALL_DIR/foxmon
if [ $? -eq 0 ]; then
    echo "Setting permissions - Success!"
else
    echo "Setting permissions - Failed!"
    exit 1
fi

# Create foxmon user and group if they do not exist
if id -u $USER_NAME &>/dev/null; then
    echo "User $USER_NAME already exists."
else
    echo "Creating user $USER_NAME..."
    useradd -r -s /bin/false $USER_NAME
    if [ $? -eq 0 ]; then
        echo "Creating user $USER_NAME - Success!"
    else
        echo "Creating user $USER_NAME - Failed!"
        exit 1
    fi
fi

# Change ownership of the binary to foxmon
chown $USER_NAME:$GROUP_NAME $INSTALL_DIR/foxmon

# Create systemd service
echo "Creating systemd service..."
cat > $SERVICE_FILE <<EOL
[Unit]
Description=FoxMon System Monitoring Daemon
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/foxmon
Restart=on-failure
User=$USER_NAME
Group=$GROUP_NAME
WorkingDirectory=$INSTALL_DIR
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=foxmon

[Install]
WantedBy=multi-user.target
EOL

if [ $? -eq 0 ]; then
    echo "Creating systemd service - Success!"
else
    echo "Creating systemd service - Failed!"
    exit 1
fi

# Reload systemd configuration
echo "Reloading systemd configuration..."
systemctl daemon-reload
if [ $? -eq 0 ]; then
    echo "Reloading systemd configuration - Success!"
else
    echo "Reloading systemd configuration - Failed!"
    exit 1
fi

# Enable and start the service
echo "Enabling FoxMon service..."
systemctl enable foxmon.service
if [ $? -eq 0 ]; then
    echo "Enabling FoxMon service - Success!"
else
    echo "Enabling FoxMon service - Failed!"
    exit 1
fi

echo "Starting FoxMon service..."
systemctl start foxmon.service
if [ $? -eq 0 ]; then
    echo "Starting FoxMon service - Success!"
else
    echo "Starting FoxMon service - Failed!"
    exit 1
fi

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf $DOWNLOAD_DIR

echo "FoxMon installation completed successfully!"
