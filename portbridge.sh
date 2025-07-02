#!/bin/bash

sudo apt update
sudo apt install -y socat

while true; do
  clear
  echo "1) add new"
  echo "2) delete"
  echo "3) show"
  echo "q) quit"
  read -p "Choose an option: " choice

  if [[ "$choice" == "1" ]]; then
    read -p "kharej port: " kharej_port
    read -p "iran ip: " iran_ip
    read -p "iran port: " iran_port

    service_name="socat-to-iran-${kharej_port}"
    service_path="/etc/systemd/system/${service_name}.service"

    echo "[Unit]
Description=Socat tunnel to Iran API
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:${kharej_port},fork TCP:${iran_ip}:${iran_port}
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee "$service_path" > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl restart "$service_name"
    status=$(systemctl is-active "$service_name")

    if [[ "$status" == "active" ]]; then
      echo "✅ $service_name is active"
    else
      echo -e "\e[31m❌ Error starting $service_name:\e[0m"
      sudo journalctl -u "$service_name" -n 10 --no-pager
    fi

    read -p "Press enter to continue..."

  elif [[ "$choice" == "2" ]]; then
    read -p "Enter the tunnel id (port): " tunnel_id
    service_name="socat-to-iran-${tunnel_id}"
    sudo systemctl stop "$service_name"
    sudo systemctl disable "$service_name"
    sudo rm -f "/etc/systemd/system/${service_name}.service"
    sudo systemctl daemon-reload
    echo "Deleted $service_name"
    read -p "Press enter to continue..."

  elif [[ "$choice" == "3" ]]; then
    echo "Active tunnels:"
    for f in /etc/systemd/system/socat-to-iran-*.service; do
      [[ -e "$f" ]] || continue
      fname=$(basename "$f")
      port=$(echo "$fname" | sed 's/socat-to-iran-\(.*\)\.service/\1/')
      echo "Tunnel ID: $port"
    done
    read -p "Press enter to continue..."

  elif [[ "$choice" == "q" ]]; then
    break
  fi
done
