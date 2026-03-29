#!/bin/bash
#
# https://github.com/hwdsl2/docker-wireguard
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
# Copyright (C) 2020 Nyr
#
# Based on the work of Nyr and contributors at:
# https://github.com/Nyr/wireguard-install
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WG_CONF="/etc/wireguard/wg0.conf"

exiterr() { echo "Error: $1" >&2; exit 1; }

show_usage() {
  if [ -n "$1" ]; then
    echo "Error: $1" >&2
  fi
  cat 1>&2 <<'EOF'

WireGuard Docker - Client Management
https://github.com/hwdsl2/docker-wireguard

Usage: docker exec <container> wg_manage [options]

Options:
  --addclient      [client name]    add a new client
  --listclients                     list the names of existing clients
  --removeclient   [client name]    remove an existing client
  --showclientcfg  [client name]    export configuration for an existing client (stdout)
  --showclientqr   [client name]    show QR code for an existing client
  -y, --yes                         assume "yes" when removing a client
  -h, --help                        show this help message and exit

EOF
  exit 1
}

check_container() {
  if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
    && [ -z "$KUBERNETES_SERVICE_HOST" ] \
    && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
    exiterr "This script must be run inside a container (e.g. Docker, Podman)."
  fi
}

check_setup() {
  if [ ! -f "$WG_CONF" ]; then
    exiterr "WireGuard has not been set up yet. Please start the container first."
  fi
}

set_client_name() {
  client=$(printf '%s' "$unsanitized_client" | \
    sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g')
}

parse_args() {
  add_client=0
  list_clients=0
  remove_client=0
  show_client_cfg=0
  show_client_qr=0
  assume_yes=0
  unsanitized_client=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --addclient)
        add_client=1
        unsanitized_client="$2"
        shift; shift
        ;;
      --listclients)
        list_clients=1
        shift
        ;;
      --removeclient)
        remove_client=1
        unsanitized_client="$2"
        shift; shift
        ;;
      --showclientcfg)
        show_client_cfg=1
        unsanitized_client="$2"
        shift; shift
        ;;
      --showclientqr)
        show_client_qr=1
        unsanitized_client="$2"
        shift; shift
        ;;
      -y|--yes)
        assume_yes=1
        shift
        ;;
      -h|--help)
        show_usage
        ;;
      *)
        show_usage "Unknown parameter: $1"
        ;;
    esac
  done
}

check_args() {
  if [ "$((add_client + list_clients + remove_client + show_client_cfg + show_client_qr))" -eq 0 ]; then
    show_usage
  fi
  if [ "$((add_client + list_clients + remove_client + show_client_cfg + show_client_qr))" -gt 1 ]; then
    show_usage "Specify only one of '--addclient', '--listclients', '--removeclient', '--showclientcfg', or '--showclientqr'."
  fi
  if [ "$((add_client + remove_client + show_client_cfg + show_client_qr))" -eq 1 ]; then
    set_client_name
    if [ -z "$client" ]; then
      exiterr "Invalid client name. Use one word only, no special characters except '-' and '_'."
    fi
  fi
  if [ "$add_client" = 1 ]; then
    if grep -q "^# BEGIN_CLIENT $client$" "$WG_CONF"; then
      exiterr "'$client': invalid name. Client already exists."
    fi
  fi
  if [ "$remove_client" = 1 ] || [ "$show_client_cfg" = 1 ] || [ "$show_client_qr" = 1 ]; then
    if ! grep -q "^# BEGIN_CLIENT $client$" "$WG_CONF"; then
      exiterr "Invalid client name, or client does not exist."
    fi
  fi
}

get_next_octet() {
  octet=2
  while grep -q "AllowedIPs = 10\.7\.0\.$octet/32" "$WG_CONF"; do
    octet=$((octet + 1))
  done
  if [ "$octet" -ge 255 ]; then
    exiterr "253 clients are already configured. The WireGuard VPN subnet is full."
  fi
  echo "$octet"
}

get_server_pubkey() {
  local server_priv
  server_priv=$(grep '^PrivateKey ' "$WG_CONF" | head -n 1 | awk '{print $3}')
  printf '%s' "$server_priv" | wg pubkey
}

get_server_endpoint() {
  grep '^# ENDPOINT ' "$WG_CONF" | cut -d ' ' -f 3
}

get_server_port() {
  grep '^ListenPort ' "$WG_CONF" | awk '{print $3}'
}

write_client_conf() {
  local p="$1" priv="$2" psk="$3" octet="$4"
  local server_pub server_endpoint server_port client_dns dns2
  server_pub=$(get_server_pubkey)
  server_endpoint=$(get_server_endpoint)
  server_port=$(get_server_port)
  client_dns="${VPN_DNS_SRV1:-8.8.8.8}"
  dns2="${VPN_DNS_SRV2:-8.8.4.4}"
  client_dns="$client_dns, $dns2"
  mkdir -p /etc/wireguard/clients
  cat > "/etc/wireguard/clients/${p}.conf" <<EOF
[Interface]
Address = 10.7.0.$octet/24
DNS = $client_dns
PrivateKey = $priv

[Peer]
PublicKey = $server_pub
PresharedKey = $psk
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $server_endpoint:$server_port
PersistentKeepalive = 25
EOF
  chmod 600 "/etc/wireguard/clients/${p}.conf"
}

