#!/bin/bash
echo "1. SSL"
echo "2. S/MIME"
while true; do
	read -n1 -p "Select Certificate Type: " type
	case $type in
		[1]*)
			break
			;;
		[2]*)
			break
			;;
		*)
			echo ""
			echo "Please answer only 1 or 2." >&2
			echo ""
	esac
done
echo ""
if [ $type == 1 ]; then
	while true; do
		read -n1 -p "Do you have a CSR prepared? (Y/N) " csr
		case $csr in
			[yY]*)
				break
				;;
			[nN]*)
				break
				;;
			*)
				echo ""
				echo "Please answer only y or n." >&2
				echo ""
		esac
	done
	echo ""
fi
while true; do
	read -n1 -p "How many years? (1, 2, or 3) " years
	case $years in
		[1]*)
			life=365
			break
			;;
		[2]*)
			life=730
			break
			;;
		[3]*)
			life=1095
			break
			;;
		*)
			echo ""
			echo "Please answer only 1, 2, or 3." >&2
			echo ""
	esac
done
echo ""
while true; do
	read -n1 -p "Do you a PFX Generated? (Y/N) " pfx
	case $pfx in
		[yY]*)
			break
			;;
		[nN]*)
			break
			;;
		*)
			echo ""
			echo "Please answer only y or n." >&2
			echo ""
	esac
done
echo ""

if [ $type == 1 ]; then
	type=ssl
	cfg="ca -config ../intermediate/$type.cnf -batch -extensions server_cert -notext -md sha256 -passin pass:$(cat password) -days $life"
	if [ $csr == y ]; then
		read -p "Common Name: " cn
		read -p "Filename base: " file
		cd endpoints
		echo ""
        echo "Signing Certificate..."
		openssl ca $config -days $life -in $file.csr -out $file.crt 2>/dev/null
		if [ $pfx == y ]; then
			echo "Exporting PFX..."
			openssl pkcs12 -export -out $file.pfx -inkey $file.key -in $file.crt
		fi
		cd ../
	else
		read -p "Common Name: " cn
		read -p "Country: " c
		read -p "State: " st
		read -p "City/Locality: " l
		read -p "Organization Name: " o
		read -p "Organization Unit/Department (Optional): " ou
		scrubbedcn=$(echo $cn|sed -e 's/\./_/g' -e 's/\*/star/g')
		cd endpoints
		echo ""
		echo "Generating CSR and Private Key..."
		if [ $ou ]; then
                openssl req -new -newkey rsa:2048 -nodes -out "$scrubbedcn.csr" -keyout "$scrubbedcn.key" -subj "/C=$c/ST=$st/L=$l/O=$o/OU=$ou/CN=$cn"
        else
                openssl req -new -newkey rsa:2048 -nodes -out "$scrubbedcn.csr" -keyout "$scrubbedcn.key" -subj "/C=$c/ST=$st/L=$l/O=$o/CN=$cn"
        fi
        echo "Signing Certificate..."
		openssl $cfg -in "$scrubbedcn.csr" -out "$scrubbedcn.crt" 2>/dev/null
        if [ $pfx == y ]; then
			echo "Exporting PFX..."
			openssl pkcs12 -export -out "$scrubbedcn.pfx" -inkey "$scrubbedcn.key" -in "$scrubbedcn.crt"
		fi
	fi
	echo ""
	echo "Complete! Please find your new certificate files in 'endpoints/$scrubbedcn.*'"
elif [ $type == 2 ]; then
	type=smime
	cfg="ca -config ../intermediate/$type.cnf -batch -extensions usr_cert -notext -md sha256 -passin pass:$(cat password) -days $life" 
	read -p "Common Name: " cn
	read -p "Country: " c
	read -p "State: " st
	read -p "City/Locality: " l
	read -p "Organization Name: " o
	read -p "Organization Unit/Department (Optional): " ou
	read -p "Email Address: " email
	cd smime
	echo ""
	echo "Generating CSR and Private Key..."
	if [ $ou ]; then
                openssl req -batch -new -newkey rsa:2048 -nodes -out "$cn.csr" -keyout "$cn.key" -subj "/C=$c/ST=$st/L=$l/O=$o/OU=$ou/CN=$cn/emailAddress=$email"
        else
                openssl req -batch -new -newkey rsa:2048 -nodes -out "$cn.csr" -keyout "$cn.key" -subj "/C=$c/ST=$st/L=$l/O=$o/CN=$cn/emailAddress=$email"
        fi
        echo "Signing Certificate..."
		openssl $cfg -in "$cn.csr" -out "$cn.crt" 2>/dev/null
        if [ $pfx == y ]; then
            echo "Exporting PFX..."
			openssl pkcs12 -export -out "$cn.pfx" -inkey "$cn.key" -in "$cn.crt"
	fi
	cd ../
	echo ""
	echo "Complete! Please find your new certificate files in 'smime/$cn.*'"
fi