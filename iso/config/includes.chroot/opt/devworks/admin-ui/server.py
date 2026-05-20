#!/usr/bin/env python3
import json
import os
import platform
import re
import shutil
import subprocess
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse


BASE_DIR = Path(__file__).resolve().parent
HOST = os.environ.get("DEVWORKS_HOST", os.environ.get("HALO_HOST", "0.0.0.0"))
PORT = int(os.environ.get("DEVWORKS_PORT", os.environ.get("HALO_PORT", "8088")))
INSTALL_ENABLED = os.environ.get("DEVWORKS_ENABLE_INSTALL", os.environ.get("HALO_ENABLE_INSTALL", "0")) == "1"
PACKAGE_RE = re.compile(r"^[a-z0-9][a-z0-9+.-]{0,80}$")
WATCHED_SERVICES = ["ssh", "nginx", "docker", "fail2ban", "chrony", "devworks-admin-ui"]


def run_command(args, timeout=4):
    try:
      completed = subprocess.run(
          args,
          text=True,
          stdout=subprocess.PIPE,
          stderr=subprocess.PIPE,
          timeout=timeout,
          check=False,
      )
      return {
          "available": True,
          "ok": completed.returncode == 0,
          "code": completed.returncode,
          "stdout": completed.stdout.strip(),
          "stderr": completed.stderr.strip(),
      }
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
      return {"available": False, "ok": False, "code": None, "stdout": "", "stderr": str(exc)}


def read_linux_cpu():
    try:
        with open("/proc/stat", "r", encoding="utf-8") as stat:
            parts = stat.readline().split()[1:]
            values = [int(part) for part in parts[:8]]
            idle = values[3] + values[4]
            total = sum(values)
            return idle, total
    except OSError:
        return None


LAST_CPU = {"sample": read_linux_cpu(), "time": time.time()}


def cpu_percent():
    current = read_linux_cpu()
    if not current:
        load = os.getloadavg()[0] if hasattr(os, "getloadavg") else 0.0
        cores = os.cpu_count() or 1
        return round(min(100.0, (load / cores) * 100), 1)

    previous = LAST_CPU["sample"]
    LAST_CPU["sample"] = current
    LAST_CPU["time"] = time.time()
    if not previous:
        return 0.0

    idle_delta = current[0] - previous[0]
    total_delta = current[1] - previous[1]
    if total_delta <= 0:
        return 0.0
    return round(max(0.0, min(100.0, 100.0 * (1.0 - idle_delta / total_delta))), 1)


def memory_info():
    mem = {}
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as meminfo:
            for line in meminfo:
                key, value = line.split(":", 1)
                mem[key] = int(value.strip().split()[0]) * 1024
        total = mem.get("MemTotal", 0)
        available = mem.get("MemAvailable", 0)
        used = max(0, total - available)
        percent = round((used / total) * 100, 1) if total else 0.0
        return {"total": total, "used": used, "available": available, "percent": percent}
    except OSError:
        return {"total": 0, "used": 0, "available": 0, "percent": 0.0}


def disk_info():
    usage = shutil.disk_usage("/")
    return {
        "total": usage.total,
        "used": usage.used,
        "free": usage.free,
        "percent": round((usage.used / usage.total) * 100, 1) if usage.total else 0.0,
    }


def network_info():
    try:
        with open("/proc/net/dev", "r", encoding="utf-8") as dev:
            lines = dev.readlines()[2:]
        rx = 0
        tx = 0
        for line in lines:
            _, data = line.split(":", 1)
            fields = data.split()
            rx += int(fields[0])
            tx += int(fields[8])
        return {"rx_bytes": rx, "tx_bytes": tx}
    except OSError:
        return {"rx_bytes": 0, "tx_bytes": 0}


def gpu_info():
    result = run_command([
        "nvidia-smi",
        "--query-gpu=name,memory.used,memory.total,utilization.gpu",
        "--format=csv,noheader,nounits",
    ])
    if not result["ok"]:
        return {"available": False, "devices": []}

    devices = []
    for line in result["stdout"].splitlines():
        parts = [part.strip() for part in line.split(",")]
        if len(parts) != 4:
            continue
        used = int(parts[1])
        total = int(parts[2])
        devices.append({
            "name": parts[0],
            "memory_used_mb": used,
            "memory_total_mb": total,
            "memory_percent": round((used / total) * 100, 1) if total else 0.0,
            "utilization_percent": float(parts[3]),
        })
    return {"available": bool(devices), "devices": devices}


