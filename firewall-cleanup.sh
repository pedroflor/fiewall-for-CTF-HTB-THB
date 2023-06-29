#!/bin/bash

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