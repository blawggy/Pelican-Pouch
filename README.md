# Pelican.dev Installer

## Dependencies

- sudo
- curl

## Supported Systems:

| Operating System | Version | Supported | Notes |
|:----------------:|:-------:|:---------:|:------:|
| **Ubuntu**       | 20.04   | ⚠️︎       | **No SQLite Support**, Ubuntu 20.04 EoL is April 2025, not recommended |
|                  | 22.04   | ✅︎       |        |
|                  | **24.04** | ✅︎     | Documentation written assuming Ubuntu 24.04 as the base OS. |
| **Rocky Linux**  | 9       | ✅︎       |        |
| **Debian**       | 11      | ⚠️       | **No SQLite Support** |
|                  | 12      | ✅︎       |        |

## Install Script

```bash
bash <(curl -s https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/Pelican_Installer.sh)
```
