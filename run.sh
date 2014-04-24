#!/bin/sh
set -o nounset
set -o errexit

# A function to generates random password, $1 is desired length.
random_chars() {
    tr -dc '[:alnum:]' < /dev/urandom | head -c $1
}

# Assumes eth0 is wan interface
external_ip() {
    ip -o -4 addr list eth 0 | awk '{print $4}' | cut -d/ if 1
}

chap_username=$(random_chars 40)
chap_password=$(random_chars 40)
ipsec_preshared_key=$(random_chars 40)
external_ipv4_address=$(external_ip)

if [ `id -u` != 0 ]; then
    echo "Script running user is not root. We will not get very far."
    echo "Quitting..."
    exit 125;
fi

# Set openswan install-time options
debconf-set-selections ./files/openswan.seed

# Get packages
apt-get install -y openswan xl2tpd

# Modify config files in files dir to contain random strings generated above
sed -i "s/__chap_username__/$chap_username/g" files/chap-secrets
sed -i "s/__chap_password__/$chap_password/g" files/chap-secrets
sed -i "s/__ipsec_preshared_key__/$ipsec_preshared_key/g" files/ipsec.secrets

# Replace external_ipv4_address in files/*
find files/ -type f | xargs sed -i "s/external_ipv4_address/$external_ipv4_address/g"

# Overwriting files means we don't need to change file permissions.
cat files/xl2tpd.conf > /etc/xl2tpd/xl2tpd.conf
cat files/ipsec.conf > /etc/ipsec.conf
cat files/options.xl2tpd > /etc/ppp/options.xl2tpd
cat files/chap-secrets > /etc/ppp/chap-secrets
cat files/ipsec.secrets > /etc/ipsec.secrets

# Add virtual network interface
echo "

auto eth0:1
iface eth0:1 inet static
    address 192.168.200.1
    netmask 255.255.255.0" >> /etc/network/interfaces

# Add masquerade target in nat table's postrouting chain for vpn virtual subnet
iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
apt-get install iptables-persistent

# Configure network arguments
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf

sysctl -p

service networking restart

# Make iptables rules persist
service xl2tpd restart
service ipsec restart

# ipsec verify uses lsof, which isn't installed in Debian by default.
apt-get install lsof

# Check it worked
ipsec verify

echo -e "\n\n"
echo "The values you need to setup your VPN are:"
echo "  server ip: " $external_ipv4_address
echo "  username:  " $chap_username
echo "  password:  " $chap_password
echo "  secret:    " $ipsec_preshared_key
