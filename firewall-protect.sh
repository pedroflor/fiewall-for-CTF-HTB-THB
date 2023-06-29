#!/bin/bash
## Modified by: Pedro Flor
# Assing IPv4 from argument to a global variable
ipv4=$1

## Validate IPv4 address
# Source: https://www.linuxjournal.com/content/validating-ip-address-bash-script
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
    then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


## Author: Nisrin Ahmed aka Wh1teDrvg0n
function do_firewall() {
  echo "Appliying firewall rules on \"tun0\" to protect you from adversaries ;)"

  # IPv4 flush
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -t nat -F
  iptables -t mangle -F
  iptables -F
  iptables -X
  iptables -Z

  # IPv6 flush
  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT DROP
  ip6tables -t nat -F
  ip6tables -t mangle -F
  ip6tables -F
  ip6tables -X
  ip6tables -Z

  # Ping machine
  iptables -A INPUT -p icmp -i tun0 -s $ipv4 --icmp-type echo-request -j ACCEPT
  iptables -A INPUT -p icmp -i tun0 -s $ipv4 --icmp-type echo-reply -j ACCEPT
  iptables -A INPUT -p icmp -i tun0 --icmp-type echo-request -j DROP  
  iptables -A INPUT -p icmp -i tun0 --icmp-type echo-reply -j DROP
  iptables -A OUTPUT -p icmp -o tun0 -d $ipv4 --icmp-type echo-reply -j ACCEPT
  iptables -A OUTPUT -p icmp -o tun0 -d $ipv4 --icmp-type echo-request -j ACCEPT
  iptables -A OUTPUT -p icmp -o tun0 --icmp-type echo-request -j DROP
  iptables -A OUTPUT -p icmp -o tun0 --icmp-type echo-reply -j DROP

  # Allow VPN connection only from machine
  iptables -A INPUT -i tun0 -p tcp -s $ipv4 -j ACCEPT
  iptables -A OUTPUT -o tun0 -p tcp -d $ipv4 -j ACCEPT
  iptables -A INPUT -i tun0 -p udp -s $ipv4 -j ACCEPT
  iptables -A OUTPUT -o tun0 -p udp -d $ipv4 -j ACCEPT
  iptables -A INPUT -i tun0 -j DROP
  iptables -A OUTPUT -o tun0 -j DROP
}


## Verify if tun0 exists
ifname_tun0=$(ip link | grep tun0 | cut -f2 -d":" | tr -d " ")
if [ -z $ifname_tun0 ] || [ $ifname_tun0 != "tun0" ]
then
  echo "Error: \"tun0\" doesn't exist"
  exit
fi

## Verify if root
if [ $(id -u) != 0 ]
then
  echo "Error: Scrip needs root to run!!!"
  exit
fi

## Verify arguments (IPv4)
if [ $# -eq 1 ]
then
  echo -n ""
else
  echo "Error: Must specify an IPv4 address"
  exit
fi

## Verify IPv4 sintax
ipv4=$1
valid_ip $ipv4
if [ $? != 0 ]
then
  echo "Error: Must provide a valid IPv4"
  exit
fi

# All validations passed. Procceed to apply firewall
do_firewall
