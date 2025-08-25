#!/bin/bash
cat << "EOF"
╔╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╗
╠╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╬╣
╠╣__        __   _                            _                               ╠╣
╠╣\ \      / /__| | ___ ___  _ __ ___   ___  | |_ ___                         ╠╣
╠╣ \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \                        ╠╣
╠╣  \ V  V /  __/ | (_| (_) | | | | | |  __/ | || (_) |                       ╠╣
╠╣ _ \_/\_/ \___|_|\___\___/|_| |_|_|_|\___|  \__\___/_                       ╠╣
╠╣(_)_ __  ___| |_ __ _| | | | | _(_) __| | | ___   _| |__   ___ _ __         ╠╣
╠╣| | '_ \/ __| __/ _` | | | | |/ / |/ _` | |/ / | | | '_ \ / _ \ '__|  _____ ╠╣
╠╣| | | | \__ \ || (_| | | | |   <| | (_| |   <| |_| | |_) |  __/ |    |_____|╠╣
╠╣|_|_| |_|___/\__\__,_|_|_| |_|\_\_|\__,_|_|\_\\__,_|_.__/ \___|_|           ╠╣
╠╣  __ _ _ __ _   _ _ __ (_)___| |__   ___ _ __ ___                           ╠╣
╠╣ / _` | '__| | | | '_ \| / __| '_ \ / _ \ '__/ _ \                          ╠╣
╠╣| (_| | |  | |_| | | | | \__ \ | | |  __/ | |  __/                          ╠╣
╠╣ \__,_|_|   \__, |_| |_|_|___/_| |_|\___|_|  \___|                          ╠╣
╠╣            |___/                                                           ╠╣
╠╬╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╦╬╣
╚╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╝
EOF
set -e

echo "===== Kubernetes Installer Script ====="

for cmd in curl sudo; do
    command -v $cmd >/dev/null 2>&1 || {
        echo "$cmd is required, installing..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y $cmd
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y $cmd
        else
            echo "Unsupported OS for installing $cmd"
            exit 1
        fi
    }
done

if [ -f /etc/redhat-release ]; then
    OS="redhat"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    echo "Unsupported OS"
    exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected OS: $OS"
echo "Detected Architecture: $ARCH"

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Installing kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    if [ "$ARCH" == "amd64" ]; then
        curl -Lo "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    else
        curl -Lo "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/arm64/kubectl"
    fi
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed: $(kubectl version --client --short)"
fi

echo "Which Kubernetes do you want to install?"
echo "1) Minikube"
echo "2) k3s + Kind (k3d)"
read -rp "Enter choice [1-2]: " K8S_CHOICE

if [ "$K8S_CHOICE" == "1" ]; then
    if command -v minikube >/dev/null 2>&1; then
        echo "Minikube already installed: $(minikube version)"
        read -rp "Do you want to reinstall/update it? [y/N]: " REINSTALL
        [[ "$REINSTALL" =~ ^[Yy]$ ]] || exit 0
    fi

    if [ "$OS" == "redhat" ]; then
        echo "Choose installation type: "
        echo "1) Binary"
        echo "2) RPM package"
        read -rp "Enter choice [1-2]: " TYPE
    elif [ "$OS" == "debian" ]; then
        echo "Choose installation type: "
        echo "1) Binary"
        echo "2) DEB package"
        read -rp "Enter choice [1-2]: " TYPE
    fi

    if [ "$TYPE" == "1" ]; then
        # Binary
        if [ "$ARCH" == "amd64" ]; then
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
        else
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-arm64
            sudo install minikube-linux-arm64 /usr/local/bin/minikube
            rm minikube-linux-arm64
        fi
    elif [ "$TYPE" == "2" ]; then
        # Package
        if [ "$OS" == "debian" ]; then
            if [ "$ARCH" == "amd64" ]; then
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
                sudo dpkg -i minikube_latest_amd64.deb
                rm minikube_latest_amd64.deb
            else
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_arm64.deb
                sudo dpkg -i minikube_latest_arm64.deb
                rm minikube_latest_arm64.deb
            fi
        elif [ "$OS" == "redhat" ]; then
            if [ "$ARCH" == "amd64" ]; then
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
                sudo rpm -Uvh minikube-latest.x86_64.rpm
                rm minikube-latest.x86_64.rpm
            else
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.aarch64.rpm
                sudo rpm -Uvh minikube-latest.aarch64.rpm
                rm minikube-latest.aarch64.rpm
            fi
        fi
    else
        echo "Invalid choice"
        exit 1
    fi

    echo "Choose a Minikube driver:"
    echo "1) Docker"
    echo "2) VirtualBox"
    echo "3) KVM2"
    read -rp "Enter choice [1-3]: " DRIVER_CHOICE
    case $DRIVER_CHOICE in
        1) DRIVER="docker" ;;
        2) DRIVER="virtualbox" ;;
        3) DRIVER="kvm2" ;;
        *) echo "Invalid choice, defaulting to docker"; DRIVER="docker" ;;
    esac

    if [ "$DRIVER" == "docker" ]; then
        if ! command -v docker >/dev/null 2>&1; then
            echo "Installing Docker..."
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y docker.io
                sudo systemctl enable --now docker
                sudo usermod -aG docker $USER
            elif [ "$OS" == "redhat" ]; then
                sudo yum install -y docker
                sudo systemctl enable --now docker
                sudo usermod -aG docker $USER
            fi
        fi
    elif [ "$DRIVER" == "virtualbox" ]; then
        if ! command -v VBoxManage >/dev/null 2>&1; then
            echo "Installing VirtualBox..."
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y virtualbox
            elif [ "$OS" == "redhat" ]; then
                sudo yum install -y virtualbox
            fi
        fi
    elif [ "$DRIVER" == "kvm2" ]; then
        if ! command -v virsh >/dev/null 2>&1; then
            echo "Installing KVM2 dependencies..."
            if [ "$OS" == "debian" ]; then
                sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
                sudo usermod -aG libvirt $USER
            elif [ "$OS" == "redhat" ]; then
                sudo yum install -y qemu-kvm libvirt libvirt-daemon libvirt-client virt-install virt-manager
                sudo usermod -aG libvirt $USER
            fi
        fi
    fi

    echo "Starting Minikube with driver: $DRIVER"
    minikube start --force $DRIVER

elif [ "$K8S_CHOICE" == "2" ]; then
    if [ "$ARCH" == "amd64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
    else
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
    fi
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    echo "Installing k3s..."
    curl -sfL https://get.k3s.io | sh -

else
    echo "Invalid choice"
    exit 1
fi

echo "===== Installation completed! ====="
echo "kubectl version: $(kubectl version --client --short)"
echo "If Minikube, run: minikube status"
echo "If k3s, run: sudo k3s kubectl get nodes"
