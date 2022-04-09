#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

RED='\033[0;31m'
NC='\033[0m'

# Modified from: https://github.com/sirselim/jetson_nanopore_sequencing/blob/main/setup-guide-mk1c.txt
RELEASE="$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)"
if [[ "$RELEASE" != "xenial" ]] && [[ "$RELEASE" != "bionic" ]]; then
    echo -e "${RED}'${RELEASE}' is not supported directly, falling back to 'bionic' packages.${NC}"
    RELEASE="bionic"
fi

sudo apt update
sudo apt install -y apt-transport-https gnupg2 vim wget

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
