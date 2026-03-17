#!/bin/bash
set -e

echo "=== Installing nerd fonts ==="
mkdir -p ~/.local/share/fonts
cd /tmp
for font in Hack Meslo NerdFontsSymbolsOnly; do
  curl -fLo "nerd-fonts-${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  unzip -o "nerd-fonts-${font}.zip" -d ~/.local/share/fonts
  rm "nerd-fonts-${font}.zip"
done
fc-cache -f -v

echo "=== Installing system packages via apt ==="
sudo apt update
sudo apt install -y playerctl steam-devices

echo "=== Installing gcloud CLI ==="
if ! command -v gcloud &> /dev/null; then
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
  echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt update && sudo apt install -y google-cloud-cli
fi

echo "=== Running brew bundle ==="
brew bundle --file=Brewfile_linux

echo "=== Installing Flatpak apps ==="
flatpak install -y flathub \
  com.google.AndroidStudio \
  com.bitwarden.desktop \
  com.brave.Browser \
  com.usebruno.Bruno \
  io.dbeaver.DBeaverCommunity \
  com.discordapp.Discord \
  com.google.Chrome \
  rest.insomnia.Insomnia \
  dev.lapce.lapce \
  net.mullvad.MullvadBrowser \
  md.obsidian.Obsidian \
  com.getpostman.Postman \
  one.flipperzero.qFlipper \
  org.signal.Signal \
  com.spotify.Client \
  com.valvesoftware.Steam \
  com.sublimetext.three \
  org.telegram.desktop \
  com.todoist.Todoist \
  org.videolan.VLC \
  com.vscodium.codium \
  org.wezfurlong.wezterm \
  dev.zed.Zed \
  org.bitcoincore.bitcoin-qt \
  com.usebottles.bottles

echo "=== Setup complete ==="
