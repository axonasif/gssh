use std::print::log;
use std::native::sleep;

function stream_gp_ports() {
	export cppid=$PPID;
	echo "$cppid" > /tmp/ppid
  function read_ports() {
	  while sleep 2 && grep -q '@pts/' "/proc/$cppid/cmdline"; do {
		lsof -P -iTCP -sTCP:LISTEN -F 'n' | sed -n 's/^n.*://p';
	} done
  }

  local forwarded_ports=(22000 23000);
  if command -v tmux 1>/dev/null; then {
  	local tmux=true;
  } fi
  while read -r port; do {
          if [[ ! "${forwarded_ports[*]}" =~ (^| )${port}($| ) ]]; then {
                  forwarded_ports+=("$port");
		  if test -v tmux; then {
			  while read -r session_name; do {
				tmux display-message -t "$session_name" "Port ${port} was forwarded to your client device";
			  } done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null);
		  	unset session_name;
		  } fi
                  printf '%s\n' "$port";
          } fi
  } done < <(read_ports)
}

function main() {
  local args=("${@}");
  # ran_port=$(($RANDOM * $RANDOM * $RANDOM)) && ran_port="${ran_port::4}";
  # address="localhost:$ran_port";
  local master_socket="/tmp/.gssh_sock.$$_$RANDOM";

  for i in "${!args[@]}"; do {
	if [[ "${args[i]}" == "--" ]]; then {
		break;
	} fi
	  if [[ "${args[i]}" == "/usr/bin/ssh" ]] || [[ "${args[i]}" == ssh ]]; then {
     unset 'args[i]'; 
    } elif test ! -v server_address && [[ "${args[i]}" =~ [^[:space:]]+@[^[:space:]]+ ]]; then {
      local server_address="${args[i]}";
      unset 'args[i]';
    } fi
  } done
  args=("${args[@]}");

  if test ! -v server_address; then {
    log::error "No server address was given!" 1 || exit 1;
  } fi

	local ssh_command=(
	    ssh
		    #-C # For compression
		    #-o ControlMaster=auto
		    #-o ControlPath="$master_socket"
		    #-o ControlPersist=10m
		    -M -S "$master_socket"
		    -o UserKnownHostsFile=/dev/null
		    -o StrictHostKeyChecking=no
		    "$server_address"
		    "${args[@]}"
	);

# Start port watcher in the background
  (
    until sleep 2 && test -e "$master_socket"; do {
      continue;
    } done

    host="127.0.0.1";
    while read -r port; do {
      # Avoid conflict for multiple ssh connections
      while nc -w 1 -z "$host" "$port" 2>/dev/null; do {
	      log::warn "Port $port already exists, adding 1 to $port to try again";
	      port="$((port + 1))"
      } done
      ssh -n -O forward -S "$master_socket" -L "${port}:${host}:${port}" "$server_address";
    } done < <(
      printf '%s\n' "$(declare -f stream_gp_ports)" "stream_gp_ports;exit" \
        | exec ssh -T -S "$master_socket" /bin/bash
    )
  ) &

  exec "${ssh_command[@]}"
}

