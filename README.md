# MobileIron CVE-2023-38035 Exploit README.md
## Description 
This bash script automates the process of scanning for vulnerable MobileIron systems that are susceptible to the CVE-2023-38035 exploit. The script performs multiple checks, including checking for required programs, downloading potential targets from Shodan, scanning these targets, and finally attempting to spawn a shell on a vulnerable system.

## Features
- Automated Shodan query to find vulnerable MobileIron Systems
- Extracts IP addresses for scanning
- Automated vulnerability assessment of targets
- Gives an option to execute reverse shell using different methods like ncat or multi_reverse.sh
- Checks for missing dependencies and recommends installation
- Beautiful banner to make the tool look cool 😎

## Requirements
The following programs/packages are required for this script to work:

- shodan: Shodan CLI tool and API Key
- jq: Lightweight and flexible command-line JSON processor
- python: Python3
- ngrok: To expose a local server behind a NAT or firewall to the Internet
- terminator: For managing multiple terminal windows

Ensure that you have properly configured Shodan and Ngrok.

## Installations steps
1. Clone this repository
```bash
git clone <repository-url>
```
2. Navigate to the repository
```bash
cd <project-directory>
```
3. Make the script executable
```bash
chmod +x mics_hunter.sh
```
4. Run the script
```bash
./mics_hunter.sh
```

## Usage
Just run the script, and it will perform all the tasks sequentially:
1. Check for required programs.
2. Download Shodan search results.
3. Scan the potential targets.
4. Allow you to select a target and method for reverse shell execution.

## External Dependencies
This script uses an external tool `hessian.py` to serialization of data. Make sure you have it in the same directory as this script.

## Credits for hessian.py
This script uses `hessian.py` which is a modified version of a script created by [horizon3ai](https://github.com/horizon3ai/CVE-2023-38035). 

## Disclaimer
This script is for educational purposes only. The use of this script for any malicious activities is prohibited.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
GPLv3

## Author
- mind2hex

Feel free to reach out to me if you have any questions or issues!