export allowed_commands=(foobarize echo_ reload_commands sample allow_command);
foobarize(){ echo "$3: foobar"; } 
echo_(){ echo "$3: $4"; }
allow_command(){ allowed_commands+=($4); echo "$3: Your command is now allowed"; }
see_allowed_commands(){ echo ${allowed_commands[@]}; }
reload_commands(){ source $BASH_SOURCE;  }
sample(){ Server $1\n Channel $2\n Owner $3\n Arguments $4; }
