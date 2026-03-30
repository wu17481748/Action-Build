#!/bin/bash
FILE=$1

[ -f "$FILE" ] || {
	echo "Provide a config file as argument"
	
	exit
}

write=false

if [ "$2" = "-w" ]; then
	write=true
fi

CONFIGS_ON="

# Kernel configurations for full DroidSpaces support
# Copyright (C) 2026 ravindu644 <droidcasts@protonmail.com>

# IPC mechanisms (required for tools that rely on shared memory and IPC namespaces)
CONFIG_SYSCTL
CONFIG_SYSVIPC
CONFIG_POSIX_MQUEUE

# Core namespace support (essential for isolation and running init systems)
CONFIG_NAMESPACES
CONFIG_PID_NS
CONFIG_UTS_NS
CONFIG_IPC_NS

# Seccomp support (enables syscall filtering and security hardening)
CONFIG_SECCOMP
CONFIG_SECCOMP_FILTER

# Control groups support (required for systemd and resource accounting)
CONFIG_CGROUPS
CONFIG_CGROUP_DEVICE
CONFIG_CGROUP_PIDS
CONFIG_MEMCG
CONFIG_CGROUP_SCHED
CONFIG_FAIR_GROUP_SCHED
CONFIG_CGROUP_FREEZER
CONFIG_CGROUP_NET_PRIO

# Device filesystem support (enables hardware access when --hw-access is enabled)
CONFIG_DEVTMPFS

# Overlay filesystem support (required for volatile mode)
CONFIG_OVERLAY_FS

# Firmware loading support (optional, used when --hw-access is enabled)
CONFIG_FW_LOADER
CONFIG_FW_LOADER_USER_HELPER
CONFIG_FW_LOADER_COMPRESS

# Droidspaces Network Isolation Support - NAT/none modes
# Network namespace isolation
CONFIG_NET_NS

# Virtual ethernet pairs
CONFIG_VETH

# Bridge device
CONFIG_BRIDGE

# Netfilter core
CONFIG_NETFILTER
CONFIG_BRIDGE_NETFILTER
CONFIG_NETFILTER_ADVANCED

# Connection tracking
CONFIG_NF_CONNTRACK
# kernels ≤ 4.18 (Android 4.4 / 4.9)
CONFIG_NF_CONNTRACK_IPV4

# iptables infrastructure
CONFIG_IP_NF_IPTABLES

# filter table
CONFIG_IP_NF_FILTER

# NAT table
CONFIG_NF_NAT

# NF Tables
CONFIG_NF_TABLES

# kernels ≤ 5.0 (Kernel 4.4 / 4.9)
CONFIG_NF_NAT_IPV4
CONFIG_IP_NF_NAT

# MASQUERADE target (renamed in 5.2)
CONFIG_IP_NF_TARGET_MASQUERADE
CONFIG_NETFILTER_XT_TARGET_MASQUERADE

# MSS clamping
CONFIG_NETFILTER_XT_TARGET_TCPMSS

# addrtype match (required for --dst-type LOCAL DNAT port forwarding)
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE

# Conntrack netlink + NAT redirect (required for stateful NAT)
CONFIG_NF_CONNTRACK_NETLINK
CONFIG_NF_NAT_REDIRECT

# Policy routing
CONFIG_IP_ADVANCED_ROUTER
CONFIG_IP_MULTIPLE_TABLES


# UFW CORE
CONFIG_NETFILTER_XT_MATCH_COMMENT
CONFIG_NETFILTER_XT_MATCH_STATE
CONFIG_NETFILTER_XT_MATCH_CONNTRACK
CONFIG_NETFILTER_XT_MATCH_MULTIPORT
CONFIG_NETFILTER_XT_MATCH_HL
CONFIG_NETFILTER_XT_TARGET_REJECT
CONFIG_IP_NF_TARGET_REJECT
CONFIG_NETFILTER_XT_TARGET_LOG
CONFIG_IP_NF_TARGET_ULOG

# FAIL2BAN CORE
CONFIG_NETFILTER_XT_MATCH_RECENT
CONFIG_NETFILTER_XT_MATCH_LIMIT
CONFIG_NETFILTER_XT_MATCH_HASHLIMIT
CONFIG_NETFILTER_XT_MATCH_OWNER
CONFIG_NETFILTER_XT_MATCH_PKTTYPE
CONFIG_NETFILTER_XT_MATCH_MARK
CONFIG_NETFILTER_XT_TARGET_MARK

# IPSET (efficient fail2ban banlists)
CONFIG_IP_SET
CONFIG_IP_SET_HASH_IP
CONFIG_IP_SET_HASH_NET
CONFIG_NETFILTER_XT_SET

# NFNETLINK / logging
CONFIG_NETFILTER_NETLINK_QUEUE
CONFIG_NETFILTER_NETLINK_LOG
CONFIG_NETFILTER_XT_TARGET_NFLOG

"

CONFIGS_OFF="
# Disable this on older kernels to make internet work
CONFIG_ANDROID_PARANOID_NETWORK
"
CONFIGS_EQ="
"

ered() {
	echo -e "\033[31m" $@
}

egreen() {
	echo -e "\033[32m" $@
}

ewhite() {
	echo -e "\033[37m" $@
}

echo -e "\n\nChecking config file for https://github.com/wu17481748/lxc-docker specific config options.\n\n"

errors=0
fixes=0

for c in $CONFIGS_ON $CONFIGS_OFF;do
	cnt=`grep -w -c $c $FILE`
	if [ $cnt -gt 1 ];then
		ered "$c appears more than once in the config file, fix this"
		errors=$((errors+1))
	fi

	if [ $cnt -eq 0 ];then
		if $write ; then
			ewhite "Creating $c"
			echo "# $c is not set" >> "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is neither enabled nor disabled in the config file"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_ON;do
	if grep "$c=y\|$c=m" "$FILE" >/dev/null;then
		egreen "$c is already set"
	else
		if $write ; then
			ewhite "Setting $c"
			sed  -i "s,# $c is not set,$c=y," "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is not set, set it"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_EQ;do
	lhs=$(awk -F= '{ print $1 }' <(echo $c))
	rhs=$(awk -F= '{ print $2 }' <(echo $c))
	if grep "^$c" "$FILE" >/dev/null;then
		egreen "$c is already set correctly."
		continue
	elif grep "^$lhs" "$FILE" >/dev/null;then
		cur=$(awk -F= '{ print $2 }' <(grep "$lhs" "$FILE"))
		ered "$lhs is set, but to $cur not $rhs."
		if $write ; then
			egreen "Setting $c correctly"
			sed -i 's,^'"$lhs"'.*,# '"$lhs"' was '"$cur"'\n'"$c"',' "$FILE"
			fixes=$((fixes+1))
		fi
	else
		if $write ; then
			ewhite "Setting $c"
			echo  "$c" >> "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is not set"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_OFF;do
	if grep "$c=y\|$c=m" "$FILE" >/dev/null;then
		if $write ; then
			ewhite "Unsetting $c"
			sed  -i "s,$c=.*,# $c is not set," $FILE
			fixes=$((fixes+1))
		else
			ered "$c is set, unset it"
			errors=$((errors+1))
		fi
	else
		egreen "$c is already unset"
	fi
done

if [ $errors -eq 0 ];then
	egreen "\n\nConfig file checked, found no errors.\n\n"
else
	ered "\n\nConfig file checked, found $errors errors that I did not fix.\n\n"
fi

if [ $fixes -gt 0 ];then
	egreen "开启docker-lxc配置 $fixes 项.\n\n"
fi

ewhite " "
