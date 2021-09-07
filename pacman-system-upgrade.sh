#!/bin/bash

pacman-system-upgrade () {
    # confirm root is executing
    [[ $UID -eq 0 ]] || { printf 'script requires elevated privileges!\n' ; return 1 ; }

    # confirm system is arch linux
    [[ -f /etc/arch-release ]] || { printf 'system is not arch linux!\n' ; return 1 ; }

    # confirm network connectivity
    ping -c 1 archlinux.org &> /dev/null || { printf 'system does not have network connectivity!\n' ; return 1 ; }

    # function to separate sections
    sec_start () { printf "\n----------\n\n" ; }

    # confirm required dependencies are installed
    while read dependency ; do
        missing_deps+=($(awk -F \' '/error: package.*not found/ {print $2}' <<< "$dependency"))
    done < <(pacman -Q coreutils sed gawk curl 2>&1 >/dev/null)

    if [[ ${missing_deps[@]} ]] ; then
        sec_start
        printf 'the following dependencies are missing:\n'
        printf '    %s\n' ${missing_deps[@]}
        read -p 'would you like to install them now? [yes/no]> ' _answer
        if [[ ${_answer,,} =~ ^y(es)?$ ]] ; then
            pacman -S --noconfirm ${missing_deps[@]}
        else
            printf "install missing dependencies first!\n"
            return 1
        fi
    fi

    # find last successful upgrade time
    timestamp="$(tac /var/log/pacman.log | awk '/starting full system upgrade|transaction started/' \
        | awk -F '[][]' '
            BEGIN { var1 = " transaction started" }
            {
              current = $NF;
              if (var1 == current) {
                  found = 1;
                  next;
              } else {
                  if (found != 1) {
                      next;
                  } else {
                      answer = $2;
                      exit;
                  }
              }
            }
            END { print answer }'
    )"
    last_upgrade="$(date -d $timestamp +%s)"

    # time -> epoch function for html filter
    d2e () { date -d "$(cut -d ' ' -f 1 <<< $1) 00:00" +%s ; }

    # extract news by filtering html from curl
    sec_start
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
    sec_start
    pacman -Syu
    pac_exit=$?

    # shutdown system at request
    if [[ $pac_exit -eq 0 ]] ; then
        sec_start
        read -p "Would you like to shut down now? [yes/no]> " _finalans
        [[ ${_finalans,,} =~ ^y(es)?$ ]] && shutdown -P now
    fi
}
