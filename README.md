# Pelican Pouch

An all-in-one installation script for [Pelican Panel](https://pelican.dev) - the modern game server management panel.

## Quick Start

```bash
bash <(curl -sL https://pouch.zptc.cc)
```

### Skip Welcome Screen

```bash
bash <(curl -s https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/Pelican_Pouch.sh) --skip-welcome
```

## Prerequisites

Before running the installation script, ensure your system has:

- **Sudo** - Required for system-level operations
- **Curl** - Required to download and run the script

## Supported Operating Systems

| Operating System | Version | Support Status | Notes |
|------------------|---------|----------------|-------|
| **Debian** | 12 | ✅ Fully Supported | Recommended - Documentation base OS |
| | 11 | ⚠️ Partial | No SQLite support |
| **Ubuntu** | 24.04 LTS | ⚠️ Partial | Some manual configuration required |
| | 22.04 LTS | ⚠️ Partial | |
| | 20.04 LTS | ❌ Not Recommended | No SQLite support, EOL April 2025 |
| **Rocky Linux** | 9 | ✅ Fully Supported | |

## Installation Steps

### 1. Prepare Your System

Ensure curl and sudo are installed:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y curl sudo

# Rocky Linux
sudo dnf install -y curl sudo
```

### 2. Run the Installation Script

Execute the Pelican Pouch installer:

```bash
bash <(curl -sL https://pouch.zptc.cc)
```

The script will guide you through the installation process with an interactive menu.

### 3. Complete Panel Setup

After the installation completes:

1. Access your panel in a web browser using the URL provided
2. Complete the initial setup wizard by clicking "Next" through each step
3. Log in with the administrator credentials displayed after installation

### 4. Configure Your First Node

Follow the on-screen instructions to add and configure your first Wings node.

## What Gets Installed?

Pelican Pouch automatically installs and configures:

- **Pelican Panel** - Web interface for server management
- **Dependencies** - PHP, Composer, Node.js, and required extensions
- **Web Server** - Nginx or Apache (your choice)
- **Database** - MariaDB or PostgreSQL (your choice)
- **SSL Certificate** - Optional Let's Encrypt integration
- **Wings** - Optional game server daemon installation

## Troubleshooting

If you encounter issues during installation:

1. Verify your operating system is supported
2. Ensure you have a fresh system with minimal modifications
3. Check that ports 80 and 443 are available
4. Review the [official Pelican documentation](https://pelican.dev/docs)

## Need Help?

- 📚 [Official Documentation](https://pelican.dev/docs)
- 💬 [Discord Community](https://discord.gg/pelican-panel)
- 🐛 [Report Issues](https://github.com/blawggy/Pelican-Pouch/issues)

## License

This project is open source. Pelican Panel is licensed under the MIT License.