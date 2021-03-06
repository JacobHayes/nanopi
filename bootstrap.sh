#!/usr/bin/env bash
#
# Modified from: https://github.com/sirselim/jetson_nanopore_sequencing/blob/main/setup-guide-mk1c.txt

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
NC='\033[0m'

echo -n "Enter the data and log directory: "
read -r DATA_DIR

RELEASE="$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)"
if [[ "$RELEASE" != "xenial" ]] && [[ "$RELEASE" != "bionic" ]]; then
    echo -e "${RED}'${RELEASE}' is not supported directly, falling back to 'bionic' packages.${NC}"
    RELEASE="bionic"
fi

# Workaround occasional freezes when resizing windows, etc[1]. It is marked as fixed and fresh installs appear to be
# using a later linux-raspi version, but I still encountered the issue.
#   1: https://bugs.launchpad.net/ubuntu/+source/linux-raspi/+bug/1946368
sudo sed -i \
    -e 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-fkms-v3d/g' \
    /boot/firmware/config.txt

# Install MinKNOW software
sudo apt update
sudo apt install -y apt-transport-https gnupg2 wget

wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | sudo apt-key add -
echo "deb [arch=arm64] https://cdn.oxfordnanoportal.com/apt $RELEASE-stable-mk1c non-free" | sudo tee /etc/apt/sources.list.d/nanoporetech.sources.list
echo "deb [arch=arm64] https://mirror.oxfordnanoportal.com/apt $RELEASE-stable-mk1c non-free" | sudo tee -a /etc/apt/sources.list.d/nanoporetech.sources.list

sudo apt update
sudo apt install -y \
    minknow-core-minion-1c-offline \
    ont-bream4-mk1c \
    ont-configuration-customer-mk1c \
    ont-kingfisher-ui-mk1c \
    ont-vbz-hdf-plugin

# Configure data and log directories
sudo mkdir -p "$DATA_DIR/data"
sudo mkdir -p "$DATA_DIR/logs"
sudo /opt/ont/minknow/bin/config_editor \
  --conf user \
  --filename /opt/ont/minknow/conf/user_conf \
  --set output_dirs.base="$DATA_DIR/data" \
  --set output_dirs.logs="$DATA_DIR/logs"

# Configure MinKNOW (override MinIONMK1C defaults)
sudo sed -i \
    -e 's/Serial=.*/Serial=nanopi/g' \
    /etc/oxfordnanopore/configs/identity.config
sudo sed -i \
    -e 's/"device_type":.*/"device_type": "MinION",/' \
    -e 's/"host_type":.*/"host_type": "PC",/' \
    /opt/ont/minknow/conf/app_conf

sudo sed -i \
    -e 's/--hide-mouse-cursor//g' \
    -e 's/--keyboard//g' \
    -e 's/--zoom-factor 2/--zoom-factor 1/g' \
    /usr/bin/minknow_ui_start.sh \
    /usr/share/applications/minknow.desktop

sudo sed -i -e 's/User=.*/User=root/g' -e 's/Group=.*/Group=root/g' /usr/lib/systemd/system/minknow.service

sudo systemctl enable minknow.service
sudo systemctl restart minknow.service

ln -s /usr/share/applications/minknow.desktop /home/nanopi/Desktop/minknow.desktop

echo "Done!"