do_add_client() {
  local octet client_priv client_psk client_pub
  echo
  echo "Adding client '$client'..."
  octet=$(get_next_octet)
  client_priv=$(wg genkey)
  client_psk=$(wg genpsk)
  client_pub=$(printf '%s' "$client_priv" | wg pubkey)

  # Append client block to server config
  cat >> "$WG_CONF" <<EOF

# BEGIN_CLIENT $client
[Peer]
PublicKey = $client_pub
PresharedKey = $client_psk
AllowedIPs = 10.7.0.$octet/32
# END_CLIENT $client
EOF

  # Apply to running interface if available
  if ip link show wg0 >/dev/null 2>&1; then
    wg set wg0 peer "$client_pub" \
      preshared-key <(printf '%s' "$client_psk") \
      allowed-ips "10.7.0.$octet/32"
  fi

  # Write client config and show QR
  write_client_conf "$client" "$client_priv" "$client_psk" "$octet"
  echo
  echo "Client '$client' added."
  echo "Client configuration: /etc/wireguard/clients/$client.conf"
  echo "Use 'docker cp <container>:/etc/wireguard/clients/$client.conf .' to download it."
  echo
  echo "QR code for $client (scan with your WireGuard mobile app):"
  echo
  qrencode -t ansiutf8 < "/etc/wireguard/clients/$client.conf"
  echo
}

do_list_clients() {
  echo
  echo "Checking for existing clients..."
  num=$(grep -c '^# BEGIN_CLIENT ' "$WG_CONF" 2>/dev/null || echo 0)
  if [ "$num" -eq 0 ]; then
    echo
    echo "No clients found."
    echo
    exit 0
  fi
  echo
  grep '^# BEGIN_CLIENT ' "$WG_CONF" | awk '{print $3}' | nl -s ') '
  echo
  if [ "$num" -eq 1 ]; then
    printf '%s\n\n' "Total: 1 client"
  else
    printf '%s\n\n' "Total: $num clients"
  fi
}

do_remove_client() {
  if [ "$assume_yes" != 1 ]; then
    echo
    printf 'Remove client '"'"'%s'"'"'? This cannot be undone. [y/N]: ' "$client"
    read -r remove
    case "$remove" in
      [yY][eE][sS]|[yY]) ;;
      *) echo; echo "Removal aborted."; echo; exit 1 ;;
    esac
  fi
  echo
  echo "Removing client '$client'..."

  # Get client public key before removing from conf
  client_pub=$(sed -n "/^# BEGIN_CLIENT $client$/,/^# END_CLIENT $client$/p" "$WG_CONF" \
    | grep '^PublicKey ' | awk '{print $3}')

  # Remove from live interface if running
  if [ -n "$client_pub" ] && ip link show wg0 >/dev/null 2>&1; then
    wg set wg0 peer "$client_pub" remove 2>/dev/null || true
  fi

  # Remove client block from server config
  sed -i "/^# BEGIN_CLIENT $client$/,/^# END_CLIENT $client$/d" "$WG_CONF"

  # Remove blank lines that may be left before the next section
  sed -i '/^$/N;/^\n$/d' "$WG_CONF"

  # Remove client config file if present
  rm -f "/etc/wireguard/clients/$client.conf"

  echo
  echo "Client '$client' removed."
  echo
}

do_show_client_cfg() {
  local conf_file="/etc/wireguard/clients/${client}.conf"
  if [ ! -f "$conf_file" ]; then
    # Regenerate if the file is missing but client exists in server config
    local client_pub client_priv client_psk octet
    client_pub=$(sed -n "/^# BEGIN_CLIENT $client$/,/^# END_CLIENT $client$/p" "$WG_CONF" \
      | grep '^PublicKey ' | awk '{print $3}')
    client_psk=$(sed -n "/^# BEGIN_CLIENT $client$/,/^# END_CLIENT $client$/p" "$WG_CONF" \
      | grep '^PresharedKey ' | awk '{print $3}')
    octet=$(sed -n "/^# BEGIN_CLIENT $client$/,/^# END_CLIENT $client$/p" "$WG_CONF" \
      | grep '^AllowedIPs ' | grep -oE '10\.7\.0\.([0-9]+)/32' | cut -d. -f4 | cut -d/ -f1)
    if [ -z "$client_psk" ] || [ -z "$octet" ]; then
      exiterr "Client config file not found and cannot be regenerated (private key is not stored). Use '--removeclient $client' and re-add the client."
    fi
    echo "Warning: Client config file not found. A new config with a new private key cannot be generated." >&2
    echo "         Use '--removeclient $client' and '--addclient $client' to regenerate." >&2
    exit 1
  fi
  cat "$conf_file"
}

do_show_client_qr() {
  local conf_file="/etc/wireguard/clients/${client}.conf"
  if [ ! -f "$conf_file" ]; then
    exiterr "Client config file not found: $conf_file. Use '--showclientcfg $client' for details."
  fi
  echo
  echo "QR code for $client:"
  echo
  qrencode -t ansiutf8 < "$conf_file"
  echo
}

check_container
check_setup
parse_args "$@"
check_args

if [ "$add_client" = 1 ]; then
  do_add_client
  exit 0
fi

if [ "$list_clients" = 1 ]; then
  do_list_clients
  exit 0
fi

if [ "$remove_client" = 1 ]; then
  do_remove_client
  exit 0
fi

if [ "$show_client_cfg" = 1 ]; then
  do_show_client_cfg
  exit 0
fi

if [ "$show_client_qr" = 1 ]; then
  do_show_client_qr
  exit 0
fi