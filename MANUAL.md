# Manual Installation

These tools require manual installation steps.

## nvm (Node Version Manager)

Install via:
[https://nodejs.org/en/download](https://nodejs.org/en/download)

## Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Plugins

**zsh-autosuggestions:**
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

**zsh-syntax-highlighting:**
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Dracula Pro Theme

Copy the theme file to `~/.oh-my-zsh/themes/dracula-pro.zsh-theme`

[Dracula Pro](https://draculatheme.com/pro)

## 1Password with SSH Agent

1. Install 1Password for Linux (see the download link below)
2. Enable SSH Agent in Settings > Developer > SSH Agent
3. The agent socket is configured at `~/.1password/agent.sock`

[SSH Agent setup guide](https://developer.1password.com/docs/ssh/get-started/)

## JetBrains Toolbox

Download and install from:
[https://www.jetbrains.com/toolbox-app/](https://www.jetbrains.com/toolbox-app/)

```bash
# Extract and run
tar -xzf jetbrains-toolbox-*.tar.gz
./jetbrains-toolbox-*/jetbrains-toolbox
```

Installed JetBrains plugins are exported as reference lists in `packages/jetbrains-plugins/`.
Restore them manually in the matching current IDE version.

## Valet Linux

Requires Composer to be installed first.

```bash
composer global require cpriego/valet-linux
valet install
```

[Valet Linux repository](https://github.com/cpriego/valet-linux)

## Spatie Ray

Download from [spatie.be](https://spatie.be/)

## Tinkerwell

Download from [beyondco.de](https://beyondco.de/)

## Navicat

Download from [customer.navicat.com](https://customer.navicat.com/)

## Obsidian

Download deb from [obsidian.md/download](https://obsidian.md/download)

## 1password

Download deb from [1password.com/downloads/linux](https://1password.com/downloads/linux)

## Slack

Download deb from [slack.com/downloads/linux](https://slack.com/downloads/linux)
