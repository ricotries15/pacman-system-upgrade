#!/bin/bash

# confirm root is executing
[[ $UID -eq 0 ]] || { printf 'script requires elevated privileges!\n' ; exit 1 ; }

# confirm system is arch linux
[[ -f /etc/arch-release ]] || { printf 'system is not arch linux!\n' ; exit 1 ; }

# confirm required dependencies are installed
while read dependency ; do
    missing_deps+=($(awk -F \' '/error: package.*not found/ {print $2}' <<< "$dependency"))
done < <(pacman -Q coreutils sed gawk curl 2>&1 >/dev/null)

if [[ ${missing_deps[@]} ]] ; then
    printf 'the following dependencies are missing:\n'
    printf '    %s\n' ${missing_deps[@]}
    read -p 'would you like to install them now? [yes/no]> ' _answer
    if [[ $_answer =~ ^y(es)?$ ]] ; then
        pacman -S ${missing_deps[@]}
    else
        printf "install missing dependencies first!\n"
    fi
fi

# log since last system upgrade
tmp_log="$(tac /var/log/pacman.log | sed -n '0,/starting full system upgrade/p' | tac)"

# find last upgrade time
last_upgrade="$(date -d "$(awk -F'[][]' 'NR==1 {print $2}' <<< "$tmp_log")" +%s)"

# time -> epoch function for html filter
d2e () { date -d "$(cut -d ' ' -f 1 <<< $1) 00:00" +%s ; }

# extract news by filtering html from curl
empty=''
while read -d $'\n' line ; do
    [[ $(d2e "$line") -gt $last_upgrade ]] && { printf "$line\n" ; empty='nope' ; }
done < <(curl -s https://archlinux.org/news/ \
        | awk '/<td>[0-9\-]{10}<\/td>|title="View:/' \
        | sed -E 's|^ +||;s|^<td>([0-9\-]{10})</td>|\1|;s|^title=.+>(.+)</a></td>$|\1|' \
        | sed '$!N;s|\n| |'
)

[[ -z $empty ]] && printf 'No Arch Linux news since last upgrade!\n'

# execute pacman sync and upgrade
pacman -Syu
