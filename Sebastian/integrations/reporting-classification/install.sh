#!/bin/bash
sudo apt update && sudo apt install -y xsltproc nmap git wkhtmltopdf python3-pip -y
if [ ! -d vulscan ]
then
    git clone https://github.com/scipag/vulscan vulscan
fi
#ask if the user wants to install the AWS prowler script
echo "Do you want to install the AWS prowler script? (y/n)"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    pip install prowler
    prowler -v
fi 
#