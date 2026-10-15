#!/usr/bin/env python3
import json
import ipaddress
import argparse
#The purpose of this file is to provide a wizard for the user to configure the program
#The configuration file is stored in the same directory as the program and is called config.json
#Additionally, this file provides a function to read the configuration file and return the values that other files can use

#Stored in the config.json file:
# ranges: a list of ranges to scan in CIDR notation
# hosts: a list of hosts detected by the nmap scan.

def prompt_config():
    print("Gathering configuration information for the CPTC scripts")
    print("Please enter the ranges you wish to scan in CIDR notation, separated by commas. [192.168.1.0/24]")
    ranges = input("Ranges: ")
    if ranges == "":
        ranges = []
    else:
        ranges = ranges.split(",")
        #strip whitespace
        for i in range(len(ranges)):
            ranges[i] = ranges[i].strip()
    print("Please enter the hosts you wish to scan, separated by commas. If you don\'t know, don't worry leave it blank, it will be populated by the scans [192.168.1.1, host1.kkms.us, etc]")
    while True:
        hosts = input("Hosts: ")
        error = False
        if hosts == "":
            hosts = []
        else:
            hosts = hosts.split(",")
            #strip whitespace
            for i in range(len(hosts)):
                hosts[i] = hosts[i].strip()
                #check that the host is a valid IP address in the CIDR range in ANY of the ranges
                try:
                    ipaddress.ip_address(hosts[i])
                    in_range = False
                    for r in ranges:
                        if ipaddress.ip_address(hosts[i]) in ipaddress.ip_network(r):
                            in_range = True
                            break
                    if not in_range:
                        print("Host {} is not in any of the ranges specified. Please try again.".format(hosts[i]))
                        error = True
                except ValueError:
                    #don't worry about it, it's probably a hostname
                    continue
        if not error:
            break
    config = {"ranges": ranges, "hosts": hosts}
    return config
def write_config(config):
    #prompt for config save location
    input_location = input("Where would you like to save your config file? [default/recommended: ./config.json]")
    if input_location == "":
        input_location = "./config.json"
    #write the config file
    with open(input_location, "w") as f:
        json.dump(config, f)
def read_config(filename="./config.json"):
    #check in ./config.json for a config file, then ~/.config.json. If neither exist, create one
    try:
        with open(filename, "r") as f:
            config = json.load(f)
            return config
    except FileNotFoundError:
        try:
            with open("~/.config.json", "r") as f:
                config = json.load(f)
                return config
        except FileNotFoundError:
            print("No config file found, creating one")
            config = prompt_config()
            write_config(config)
            return config
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