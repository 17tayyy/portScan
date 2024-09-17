
# Port Scanner Script Usage Guide

This script scans ports on a specified host to check whether they are open or closed.

## Usage

```bash
./port_scan.sh -h <host> -p <ports> [-t <timeout>]
```

### Example:
```bash
./port_scan.sh -h 192.168.1.1 -p 80,443,22 -t 0.1
```

### Options:

- `-h, --host`: **Target IP or domain**.
- `-p, --ports`: **Ports to scan** (comma-separated or a range, e.g., `20-80`).
- `-t, --timeout`: **Timeout per port in seconds** (optional, default is `1s`).
- `--help`: Show the help message.

### Output
- **Open ports**: The script will list all the ports that are open on the specified host.
- **Closed/Filtered ports**: It will also indicate which ports are closed or filtered.

## Example Scan:

```bash
./port_scan.sh -h 192.168.0.10 -p 22,80,443 -t 0.5
```

This will scan ports 22, 80, and 443 on the host `192.168.0.10` with a timeout of `0.5` seconds per port.

## Notes

- The script will exit if either `Netcat` or `timeout` is not installed, prompting you to install the missing dependencies.
- By default, if no timeout is specified, it will use `1s` per port.
