#!/bin/bash

# Load config
config_file="config.yaml"
environment=$(grep 'environment:' $config_file | awk '{print $2}')

# Check memory
check_memory() {
  total_mem=$(free -m | awk '/^Mem:/{print $2}')
  if [ $total_mem -lt 4000 ]; then
    echo "Warning: This machine has less than 4GB RAM. It may not be sufficient to run the setup."
    exit 1
  fi
}

# Install dependencies
install_dependencies() {
  echo "Installing dependencies for $1..."
  
  case $1 in
    Ubuntu)
      sudo apt update
      sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
      ;;
    CentOS) 
      sudo yum install -y yum-utils device-mapper-persistent-data lvm2
      ;;
    *)
      echo "Unsupported OS"
      exit 1
      ;;
  esac

  # Install latest Docker
  install_docker $1

  # Install latest Kubernetes
  install_kubernetes $1

  # Install latest Terraform
  install_terraform

  # Install Helm
  install_helm
}

install_docker() {
  echo "Installing latest Docker..."
  case $1 in
    Ubuntu)
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      sudo apt update
      sudo apt install -y docker-ce docker-ce-cli containerd.io
      ;;
    CentOS)
      sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      sudo yum install -y docker-ce docker-ce-cli containerd.io
      ;;
  esac
  sudo systemctl start docker
  sudo systemctl enable docker
}

install_kubernetes() {
  echo "Installing latest Kubernetes..."
  case $1 in
    Ubuntu)
      curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
      echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
      sudo apt update
      sudo apt install -y kubelet kubeadm kubectl
      sudo apt-mark hold kubelet kubeadm kubectl
      ;;
    CentOS)
      cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
      sudo setenforce 0
      sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
      sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
      sudo systemctl enable --now kubelet
      ;;
  esac
}

install_terraform() {
  echo "Installing latest Terraform..."
  LATEST_URL=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url' | grep 'linux.*amd64' | sort -V | tail -n 1)
  curl -o terraform.zip "${LATEST_URL}"
  unzip terraform.zip
  sudo mv terraform /usr/local/bin/
  rm terraform.zip
}

install_helm() {
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  if [ $? -ne 0 ]; then
    echo "Helm installation failed. Trying alternative method..."
    HELM_VERSION=$(curl -s https://github.com/helm/helm/releases | grep 'tag-name' | grep -v no-underline | head -n 1 | cut -d '"' -f 2 | sed 's/v//g')
    wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
    tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm-v${HELM_VERSION}-linux-amd64.tar.gz
  fi
}

# Setup Kubernetes single-node
setup_kubernetes_single_node() {
  echo "Setting up Kubernetes single-node..."
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
  # Allow scheduling on the control-plane node
  kubectl taint nodes --all node-role.kubernetes.io/master-
  
  # Install network plugin (Flannel)
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

# Setup CI/CD
setup_cicd() {
  echo "Setting up Jenkins..."
  if [[ "$OS" == "Ubuntu" ]]; then
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install -y jenkins
  elif [[ "$OS" == "CentOS" ]]; then
    sudo yum install -y epel-release
    sudo yum install -y jenkins
  fi
}

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
elif type lsb_release >/dev/null 2>&1; then
  OS=$(lsb_release -si)
elif [ -f /etc/lsb-release ]; then
  . /etc/lsb-release
  OS=$DISTRIB_ID
else
  OS=$(uname -s)
fi

# Main
check_memory
install_dependencies $OS
setup_kubernetes_single_node
setup_cicd

echo "Setup complete for $environment environment"