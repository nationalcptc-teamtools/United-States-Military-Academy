#!/usr/bin/env python3
import config
import argparse
import sys 
import subprocess
import time
import ipaddress
import json
import sys
import xml.etree.ElementTree as ET
if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        prog="super_nmap.py",
        description='''
            A wrapper for nmap that automatically converts the output to html and caches hosts in the config file for more scans
        ''',
        usage="Usage: super_nmap.py [options]",
    )
    argparser.add_argument("-C","--config", help="The config file to use", type=str, default="./config.json")
    argparser.add_argument("-s", "--scan-type", help="Scan type", type=str, choices=["ping", "port", "fast", "full","udp","custom","vulscan"], default="custom")
    argparser.add_argument("-H","--hosts-only", help="Only scan hosts, not ranges", action="store_true")
    argparser.add_argument("-o", "--output", help="Output directory", type=str, default=".")
    argparser.add_argument("-c","--custom-args", help="Custom arguments to pass to nmap", type=str, default="")
    argparser.parse_args()
    #load config

    args = argparser.parse_args()
    config = config.read_config(args.config)
    #parse arguments
    #get timestamp for script output
    timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
    output_file = f"{args.output}/nmap_scan_{timestamp}_{args.scan_type}.xml"
    #create output directory if it doesn't exist
    subprocess.run(["mkdir", "-p", args.output])
    #create output file name (xml)
    nmap_args = ["sudo","nmap", "-vv", "-oX", output_file, "-T4"]
    if args.scan_type == "ping":
        nmap_args.append("-sn")
    elif args.scan_type == "port":
        nmap_args.append("-p0-65535")
    elif args.scan_type == "full":
        if not args.hosts_only:
            print("WARNING: Enabling -H (hosts only) is suggested for this scan because it will take a long time to do a full scan on the full IP range", file=sys.stderr)
        nmap_args.append("-p0-65535")
        nmap_args.append("-sV")
        nmap_args.append("-O")
        nmap_args.append("--script=default,safe,smb-vuln-ms17-010,http-default-accounts,http-vuln-cve2013-0156,smb-enum*")
    elif args.scan_type == "udp":
        if not args.hosts_only:
            print("WARNING: Enabling -H (hosts only) is suggested for this scan because it will take a long time to do a UDP scan on a range", file=sys.stderr)
        nmap_args.append("-sU")
        nmap_args.append("-p0-65535")
    elif args.scan_type == "fast":
        nmap_args.append("-F")
    elif args.scan_type== "vulscan":
        if not args.hosts_only:
            print("WARNING: Enabling -H (hosts only) is suggested for this scan because it will take a long time to do a vuln scan on a range", file=sys.stderr)
        #check if vulscan/vulscan.nse exists
        try:
            with open("vulscan/vulscan.nse", "r") as f:
                pass
        except FileNotFoundError:
            print("ERROR: vulscan.nse not found. Please run ./install.sh to install vulscan", file=sys.stderr)
            sys.exit(1)
        nmap_args.append("--script=./vulscan/vulscan.nse")
        nmap_args.append("-A")
    nmap_args.append(args.custom_args)
    if args.hosts_only:
        for host in config["hosts"]:
            nmap_args.append(host)
    else:
        for network in config["ranges"]:
            nmap_args.append(network)
    print("FINAL COMMAND: {}".format(" ".join(nmap_args)))
    input("Press enter if everything looks good...")
    #run nmap, redirect the stdout and stdin to current terminal
    process = subprocess.Popen(nmap_args, stdout=sys.stdout, stderr=sys.stderr)
    process.wait()
    #read the xml file and parse for address tags to add to config
    tree = ET.parse(output_file)
    for host in tree.findall("host"):
        address = host.find("address")
        if address is not None:
            addr = address.get("addr")
            if addr is not None:
                #add it to the config file
                if addr not in config["hosts"]:
                    config["hosts"].append(addr)
                    #write the config file
                    with open(args.config, "w") as f:
                        json.dump(config, f)
    #turn xml into html using xsltproc
    subprocess.run(["xsltproc", output_file, "-o", output_file.replace(".xml", ".html")])
    #turn html into pdf using wkhtmltopdf
    subprocess.run(["wkhtmltopdf", "-n", output_file.replace(".xml", ".html"), output_file.replace(".xml", ".pdf")])


