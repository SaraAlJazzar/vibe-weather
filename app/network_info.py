"""Network diagnostics — demonstrates IP, routing, TCP/UDP, DNS concepts."""

import os
import socket
import subprocess
from dataclasses import asdict, dataclass


@dataclass
class InterfaceInfo:
    name: str
    addresses: list[str]


def get_hostname() -> str:
    return socket.gethostname()


def get_container_ips() -> list[InterfaceInfo]:
    """Read network interfaces from the container (Ethernet at L2, IP at L3)."""
    interfaces: list[InterfaceInfo] = []
    try:
        import netifaces  # optional; fall back below
        for iface in netifaces.interfaces():
            addrs = []
            for family in (netifaces.AF_INET, netifaces.AF_INET6):
                for entry in netifaces.ifaddresses(iface).get(family, []):
                    addrs.append(entry.get("addr", ""))
            if addrs:
                interfaces.append(InterfaceInfo(name=iface, addresses=addrs))
    except ImportError:
        # Pure-stdlib fallback via getaddrinfo on hostname
        hostname = socket.gethostname()
        try:
            for info in socket.getaddrinfo(hostname, None):
                family, _, _, _, sockaddr = info
                if family == socket.AF_INET:
                    interfaces.append(
                        InterfaceInfo(name="eth0 (resolved)", addresses=[sockaddr[0]])
                    )
                    break
        except socket.gaierror:
            pass
    return interfaces


def get_routing_table() -> str:
    """Linux routing table — how packets are forwarded (Routing concept)."""
    try:
        result = subprocess.run(
            ["ip", "route"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.strip() or result.stderr.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return "ip route unavailable in this environment"


def tcp_connect_test(host: str = "api.openweathermap.org", port: int = 443) -> dict:
    """TCP connection test (TCP = reliable, connection-oriented, L4)."""
    start = __import__("time").time()
    try:
        with socket.create_connection((host, port), timeout=5):
            latency_ms = round((__import__("time").time() - start) * 1000, 2)
            return {
                "protocol": "TCP",
                "host": host,
                "port": port,
                "status": "connected",
                "latency_ms": latency_ms,
            }
    except OSError as exc:
        return {
            "protocol": "TCP",
            "host": host,
            "port": port,
            "status": "failed",
            "error": str(exc),
        }


def udp_probe(host: str = "8.8.8.8", port: int = 53) -> dict:
    """UDP send probe (UDP = connectionless, used by DNS on port 53)."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(3)
        sock.sendto(b"\x00", (host, port))
        sock.close()
        return {
            "protocol": "UDP",
            "host": host,
            "port": port,
            "service": "DNS",
            "status": "sent",
            "note": "UDP has no handshake; success means packet was sent",
        }
    except OSError as exc:
        return {"protocol": "UDP", "host": host, "port": port, "status": "failed", "error": str(exc)}


def ping_host(host: str = "8.8.8.8", count: int = 3) -> dict:
    """ICMP ping — requires CAP_NET_RAW in containers."""
    try:
        result = subprocess.run(
            ["ping", "-c", str(count), "-W", "2", host],
            capture_output=True,
            text=True,
            timeout=15,
        )
        return {
            "tool": "ping (ICMP)",
            "host": host,
            "exit_code": result.returncode,
            "output": result.stdout.strip() or result.stderr.strip(),
            "note": "ICMP uses neither TCP nor UDP; blocked by many firewalls",
        }
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return {"tool": "ping (ICMP)", "host": host, "status": "unavailable", "error": str(exc)}


def traceroute_host(host: str = "api.openweathermap.org", max_hops: int = 15) -> dict:
    """Traceroute — shows routing path hop-by-hop."""
    for cmd in (
        ["traceroute", "-m", str(max_hops), "-w", "2", host],
        ["tracepath", "-m", str(max_hops), host],
    ):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            return {
                "tool": cmd[0],
                "host": host,
                "exit_code": result.returncode,
                "output": result.stdout.strip() or result.stderr.strip(),
            }
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return {"tool": "traceroute", "host": host, "status": "unavailable"}


def dns_lookup(hostname: str = "api.openweathermap.org") -> dict:
    """DNS resolution — maps hostnames to IP addresses (UDP/TCP port 53)."""
    try:
        results = socket.getaddrinfo(hostname, None)
        ips = list({r[4][0] for r in results})
        return {"hostname": hostname, "addresses": ips, "record_type": "A/AAAA"}
    except socket.gaierror as exc:
        return {"hostname": hostname, "error": str(exc)}


def network_concepts() -> dict:
    """Educational reference for networking topics used in this stack."""
    return {
        "layers": {
            "L2_Ethernet": "Frames between devices on same network segment (MAC addresses)",
            "L3_IP": "Routing between networks using IP addresses (private vs public)",
            "L4_TCP_UDP": "TCP = reliable streams (HTTP/HTTPS); UDP = datagrams (DNS, video)",
            "L7_HTTP_HTTPS": "Application layer — Nginx terminates HTTP/HTTPS here",
        },
        "vpc_analogy": {
            "public_subnet": "nginx container — has host port mapping (80/443) like a public subnet with IGW",
            "private_subnet": "app containers — reachable only via nginx, outbound via Docker NAT (like NAT Gateway)",
            "nat": "Docker iptables MASQUERADE translates container private IPs for internet egress",
            "dns": "Docker embedded DNS (127.0.0.11) resolves service names: app, nginx",
        },
        "ip_addresses": {
            "private_ranges": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
            "container_ips": "Assigned from Docker bridge network CIDR",
            "public_ip": "Server's elastic/public IP — maps to nginx via port forwarding",
        },
        "ports_and_firewall": {
            "exposed": "80 (HTTP), 443 (HTTPS) on host via nginx",
            "internal": "8000/tcp app backend — not published to host",
            "ufw": "Host firewall allows 22, 80, 443 — configured in deploy/setup-server.sh",
        },
        "docker_internals": {
            "multi_stage_build": "Builder stage installs deps; runtime stage is minimal OCI image",
            "buildkit": "Parallel builds + cache mounts (see Dockerfile syntax directive)",
            "layer_caching": "Each Dockerfile instruction = layer; order deps before code",
            "oci_runtime": "containerd/runc executes the final OCI bundle",
            "image_internals": "Layers stacked read-only; copy-on-write container layer on top",
            "storage": "Named volumes for nginx logs; bind mounts for config",
            "logging_drivers": "json-file driver with rotation in docker-compose",
            "registry": "Images pushed to ghcr.io (OCI-compliant registry)",
        },
        "replica_id": os.environ.get("HOSTNAME", "unknown"),
    }


def full_diagnostics() -> dict:
    return {
        "hostname": get_hostname(),
        "interfaces": [asdict(i) for i in get_container_ips()],
        "routing_table": get_routing_table(),
        "dns": dns_lookup(),
        "tcp_test": tcp_connect_test(),
        "udp_test": udp_probe(),
        "ping": ping_host(),
        "traceroute": traceroute_host(),
        "concepts": network_concepts(),
    }
