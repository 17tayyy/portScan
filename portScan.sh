#!/bin/bash

if ! command -v nc &> /dev/null; then
    echo "${RED} Install Netcat and try again.${RESET}"
    exit 1
fi

if ! command -v timeout &> /dev/null; then
    echo "${RED}[!] Install timeout and try again.${RESET}"
    exit 1
fi

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

start_time=$(date +%s)
temp_file=$(mktemp)

function show_usage() {
    echo -e "${BLUE}Usage:${RESET} $0 -h <host> -p <ports> [-t <timeout>]"
    echo -e "${BLUE}Example:${RESET} $0 -h 192.168.1.1 -p 80,443,22 -t 0.1"
    echo -e "${BLUE}Options:${RESET}"
    echo -e "  -h, --host    Target IP or domain"
    echo -e "  -p, --ports   Ports to scan (comma-separated or range, e.g., 20-80)"
    echo -e "  -t, --timeout Timeout per port in seconds (optional, default 1s)"
    echo -e "  --help        Show this help"
}

function handle_interrupt() {
    echo -e "\n${RED}Scan interrupted.${RESET}"
    rm -f "$temp_file"
    exit 1
}

trap handle_interrupt SIGINT

function scan_port() {
    local host=$1
    local port=$2
    local timeout=$3

    if timeout $timeout bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "$port" >> "$temp_file"
    fi
}

function show_progress() {
    local progress=$1
    local total=$2
    local width=50
    local filled=$(( (progress * width) / total ))
    local empty=$(( width - filled ))

    printf "\r["
    for ((i=0; i<filled; i++)); do printf "#"; done
    for ((i=0; i<empty; i++)); do printf " "; done
    printf "] %d/%d ports scanned" "$progress" "$total"
}

host=""
ports=""
timeout=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host)
            host=$2
            shift 2
            ;;
        -p|--ports)
            ports=$2
            shift 2
            ;;
        -t|--timeout)
            timeout=$2
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unrecognized option: $1${RESET}"
            show_usage
            exit 1
            ;;
    esac
done

if [[ -z $host || -z $ports ]]; then
    show_usage
    exit 1
fi

IFS=',' read -r -a port_array <<< "$ports"

expanded_ports=()
for port in "${port_array[@]}"; do
    if [[ $port == *-* ]]; then
        start_port=$(echo $port | cut -d '-' -f 1)
        end_port=$(echo $port | cut -d '-' -f 2)
        for ((i=start_port; i<=end_port; i++)); do
            expanded_ports+=($i)
        done
    else
        expanded_ports+=($port)
    fi
done

total_ports=${#expanded_ports[@]}
current_port=0

echo -e "${YELLOW}Scanning ports on $host with a timeout of $timeout seconds...${RESET}"

max_parallel=100
for port in "${expanded_ports[@]}"; do
    scan_port $host $port $timeout & 
    current_port=$((current_port + 1))

    show_progress "$current_port" "$total_ports"

    if (( current_port % max_parallel == 0 )); then
        wait
    fi
done

wait

show_progress "$total_ports" "$total_ports"
echo ""

echo -e "${BLUE}Scan complete.${RESET}"
if [[ -s $temp_file ]]; then
    echo -e "${GREEN}Open ports:${RESET}"
    cat "$temp_file"
else
    echo -e "${RED}No open ports found.${RESET}"
fi

rm -f "$temp_file"

