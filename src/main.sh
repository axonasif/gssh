use std::print::log;

function stream_gp_ports() {
  function read_ports() {
	while sleep 2 && true "! pgrep -f 'sshd: gitpod@notty' 1>/dev/null"; do {
		gp ports list 2>/dev/null | awk 'NR>2 {print $2}'
	} done
  }

  local forwarded_ports=(22000);
  while read -r port; do {
          if [[ ! "${forwarded_ports[*]}" =~ (^| )${port}($| ) ]]; then {
                  forwarded_ports+=("$port");
                  tmux display-message -t main "Port ${port} was forwarded to your client device";
                  printf '%s\n' "$port";
          } fi
  } done < <(read_ports)
}

function main() {
  local args=("${@}");
  # ran_port=$(($RANDOM * $RANDOM * $RANDOM)) && ran_port="${ran_port::4}";
  # address="localhost:$ran_port";
  local master_socket="/tmp/.gssh_$RANDOM";

  for i in "${!args[@]}"; do {
    if [[ "${args[i]}" == "ssh" ]]; then {
     unset 'args[i]'; 
    } elif [[ "${args[i]}" =~ [^[:space:]]+@[^[:space:]]+ ]]; then {
      local server_address="${args[i]}";
      unset 'args[i]';
    } fi
  } done
  args=("${args[@]}");

  if test ! -v server_address; then {
    log::error "No server address was given!" || exit 1;
  } fi

  # TODO: Reconsider -C
  local ssh_command=(
    ssh
    -C # For compression
    -M -S "$master_socket"
    -o UserKnownHostsFile=/dev/null
    -o StrictHostKeyChecking=no
    "${args[@]}"
    "$server_address"
  );

  # Start port watcher in the background
  (
    until sleep 2 && test -e "$master_socket"; do {
      continue;
    } done

    host="127.0.0.1";
    while read -r port; do {
      # Avoid conflict for multiple ssh connections
      if nc -w 1 -z "$host" "$port" 2>/dev/null; then {
        continue;
      } fi
      ssh -n -O forward -S "$master_socket" -L "${port}:${host}:${port}" "$server_address";
    } done < <(
      printf '%s\n' "$(declare -f stream_gp_ports)" "stream_gp_ports;exit" \
        | exec ssh -T -S "$master_socket" /bin/bash
    )
  ) & disown;

  exec "${ssh_command[@]}"
}

