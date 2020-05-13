#!/bin/bash

# Welcome the user. Warn them about the password prompts.
echo "Welcome to the certificate update script. This script will not make any permanent"
echo "changes to the system and will be working in a brand new folder."
echo ""
echo "The script will provide somewhat detailed error messages if it runs into any issues,"
echo "and will prompt 3 times for a password. Once to set the password for the JKS file,"
echo "again to confirm the same password, and finally to allow changing the alias name"
echo "in the JKS file."
echo ""
read -n 1 -s -r -p "Press any key to continue."

# Set variable $dir to be unique folder based on today's date.
dir=certificate_$(date +%Y%m%d)

# Check for pre-existence of unique folder. If none, then create.
if [[ -d "$dir" ]]; then
	echo ""
	echo "Unique directory found. Have you already run this script?"
	echo "Would you like to:"
	echo "1. Delete the folder and continue?"
	read -n1 -p "2. Cancel the operation? " continue
	case $continue in
		[1]*)
			echo ""
			echo "Continuing..."
			rm -rf $dir
			mkdir $dir
			;;
		[2]*)
			echo ""
			echo "Exiting cleanly..."
			exit 1
			;;
		*)
			echo ""
			echo "Please answer only 1 or 2." >&2
			echo ""
	esac
else
	echo ""
	mkdir $dir
fi

#if [ $continue = 1 ]; then
#elif [ $continue = 2 ]; then
#fi

# Copy the existing private key and intermediate into the new folder.
cp star_carters_com.key $dir/
cp DigiCertCA.crt $dir/

# Check the certificate file; if less than 1 day old, copy the new certificate into the new folder.
if test -f star_carters_com.crt; then
        if test "`find . -maxdepth 1 -mtime -1 -name star_carters_com.crt`"; then
                cp star_carters_com.crt $dir/
        else
	        echo "Certificate file found, but file is too old to be this year's renewal."
       		exit 1
        fi
else
	echo "Certificate file not found. Looking for 'star_carters_com.crt'."
	exit 1
fi

# Change directories to the new one; then combine the private key, new certificate, and intermediate into a PKCS#12 bundle.
cd $dir/
openssl pkcs12 -export -out MANH_WM2017.jks -inkey star_carters_com.key -in star_carters_com.crt -certfile DigiCertCA.crt

# Change the alias of the privateKeyEntry in the JKS from "1" to "carters.com":
keytool -changealias -alias 1 -destalias carters.com -keystore MANH_WM2017.jks

# Processed finished; show reminder to confirm.
echo "You should verify that the JKS is structured correctly, with alias=carters.com showing as type=privateKeyEntry and Owner CN=*.carters.com"
echo "Run 'keytool -list -v -keystore $dir/MANH_WM2017.jks' to confirm."
