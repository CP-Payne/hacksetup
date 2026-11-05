#!/usr/bin/env bash
# =============================================================================
#  hacksetup — Kali bootstrap (i3 + tmux + tooling)
#
#  Usage:
#    ./setup.sh                 # run everything listed in main()
#    ./setup.sh mobile_tools    # run only one (or more) sections
#
#  Run as your normal user, not root (it uses sudo where needed).
#  Safe to re-run: installs skip/upgrade, git tools pull, dotfiles re-link.
#
#  ADDING A TOOL: find the right section below and add one line, e.g.
#    apt_install bloodhound
#    pipx_install git+https://github.com/someone/smbthing
#    go_install github.com/projectdiscovery/katana/cmd/katana
#    git_tool https://github.com/someone/repo
#  Then run just that section:  ./setup.sh network_tools
# =============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$HOME/tools"          # git-cloned tools live here
FAILED=()                    # anything that failed gets listed at the end

# ----------------------------------------------------------------- helpers ---
log() { printf '\n\e[1;34m[+] %s\e[0m\n' "$*"; }

apt_install() {
  # Try all at once (fast); if that fails, go one by one so a single bad
  # package name doesn't block the rest.
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" && return 0
  for p in "$@"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$p" || FAILED+=("apt: $p")
  done
}

pipx_install() {
  for p in "$@"; do
    pipx install "$p" || FAILED+=("pipx: $p")
  done
}

go_install() {
  for p in "$@"; do
    go install "${p}@latest" || FAILED+=("go: $p")
  done
}

git_tool() {
  # git_tool <url> [dir-name]
  local url="$1" name="${2:-$(basename "$1" .git)}"
  if [[ -d "$TOOLS/$name/.git" ]]; then
    git -C "$TOOLS/$name" pull --ff-only || FAILED+=("git pull: $name")
  else
    git clone --depth 1 "$url" "$TOOLS/$name" || FAILED+=("git clone: $name")
  fi
}

link() {
  # link <source-in-repo> <target> — backs up a real file before replacing it
  mkdir -p "$(dirname "$2")"
  if [[ -e "$2" && ! -L "$2" ]]; then mv "$2" "$2.bak.$(date +%s)"; fi
  ln -sfn "$1" "$2"
}

# ---------------------------------------------------------------- sections ---
base_system() {
  log "Updating system"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
  apt_install git curl wget unzip p7zip-full build-essential \
              python3-pip pipx golang-go default-jdk \
              net-tools dnsutils openvpn wireguard-tools
  mkdir -p "$TOOLS" "$HOME/.local/bin" "$HOME/engagements"
  pipx ensurepath >/dev/null 2>&1 || true
}

desktop() {
  log "Desktop: i3, rofi, kitty"
  apt_install i3 i3status rofi picom dunst feh kitty \
              xclip flameshot fonts-jetbrains-mono jq x11-xserver-utils
  # At the login screen, pick "i3" from the session menu.
}

shell_tools() {
  log "Shell tools"
  apt_install tmux fzf ripgrep fd-find bat tree htop vim
  # Debian names these fdfind/batcat — give them their normal names
  [[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
  [[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

  # PATH for pipx / go tools (Kali's default shell is zsh)
  local rc="$HOME/.zshrc"
  if ! grep -q '# hacksetup' "$rc" 2>/dev/null; then
    cat >> "$rc" <<'EOF'

# hacksetup
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
alias t='tmux attach || tmux new -s main'
EOF
  fi
}

dotfiles() {
  log "Linking dotfiles (edit them in $REPO, changes apply live)"
  link "$REPO/dotfiles/tmux.conf"  "$HOME/.tmux.conf"
  link "$REPO/dotfiles/i3/config"  "$HOME/.config/i3/config"
  link "$REPO/dotfiles/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  link "$REPO/dotfiles/xprofile"   "$HOME/.xprofile"
  for f in "$REPO"/bin/*; do
    chmod +x "$f"
    link "$f" "$HOME/.local/bin/$(basename "$f")"
  done
  # tmux reads its config once, at server start. A server that was already
  # running would otherwise keep the old prefix (Ctrl+B) until it was killed.
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
}

web_tools() {
  log "Web tools"
  apt_install burpsuite ffuf feroxbuster gobuster sqlmap nuclei \
              whatweb wfuzz seclists wordlists
  # burpsuite here is Community — see burp_pro() for Pro.
  [[ -f /usr/share/wordlists/rockyou.txt.gz ]] && sudo gunzip -kf /usr/share/wordlists/rockyou.txt.gz
}

network_tools() {
  log "Network / AD tools"
  apt_install nmap netexec impacket-scripts python3-impacket responder \
              smbclient smbmap enum4linux-ng evil-winrm \
              hashcat john hydra chisel socat rlwrap
  # Examples of non-apt installs — uncomment / add your own:
  # pipx_install git+https://github.com/fortra/impacket   # latest impacket
  # go_install github.com/projectdiscovery/katana/cmd/katana
  # git_tool https://github.com/carlospolop/PEASS-ng
}

mobile_tools() {
  log "Mobile tools"
  apt_install adb fastboot apktool jadx aapt zipalign apksigner
  pipx_install frida-tools objection
}

burp_pro() {
  # Optional: Burp Suite Pro via PortSwigger's Linux installer (unattended).
  # Installs to ~/BurpSuitePro. Licence is entered on first launch.
  log "Burp Suite Pro"
  local inst; inst="$(mktemp --suffix=.sh)"
  curl -fL -o "$inst" 'https://portswigger.net/burp/releases/download?product=pro&type=Linux' \
    && sh "$inst" -q || FAILED+=("burp pro installer")
  rm -f "$inst"
}

summary() {
  log "Done"
  if ((${#FAILED[@]})); then
    printf '\e[1;31m[!] These failed — check names/URLs:\e[0m\n'
    printf '    %s\n' "${FAILED[@]}"
  fi
  echo "Log out, pick 'i3' at the login screen. Super+Enter = terminal, 'eng <name>' = new engagement."
}

# -------------------------------------------------------------------- main ---
# Comment out anything you don't want on this machine.
main() {
  base_system
  desktop
  shell_tools
  dotfiles
  web_tools
  network_tools
  mobile_tools
  # burp_pro
  summary
}

if (($#)); then
  for section in "$@"; do "$section"; done
  summary
else
  main
fi
