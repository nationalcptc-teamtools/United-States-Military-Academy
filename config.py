#!/usr/bin/env python3
import json
import ipaddress
import argparse
import re
from pathlib import Path
#The purpose of this file is to provide a wizard for the user to configure the program
#The configuration file is stored in the same directory as the program and is called config.json
#Additionally, this file provides a function to read the configuration file and return the values that other files can use

#Stored in the config.json file:
# ranges: a list of ranges to scan in CIDR notation
# hosts: explicit IP hosts/hostnames; this helper performs no discovery or DNS.

def config_ranges(values):
    if not isinstance(values, list) or len(values) > 4096:
        raise ValueError("ranges must be a bounded list")
    networks = []
    for value in values:
        if not isinstance(value, str) or not value or any(c.isspace() for c in value):
            raise ValueError("invalid IP/CIDR range")
        try:
            network = ipaddress.ip_network(value, strict=True)
        except ValueError:
            raise ValueError("invalid IP/CIDR range; host bits must be zero") from None
        if network.prefixlen == 0:
            raise ValueError("default-route scope is not allowed")
        networks.append(network)
    return networks


def config_hosts(values, networks):
    if not isinstance(values, list) or len(values) > 4096:
        raise ValueError("hosts must be a bounded list")
    for value in values:
        if not isinstance(value, str) or not 0 < len(value) <= 253 or '%' in value:
            raise ValueError("invalid host")
        try:
            address = ipaddress.ip_address(value)
        except ValueError:
            labels = (value[:-1] if value.endswith('.') else value).split('.')
            if (not all(re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", label) for label in labels)
                    or not re.search(r"[A-Za-z]", labels[-1])
                    or any(re.fullmatch(r"0[xX][0-9A-Fa-f]+", label) for label in labels)):
                raise ValueError("invalid IP or hostname") from None
        else:
            if networks and not any(address.version == n.version and address in n for n in networks):
                raise ValueError("literal host is outside the supplied ranges")


def validate_config(config):
    if not isinstance(config, dict) or set(config) != {"ranges", "hosts"}:
        raise ValueError("configuration requires ranges and hosts only")
    networks = config_ranges(config["ranges"])
    config_hosts(config["hosts"], networks)
    return config


def prompt_config():
    print("Gathering configuration information for the CPTC scripts")
    print("Enter authorized IP/CIDR ranges separated by commas. Hostnames are not resolved here.")
    while True:
        raw = input("Ranges: ")
        ranges = [value.strip() for value in raw.split(',')] if raw.strip() else []
        try:
            networks = config_ranges(ranges)
            break
        except ValueError as error:
            print("Invalid ranges: " + str(error))
    print("Enter explicit IP hosts or hostnames separated by commas; leave blank if unknown.")
    while True:
        raw = input("Hosts: ")
        hosts = [value.strip() for value in raw.split(',')] if raw.strip() else []
        try:
            config_hosts(hosts, networks)
            return {"ranges": ranges, "hosts": hosts}
        except ValueError as error:
            print("Invalid hosts: " + str(error))


def write_config(config):
    validate_config(config)
    #prompt for config save location
    input_location = input("Where would you like to save your config file? [default/recommended: ./config.json]")
    if input_location == "":
        input_location = "./config.json"
    #write the config file
    with Path(input_location).expanduser().open("w", encoding="utf-8") as f:
        json.dump(config, f)
def read_config(filename="./config.json"):
    # Default lookup can fall back to home; an explicit missing path fails closed.
    try:
        with Path(filename).expanduser().open("r") as f:
            config = json.load(f)
            return validate_config(config)
    except FileNotFoundError:
        # Missing explicitly selected scope must not use an unrelated fallback.
        if Path(filename) != Path("config.json"):
            raise
        try:
            with Path("~/.config.json").expanduser().open("r") as f:
                config = json.load(f)
                return validate_config(config)
        except FileNotFoundError:
            print("No config file found, creating one")
            config = prompt_config()
            write_config(config)
            return validate_config(config)
if __name__ == "__main__":
    args = argparse.ArgumentParser(
        prog = "config.py",
        description="Configure the CPTC scripts via user prompt",
        usage="config.py"
        )
    args.parse_args()
    config = prompt_config()
    print(config)
    write_config(config)
    print("CPTC scripts configured successfully!")
