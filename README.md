# MTProxy Installer (telemt)
# Debian 12

> **Legal Notice**
> This repository and scripts are provided strictly for educational, research, and lawful system administration purposes. 
> The author does not promote, encourage, or support bypassing any legal restrictions or regulations.
> By using these materials, you agree that you are solely responsible for ensuring compliance with all applicable laws and regulations in your jurisdiction.
> The author assumes no liability for any misuse, legal violations, or consequences arising from the use of this software.

### The script builds Docker images from source: https://github.com/telemt/telemt

### Full example
`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer2/refs/heads/main/install2.sh) --port=443 --ip=203.0.113.10 --domain=google.com --user=user`

### Minimal example
`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer2/refs/heads/main/install2.sh) --port=443`

### Help
`bash <(wget -qO- https://raw.githubusercontent.com/prjctz/installer2/refs/heads/main/install2.sh) --help`

Tested and working. Everything deploys correctly and restarts automatically after reboot.

Provides 3 proxy modes (all functional):
1. standard
2. secure
3. fake TLS

### Recommended port: 8443

### Statistics, user management with connection limits are included — commands are displayed after installation

### Automated installer:
https://github.com/prjctz/tapok/

### Other options:
- https://github.com/prjctz/installer1/
- https://github.com/prjctz/installer3/
- https://github.com/prjctz/installer4/