def service_status():
    services = []
    for name in WATCHED_SERVICES:
        result = run_command(["systemctl", "is-active", name], timeout=2)
        if result["available"]:
            state = result["stdout"] or "unknown"
        else:
            state = "unavailable"
        services.append({
            "name": name,
            "state": state,
            "healthy": state == "active",
        })
    return services


def container_status():
    docker = run_command(["docker", "ps", "--format", "{{.Names}}|{{.Image}}|{{.Status}}"], timeout=4)
    if not docker["ok"]:
        return {"available": False, "containers": [], "message": docker["stderr"] or "Docker unavailable"}

    containers = []
    for line in docker["stdout"].splitlines():
        name, image, status = (line.split("|", 2) + ["", "", ""])[:3]
        containers.append({"name": name, "image": image, "status": status})
    return {"available": True, "containers": containers, "message": ""}


def package_catalog(query=""):
    packages = [
        {"name": "nginx", "category": "Web", "description": "Reverse proxy dan web server production."},
        {"name": "postgresql", "category": "Database", "description": "Database SQL stabil untuk aplikasi web."},
        {"name": "redis-server", "category": "Cache", "description": "Cache dan queue ringan."},
        {"name": "docker-compose-plugin", "category": "Container", "description": "Kelola stack container dengan compose."},
        {"name": "certbot", "category": "Security", "description": "TLS certificate automation."},
        {"name": "prometheus-node-exporter", "category": "Monitoring", "description": "Exporter metrik sistem untuk Prometheus."},
        {"name": "python3-venv", "category": "AI", "description": "Virtual environment Python untuk tooling AI."},
        {"name": "git-lfs", "category": "AI", "description": "Dukungan file model besar di Git."},
    ]
    needle = query.lower().strip()
    if needle:
        packages = [
            package for package in packages
            if needle in package["name"] or needle in package["category"].lower() or needle in package["description"].lower()
        ]
    return packages


def install_package(name):
    if not PACKAGE_RE.match(name):
        return 400, {"ok": False, "message": "Nama paket tidak valid."}
    if not INSTALL_ENABLED:
        return 403, {
            "ok": False,
            "message": "Install paket dikunci. Aktifkan DEVWORKS_ENABLE_INSTALL=1 di service jika server sudah siap diamankan.",
        }
    if os.name != "posix" or os.geteuid() != 0:
        return 403, {"ok": False, "message": "Install paket membutuhkan Linux dan akses root."}

    result = run_command(["apt-get", "install", "-y", name], timeout=600)
    return (200 if result["ok"] else 500), {
        "ok": result["ok"],
        "message": result["stdout"][-1200:] if result["ok"] else result["stderr"][-1200:],
    }


def system_summary():
    mem = memory_info()
    disk = disk_info()
    gpu = gpu_info()
    return {
        "hostname": platform.node() or "devworks-server",
        "platform": platform.platform(),
        "kernel": platform.release(),
        "uptime_seconds": uptime_seconds(),
        "cpu": {"percent": cpu_percent(), "cores": os.cpu_count() or 1},
        "memory": mem,
        "disk": disk,
        "network": network_info(),
        "gpu": gpu,
        "timestamp": int(time.time()),
    }


def uptime_seconds():
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as uptime:
            return int(float(uptime.read().split()[0]))
    except OSError:
        return 0


def send_json(handler, status, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class DevworksHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BASE_DIR), **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/health":
            send_json(self, 200, {"ok": True, "install_enabled": INSTALL_ENABLED})
            return
        if parsed.path == "/api/summary":
            send_json(self, 200, system_summary())
            return
        if parsed.path == "/api/services":
            send_json(self, 200, {"services": service_status()})
            return
        if parsed.path == "/api/runtime":
            send_json(self, 200, {"containers": container_status(), "gpu": gpu_info()})
            return
        if parsed.path == "/api/packages":
            query = parse_qs(parsed.query).get("q", [""])[0]
            send_json(self, 200, {"packages": package_catalog(query), "install_enabled": INSTALL_ENABLED})
            return
        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/api/packages/install":
            send_json(self, 404, {"ok": False, "message": "Endpoint tidak ditemukan."})
            return

        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8") or "{}")
        except json.JSONDecodeError:
            send_json(self, 400, {"ok": False, "message": "Payload JSON tidak valid."})
            return
        status, response = install_package(str(payload.get("name", "")))
        send_json(self, status, response)

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))


if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), DevworksHandler)
    print(f"Devworks Control Center listening on http://{HOST}:{PORT}")
    server.serve_forever()
