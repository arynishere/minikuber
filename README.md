# Kubernetes Installer Script - kidkube.sh

This repository contains a **comprehensive Bash script** (`kidkube.sh`) to automate the installation of a local Kubernetes environment on Linux systems. It supports multiple distributions, architectures, and popular Kubernetes tools.  

---

## Features

- Detects your **OS** (`Debian/Ubuntu` or `RedHat/CentOS`)  
- Detects your **architecture** (`amd64` or `arm64`)  
- Lets you choose **Kubernetes distribution**:  
  - **Minikube** (local cluster with multiple driver options)  
  - **k3s + Kind** (lightweight Kubernetes with containerized clusters)  
- Automatically installs **kubectl** if missing  
- Installs and configures **Minikube drivers**:  
  - Docker  
  - VirtualBox  
  - KVM2  
- Supports **Binary** and **Package (DEB/RPM)** installation for Minikube  
- Works on both `x86_64` and `ARM64` systems  
- Handles missing dependencies (`curl`, `sudo`, etc.)  

---

## Supported OS & Architecture

| OS       | Arch   | Minikube Installation | Drivers Supported |
|----------|--------|--------------------|-----------------|
| Debian   | amd64  | Binary / DEB       | Docker, VirtualBox, KVM2 |
| Debian   | arm64  | Binary / DEB       | Docker, VirtualBox, KVM2 |
| RedHat   | amd64  | Binary / RPM       | Docker, VirtualBox, KVM2 |
| RedHat   | arm64  | Binary / RPM       | Docker, VirtualBox, KVM2 |

---

## Usage

1. Clone this repository:

```bash
git clone https://github.com/arynishere/k8s-installer.git
cd k8s-installer
```
Make the script executable:

```
chmod +x kidkube.sh
```
Run the installer:
```
sudo ./kidkube.sh
```
Follow the prompts to:

Choose Kubernetes distribution (Minikube or k3s + Kind)

Choose Minikube installation type (Binary / Package)

Select Minikube driver (Docker / VirtualBox / KVM2)

After installation, verify:

For kubectl:

```
kubectl version --client --short
```
If Minikube:
```
minikube status
```
If k3s:
```
sudo k3s kubectl get nodes
```
