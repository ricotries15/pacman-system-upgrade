#!/bin/bash

# confirm root is executing
[[ $UID -eq 0 ]] || { echo 'script requires elevated privileges!' ; exit 1 ; }

# confirm system is arch linux
[[ -f /etc/arch-release ]] || { echo 'system is not arch linux!' ; exit 1 ; }

# log since last system upgrade
tmp_log="$(tac /var/log/pacman.log | sed -n '0,/starting full system upgrade/p' | tac)"

# find last upgrade time
last_upgrade="$(date -d "$(awk -F'[][]' 'NR==1 {print $2}' <<< "$tmp_log")" +%s)"

# time -> epoch function for html filter
d2e () { date -d "$(cut -d ' ' -f 1 <<< $1) 00:00" +%s ; }

# extract news by filtering html from curl
empty=''
while read -d $'\n' line ; do
    [[ $(d2e "$line") -gt $last_upgrade ]] && { echo "$line" ; empty='nope' ; }
done < <(curl -s https://archlinux.org/news/ \
        | grep -E '<td>[0-9\-]{10}</td>|title="View:' \
        | sed -E 's|^ +||;s|^<td>([0-9\-]{10})</td>|\1|;s|^title=.+>(.+)</a></td>$|\1|;$!N;s|\n| |'
)

[[ -z $empty ]] && echo -e 'No Arch Linux news since last upgrade!\n'

# execute pacman sync and upgrade
pacman -Syu
