#!/bin/bash
#
# MOTD for my build server
#
# Copyright (C) 2017 Nathan Chancellor
#
# CPU and memory usage functions taken from Screenfetch
# Copyright (c) 2010-2016 Brett Bohnenkamper <kittykatt@kittykatt.us>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>


function memUsage() {
	mem_info=$(</proc/meminfo)
	mem_info=$(echo $(echo $(mem_info=${mem_info// /}; echo ${mem_info//kB/})))
	for m in $mem_info; do
		case ${m//:*} in
			"MemTotal") memused=$((memused+=${m//*:})); memtotal=${m//*:} ;;
			"ShMem") memused=$((memused+=${m//*:})) ;;
			"MemFree"|"Buffers"|"Cached"|"SReclaimable") memused=$((memused-=${m//*:})) ;;
		esac
	done
	memused=$((memused / 1024))
	memtotal=$((memtotal / 1024))
    percent=$(echo $(echo "scale = 2; ($memused / $memtotal)" | bc -l | awk -F '.' '{print $2}'))

	echo "${memused} MB out of ${memtotal} MB" "(${percent}%)"
}

function cpu() {
	CPU=$( awk 'BEGIN{FS=":"} /model name/ { print $2; exit }' /proc/cpuinfo | awk 'BEGIN{FS="@"; OFS="\n"} { print $1; exit }' )
	CPUN=$(grep -c '^processor' /proc/cpuinfo)

	loc="/sys/devices/system/cpu/cpu0/cpufreq"
	bl="${loc}/bios_limit"
	smf="${loc}/scaling_max_freq"
	if [ -f "$bl" ] && [ -r "$bl" ]; then
		cpu_mhz=$(awk '{print $1/1000}' "$bl")
	elif [ -f "$smf" ] && [ -r "$smf" ]; then
		cpu_mhz=$(awk '{print $1/1000}' "$smf")
	else
		cpu_mhz=$(awk -F':' '/cpu MHz/{ print int($2+.5) }' /proc/cpuinfo | head -n 1)
	fi
	if [ -n "$cpu_mhz" ]; then
		if [ $(echo $cpu_mhz | cut -d. -f1) -gt 999 ]; then
			cpu_ghz=$(awk '{print $1/1000}' <<< "${cpu_mhz}")
			cpufreq="${cpu_ghz}GHz"
		else
			cpufreq="${cpu_mhz}MHz"
		fi
	fi

	if [[ "${CPUN}" -gt "1" ]]; then
		CPUN="${CPUN}x "
	else
		CPUN=""
	fi
	if [ -z "$cpufreq" ]; then
		CPU="${CPUN}${CPU}"
	else
		CPU="$CPU $CPUN @ ${cpufreq}"
	fi

	echo $( sed -r 's/\([tT][mM]\)|\([Rr]\)|[pP]rocessor|CPU//g' <<< "${CPU}" | xargs )
}

function cpu_usage() {
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'
}

function disk_usage() {

    used=$( df -h | grep /dev/sdb3 | awk '{print $3}')
    all=$( df -h | grep /dev/sdb3 | awk '{print $2}' ) 
    percent=$( df -h | grep /dev/sdb3 | awk '{print $5}' )

    echo "$used out of $all ($percent)"
}

function package_updates() {
    apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }' | wc -l

}

function updates() {
	DISTRO=$( cat /etc/os-release | grep ID= | sed s/ID=//g )

	case ${DISTRO} in
		"arch")
			PACK_NUM=$( pacman -Qu | grep -v ignored | wc -l ) ;;
		"ubuntu*"|"linuxmint")
			PACK_NUM=$( apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }' | wc -l ) ;;
		*)
			PACK_NUM=-1
	esac

	if [[ ${PACK_NUM} != -1 ]]; then
		echo "     Package updates   :  ${PACK_NUM}"
	fi
	echo ""
}

clear

echo ""
echo "       ________                    __    __      __                                                                        "
echo "      |        \                  |  \  |  \    |  \                                                                       "                             
echo "      | \$\$\$\$\$\$\$\$______   __    __  \\$\$ _| \$\$_   | \$\$  ______    ______    ______                             "
echo "      | \$\$__   /      \ |  \  |  \|  \|   \$\$ \  | \$\$ /      \  /      \  /      \                                    "
echo "      | \$\$  \ |  \$\$\$\$\$\$\| \$\$  | \$\$| \$\$ \\$\$\$\$\$\$  | \$\$|  \$\$\$\$\$\$\|  \$\$\$\$\$\$\|  \$\$\$\$\$\$\ "
echo "      | \$\$\$\$\$ | \$\$   \\$\$| \$\$  | \$\$| \$\$  | \$\$ __ | \$\$| \$\$  | \$\$| \$\$  | \$\$| \$\$  | \$\$          "
echo "      | \$\$    | \$\$      | \$\$__/ \$\$| \$\$  | \$\$|  \| \$\$| \$\$__/ \$\$| \$\$__/ \$\$| \$\$__/ \$\$               "
echo "      | \$\$    | \$\$       \\$\$    \$\$| \$\$   \\$\$  \$\$| \$\$ \\$\$    \$\$ \\$\$    \$\$| \$\$    \$\$             "
echo "       \\$\$     \\$\$        \\$\$\$\$\$\$  \\$\$    \\$\$\$\$  \\$\$  \\$\$\$\$\$\$   \\$\$\$\$\$\$ | \$\$\$\$\$\$\$     "
echo "                                                                        | \$\$                                             "
echo "                                                                        | \$\$                                             "    
echo "                                                                         \\$\$                                             "    
echo ""
echo "     Today's date      :  $( date "+%B %d, %Y (%A)" )"
echo "     Current time      :  $( date +"%T" )"
echo "     Operating system  :  $( source /etc/os-release; echo ${PRETTY_NAME} )"
echo "     Kernel version    :  $( uname -r )"
echo "     Processor         :  $( cpu )"
echo "     CPU Usage         :  $( cpu_usage )"
echo "     Memory usage      :  $( memUsage )"
echo "     Disk usage        :  $( disk_usage )" 
           updates
echo ""
