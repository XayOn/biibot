#!/bin/bash - 
# This somehow demonstrates "Quote! Unless you don't want to...
# Irc servers and channels can't have spaces, so we're storing them in an associative array and using parameter expansion to make it a multilevel associative array, even three levels once we tr ":" " ".

declare -x -A options

source iibot_external.sh
{ source ~/.iibot.cfg || source /etc/iibot.cfg || source iibot.cfg || { echo "Could not load config, exitting"; exit 1; }; } 2>/dev/null

in_array(){ first=$1; shift; for a in $@; do [[ $first == $a ]] && return ; done; return 1; }
log(){ echo $@; } # for now...

wait_for_commands(){
    server=$1; channel=$2;
    while [ '1' ]; do [[ -e "${options[dir]}/$server/#$channel/in" ]] && break; done
    tail -n0 -f "${options[dir]}/$server/#$channel/out" | while read date time owner isme command arguments; do
        owner="$(printf -- $owner|tr -d '<>')"; nickd="${options[nick]}"; isme=$(echo $isme|tr -d ":");
        echo "$isme"|grep "$nickd" &>/dev/null && {
            in_array $command ${allowed_commands[@]} && {
                log Executing $command $server $channel $isme $owner $arguments >> "${options[dir]}/$server/#$channel/log";
                $command "$server" "$channel" "$owner" "$arguments" >> "${options[dir]}/$server/#$channel/in";
            } || log "$command not allowed" >> "${options[dir]}/$server/#$channel/log";
        } || log "$command not directed to me, directed to -$isme- instead of -$nickd- " >> "${options[dir]}/$server/#$channel/log";
    done
}

mkdir ${options[dir]} &>/dev/null;

for server in ${options[servers]}; do 
    current_server=( $(echo $server|tr ":" " ") )
    echo "Connecting to ${current_server[@]}";
    echo "Starting allowed commands are ${allowed_commands[@]}"
    ii  -i ${options[dir]} -s ${current_server[1]} -n ${options[nick]} &

    while [ '1' ]; do [[ -e "${options[dir]}/${current_server[1]}/out" ]] && break; done
    echo $! > "${options[dir]}/${current_server[1]}/run"

    for channel in ${options[channels_${current_server[0]}]}; do 
        echo "/join #$channel" >> "${options[dir]}/${current_server[1]}/in"
        { wait_for_commands ${current_server[1]} $channel; } &
    done 

    echo "$$" > "${options[dir]}/current_pid"
done
