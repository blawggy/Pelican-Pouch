# Pelican Pouch

# An all-in-one Script for Pelican Panel 

## Dependencies

- Sudo
- Curl

## Supported Systems:

| Operating System |  Version  | Supported |                                 Notes                                  |
| :--------------: | :-------: | :-------: | :--------------------------------------------------------------------: |
|    **Ubuntu**    |   20.04   |    ⚠️︎    | **No SQLite Support**, Ubuntu 20.04 EoL is April 2025, not recommended |
|                  |   22.04   |    ⚠️     |                                                                        |
|                  | **24.04** |    ⚠️    |      Some parts require manual setup. look after official documentation       |
| **Rocky Linux**  |     9     |    ✅︎     |                                                                        |
|    **Debian**    |    11     |    ⚠️     |                         **No SQLite Support**                          |
|                  |    12     |    ✅     |       Documentation written assuming Debian 12 as the base OS        |

## Before running script
> [!IMPORTANT] 
> It is important that you have both Curl AND Sudo installed before running this script, as curl is needed to run the script and most sections use sudo

## Pelican Pouch Script

```bash
bash <(curl -s https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/Pelican_Pouch.sh)
```

### Without greeting

```bash
bash <(curl -s https://raw.githubusercontent.com/blawggy/Pelican-Dev-Installer/main/Pelican_Pouch.sh) --skip-welcome
```

## Post Panel install

After running the install, just click next all the way to the end. **NO COMMANDS NEEDED**

You Should be able to access the panel with the credentials

Now you just need to configure the Node

# Done
