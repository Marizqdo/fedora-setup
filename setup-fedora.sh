#!/usr/bin/env bash
# setup-fedora.sh · Entorno Data + AI Engineer (Fedora 41+)
# Idempotente: se puede ejecutar varias veces sin efectos secundarios.
set -euo pipefail

echo "==> 1. Sistema y herramientas base"
sudo dnf upgrade --refresh -y
sudo dnf install -y git curl make gcc

echo "==> 2. Docker CE + Compose"
sudo dnf config-manager addrepo --overwrite \
  --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  NECESITA_REINICIO=1
fi

echo "==> 3. uv + Python 3.12"
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
uv python install 3.12

echo "==> 4. VS Code (repositorio oficial de Microsoft)"
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  printf '%s\n' "[code]" "name=Visual Studio Code" \
    "baseurl=https://packages.microsoft.com/yumrepos/vscode" \
    "enabled=1" "autorefresh=1" "type=rpm-md" "gpgcheck=1" \
    "gpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
    | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
fi
sudo dnf install -y code

echo "==> 5. DBeaver Community (Flatpak)"
sudo flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub io.dbeaver.DBeaverCommunity

echo "==> 6. Terraform"
sudo dnf config-manager addrepo --overwrite \
  --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf install -y terraform

echo "==> 7. Azure CLI"
sudo dnf install -y azure-cli

echo "==> 8. Databricks CLI"
if ! command -v databricks >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh
fi

echo "==> Listo."
if [ "${NECESITA_REINICIO:-0}" = 1 ]; then
  echo "Reinicia el equipo para usar Docker sin sudo."
fi