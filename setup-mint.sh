#!/usr/bin/env bash
# setup-mint.sh · Entorno Data + AI Engineer (Linux Mint 22 / Ubuntu 24.04)
# Idempotente: se puede ejecutar varias veces sin efectos secundarios.
set -euo pipefail

CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
KEYS=/etc/apt/keyrings

# add_repo NOMBRE URL_CLAVE URL_REPO SUITE COMPONENTE
add_repo() {
  curl -fsSL "$2" | sudo gpg --dearmor --yes -o "$KEYS/$1.gpg"
  sudo tee "/etc/apt/sources.list.d/$1.sources" >/dev/null <<EOF
Types: deb
URIs: $3
Suites: $4
Components: $5
Architectures: amd64
Signed-By: $KEYS/$1.gpg
EOF
}

echo "==> 1. Sistema y herramientas base"
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl make build-essential unzip ca-certificates gpg
sudo install -m 0755 -d "$KEYS"

echo "==> 2. Repositorios oficiales (base Ubuntu: $CODENAME)"
add_repo docker    https://download.docker.com/linux/ubuntu/gpg \
                   https://download.docker.com/linux/ubuntu "$CODENAME" stable
add_repo hashicorp https://apt.releases.hashicorp.com/gpg \
                   https://apt.releases.hashicorp.com "$CODENAME" main
add_repo azure-cli https://packages.microsoft.com/keys/microsoft.asc \
                   https://packages.microsoft.com/repos/azure-cli/ "$CODENAME" main
if ! dpkg -s code >/dev/null 2>&1; then
  add_repo vscode  https://packages.microsoft.com/keys/microsoft.asc \
                   https://packages.microsoft.com/repos/code stable main
fi
sudo apt update

echo "==> 3. Docker CE, Terraform, Azure CLI y VS Code"
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin terraform azure-cli code
sudo systemctl enable --now docker
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  NECESITA_REINICIO=1
fi

echo "==> 4. uv + Python 3.12"
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
uv python install 3.12

echo "==> 5. DBeaver Community (Flatpak)"
sudo flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub io.dbeaver.DBeaverCommunity

echo "==> 6. Databricks CLI"
if ! command -v databricks >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh
fi

echo "==> Listo."
if [ "${NECESITA_REINICIO:-0}" = 1 ]; then
  echo "Reinicia el equipo para usar Docker sin sudo."
fi