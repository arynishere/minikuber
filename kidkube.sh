#!/bin/bash
# ============================================================
# Kubernetes Installer Script - "KidKube"
# Author: Ariyan Afshar (Rewritten by ChatGPT)
# Works on Debian/Ubuntu and RedHat/CentOS-based systems
# ============================================================

set -e

# === Color setup ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# === Banner ===
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                     🚀 KIDKUBE INSTALLER 🚀                  ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo -e "${BOLD}${BLUE}Starting Kubernetes installation...${NC}"

# === Function: Check command existence ===
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# === Detect OS and Architecture ===
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    echo -e "${RED}Unsupported OS.${NC}"
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo -e "${YELLOW}Detected OS:${NC} $OS"
echo -e "${YELLOW}Detected Architecture:${NC} $ARCH"

# === Ensure prerequisites ===
for cmd in curl sudo; do
    if ! check_command "$cmd"; then
        echo -e "${YELLOW}Installing missing dependency: $cmd${NC}"
        if [ "$OS" == "debian" ]; then
            sudo apt update && sudo apt install -y "$cmd"
        else
            sudo yum install -y "$cmd"
        fi
    fi
done

# === Install kubectl ===
if ! check_command kubectl; then
    echo -e "${BLUE}Installing kubectl...${NC}"
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    if [ -z "$KUBECTL_VERSION" ]; then
        echo -e "${RED}Failed to fetch kubectl version.${NC}"
        exit 1
    fi

    curl -Lo kubectl "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$ARCH/kubectl"
    sudo install -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}kubectl installed successfully: $(kubectl version --client --short)${NC}"
else
    echo -e "${GREEN}kubectl already installed: $(kubectl version --client --short)${NC}"
fi

# === Choose Kubernetes Distribution ===
echo -e "\n${BOLD}Select Kubernetes distribution:${NC}"
echo "1) Minikube"
echo "2) k3s + Kind (k3d alternative)"
read -rp "Enter choice [1-2]: " K8S_CHOICE

# === Install Minikube ===
if [ "$K8S_CHOICE" == "1" ]; then
    echo -e "${BLUE}Installing Minikube...${NC}"

    if check_command minikube; then
        echo -e "${YELLOW}Minikube already installed: $(minikube version)${NC}"
        read -rp "Reinstall/update Minikube? [y/N]: " REINSTALL
        [[ "$REINSTALL" =~ ^[Yy]$ ]] || exit 0
    fi

    echo "Choose installation type:"
    echo "1) Binary"
    echo "2) Package (${OS} format)"
    read -rp "Enter choice [1-2]: " TYPE

    if [ "$TYPE" == "1" ]; then
        curl -LO "https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-$ARCH"
        sudo install -m 0755 "minikube-linux-$ARCH" /usr/local/bin/minikube
        rm "minikube-linux-$ARCH"
    else
        if [ "$OS" == "debian" ]; then
            curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_${ARCH}.deb"
            sudo dpkg -i "minikube_latest_${ARCH}.deb"
            rm "minikube_latest_${ARCH}.deb"
        else
            curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-latest.${ARCH}.rpm"
            sudo rpm -Uvh "minikube-latest.${ARCH}.rpm"
            rm "minikube-latest.${ARCH}.rpm"
        fi
    fi

    echo -e "\nChoose Minikube driver:"
    echo "1) Docker"
    echo "2) VirtualBox"
    echo "3) KVM2"
    read -rp "Enter choice [1-3]: " DRIVER_CHOICE

    case "$DRIVER_CHOICE" in
        1) DRIVER="docker" ;;
        2) DRIVER="virtualbox" ;;
        3) DRIVER="kvm2" ;;
        *) DRIVER="docker"; echo -e "${YELLOW}Defaulting to Docker driver.${NC}" ;;
    esac

    # === Install driver dependencies ===
    if [ "$DRIVER" == "docker" ]; then
        if ! check_command docker; then
            echo -e "${BLUE}Installing Docker...${NC}"
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y docker.io
            else
                sudo yum install -y docker
            fi
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
        fi
    elif [ "$DRIVER" == "virtualbox" ]; then
        if ! check_command VBoxManage; then
            echo -e "${BLUE}Installing VirtualBox...${NC}"
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y virtualbox
            else
                sudo yum install -y virtualbox
            fi
        fi
    elif [ "$DRIVER" == "kvm2" ]; then
        if ! check_command virsh; then
            echo -e "${BLUE}Installing KVM dependencies...${NC}"
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
            else
                sudo yum install -y qemu-kvm libvirt libvirt-daemon libvirt-client virt-install virt-manager
            fi
            sudo usermod -aG libvirt "$USER"
        fi
    fi

    echo -e "${BLUE}Starting Minikube with driver: $DRIVER${NC}"
    minikube start --driver="$DRIVER" --force

# === Install k3s + Kind ===
elif [ "$K8S_CHOICE" == "2" ]; then
    echo -e "${BLUE}Installing Kind & k3s...${NC}"

    # Install Kind
    curl -Lo kind "https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-$ARCH"
    sudo install -m 0755 kind /usr/local/bin/kind
    rm kind

    # Install k3s
    curl -sfL https://get.k3s.io | sh -

else
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
fi

# === Final Summary ===
echo -e "\n${GREEN}===== Installation Completed Successfully! =====${NC}"
echo -e "${YELLOW}kubectl version:${NC} $(kubectl version --client --short)"
echo -e "${YELLOW}Next steps:${NC}"
echo "- For Minikube: run ${BOLD}minikube status${NC}"
echo "- For k3s: run ${BOLD}sudo k3s kubectl get nodes${NC}"
echo "- For Kind: run ${BOLD}kind get clusters${NC}"
