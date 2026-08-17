import os
import sys
import subprocess
import xml.etree.ElementTree as ET

if os.geteuid() != 0:
    print("ROOT_ACCESS_REQUIRED")
    sys.exit(1)

try:
    cmd = ["su", "-c", "cat /data/misc/wifi/WifiConfigStore.xml"]
    output = subprocess.check_output(cmd, text=True)
except:
    try:
        output = subprocess.check_output(["cat", "/data/misc/wifi/WifiConfigStore.xml"], text=True)
    except:
        print("CONFIG_FILE_NOT_ACCESSIBLE")
        sys.exit(1)

try:
    root = ET.fromstring(output)
except:
    print("XML_PARSE_ERROR")
    sys.exit(1)

networks = []
for conf in root.findall(".//WifiConfiguration"):
    ssid_elem = conf.find("SSID")
    psk_elem = conf.find("PreSharedKey")
    if ssid_elem is not None and psk_elem is not None:
        ssid = ssid_elem.text.strip('"')
        psk = psk_elem.text
        if psk and psk != "*" and psk != "null":
            networks.append((ssid, psk))

if not networks:
    print("NO_SAVED_NETWORKS")
    sys.exit(1)

print("=== SAVED WIFI NETWORKS ===")
for idx, (ssid, _) in enumerate(networks, 1):
    print(f"{idx}. {ssid}")

try:
    choice = int(input("SELECT_NUMBER: ")) - 1
    if 0 <= choice < len(networks):
        print(f"PASSWORD: {networks[choice][1]}")
    else:
        print("INVALID_SELECTION")
except:
    print("INPUT_ERROR")
