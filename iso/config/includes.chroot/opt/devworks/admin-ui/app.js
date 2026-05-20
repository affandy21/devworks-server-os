const $ = (selector) => document.querySelector(selector);
const HISTORY_LIMIT = 60;
const POLL_MS = 1000;
const chartHistory = {
  cpu: [],
  memory: [],
  disk: [],
  network: [],
  gpu: [],
};
let lastNetworkSample = null;

const formatBytes = (bytes) => {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`;
};

const formatUptime = (seconds) => {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  return `${days}d ${hours}h ${minutes}m`;
};

const setMetric = (id, value, detail, percent) => {
  const tile = document.querySelector(`[data-metric="${id}"]`);
  if (!tile) return;
  tile.querySelector("strong").textContent = value;
  tile.querySelector("small").textContent = detail;
  tile.querySelector(".meter i").style.width = `${Math.max(0, Math.min(100, percent))}%`;
};

const pushHistory = (key, value) => {
  const bucket = chartHistory[key];
  bucket.push(Number.isFinite(value) ? value : 0);
  if (bucket.length > HISTORY_LIMIT) {
    bucket.shift();
  }
};

const setChartValue = (key, text) => {
  const value = document.querySelector(`[data-chart-value="${key}"]`);
  if (value) value.textContent = text;
};

const networkRate = (network, timestamp) => {
  const total = (network.rx_bytes || 0) + (network.tx_bytes || 0);
  if (!lastNetworkSample) {
    lastNetworkSample = { total, timestamp };
    return 0;
  }
  const elapsed = Math.max(1, timestamp - lastNetworkSample.timestamp);
  const delta = Math.max(0, total - lastNetworkSample.total);
  lastNetworkSample = { total, timestamp };
  return delta / elapsed;
};

const drawChart = (key, maxValue = 100) => {
  const canvas = document.querySelector(`[data-chart="${key}"]`);
  if (!canvas) return;

  const rect = canvas.getBoundingClientRect();
  const ratio = window.devicePixelRatio || 1;
  const width = Math.max(1, Math.floor(rect.width * ratio));
  const height = Math.max(1, Math.floor(rect.height * ratio));
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }

  const ctx = canvas.getContext("2d");
  const values = chartHistory[key];
  const padded = Array.from({ length: HISTORY_LIMIT }, (_, index) => {
    const offset = values.length - HISTORY_LIMIT + index;
    return offset >= 0 ? values[offset] : 0;
  });

  ctx.clearRect(0, 0, width, height);
  ctx.lineWidth = Math.max(1.5, ratio * 1.5);
  ctx.strokeStyle = "#0078d4";
  ctx.fillStyle = "rgba(0, 120, 212, 0.12)";

  const xStep = width / (HISTORY_LIMIT - 1);
  const yFor = (value) => height - (Math.min(maxValue, Math.max(0, value)) / maxValue) * height;

  ctx.beginPath();
  padded.forEach((value, index) => {
    const x = index * xStep;
    const y = yFor(value);
    if (index === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  });
  ctx.stroke();

  ctx.lineTo(width, height);
  ctx.lineTo(0, height);
  ctx.closePath();
  ctx.fill();
};

const renderCharts = () => {
  const networkMax = Math.max(1024, ...chartHistory.network) * 1.2;
  drawChart("cpu");
  drawChart("memory");
  drawChart("disk");
  drawChart("gpu");
  drawChart("network", networkMax);
};

const stateClass = (state) => {
  if (state === "active" || state === "running") return "ok";
  if (state === "unavailable" || state === "failed" || state === "inactive") return "danger";
  return "warn";
};

async function getJson(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  return response.json();
}

async function refreshSummary() {
  const summary = await getJson("/api/summary");
  $("#hostname").textContent = summary.hostname;
  $("#platform").textContent = summary.platform;
  $("#kernel").textContent = summary.kernel;
  $("#uptime").textContent = formatUptime(summary.uptime_seconds);
  $("#last-refresh").textContent = new Date(summary.timestamp * 1000).toLocaleTimeString("id-ID");

  setMetric("cpu", `${summary.cpu.percent}%`, `${summary.cpu.cores} core`, summary.cpu.percent);
  setMetric(
    "memory",
    `${summary.memory.percent}%`,
    `${formatBytes(summary.memory.used)} / ${formatBytes(summary.memory.total)}`,
    summary.memory.percent,
  );
  setMetric(
    "disk",
    `${summary.disk.percent}%`,
    `${formatBytes(summary.disk.free)} free`,
    summary.disk.percent,
  );

  const gpuDevice = summary.gpu.devices?.[0];
  const gpuPercent = summary.gpu.available ? gpuDevice.utilization_percent : 0;
  const bytesPerSecond = networkRate(summary.network, summary.timestamp);

  setMetric(
    "gpu",
    summary.gpu.available ? `${gpuDevice.memory_percent}%` : "N/A",
    summary.gpu.available ? gpuDevice.name : "GPU runtime belum terdeteksi",
    summary.gpu.available ? gpuDevice.memory_percent : 0,
  );

  pushHistory("cpu", summary.cpu.percent);
  pushHistory("memory", summary.memory.percent);
  pushHistory("disk", summary.disk.percent);
  pushHistory("network", bytesPerSecond);
  pushHistory("gpu", gpuPercent);
  setChartValue("cpu", `${summary.cpu.percent}%`);
  setChartValue("memory", `${summary.memory.percent}%`);
  setChartValue("disk", `${summary.disk.percent}%`);
  setChartValue("network", `${formatBytes(bytesPerSecond)}/s`);
  setChartValue("gpu", summary.gpu.available ? `${gpuPercent}%` : "N/A");
  renderCharts();
}

async function refreshServices() {
  const payload = await getJson("/api/services");
  $("#service-list").innerHTML = payload.services.map((service) => `
    <li>
      <span class="dot ${stateClass(service.state)}"></span>
      <span>${service.name}</span>
      <strong>${service.state}</strong>
    </li>
  `).join("");
}

async function refreshRuntime() {
  const payload = await getJson("/api/runtime");
  const containerBox = $("#container-list");
  if (!payload.containers.available) {
    containerBox.innerHTML = `<div class="empty-state">${payload.containers.message}</div>`;
  } else if (payload.containers.containers.length === 0) {
    containerBox.innerHTML = `<div class="empty-state">Belum ada container berjalan.</div>`;
  } else {
    containerBox.innerHTML = payload.containers.containers.map((container) => `
      <div class="runtime-row">
        <strong>${container.name}</strong>
        <span>${container.image}</span>
        <small>${container.status}</small>
      </div>
    `).join("");
  }

  const gpuBox = $("#gpu-list");
  if (!payload.gpu.available) {
    gpuBox.innerHTML = `<div class="empty-state">NVIDIA runtime belum tersedia.</div>`;
    return;
  }
  gpuBox.innerHTML = payload.gpu.devices.map((gpu) => `
    <div class="runtime-row">
      <strong>${gpu.name}</strong>
      <span>VRAM ${gpu.memory_used_mb} / ${gpu.memory_total_mb} MB</span>
      <small>Utilization ${gpu.utilization_percent}%</small>
    </div>
  `).join("");
}

async function refreshPackages() {
  const query = encodeURIComponent($("#package-search").value);
  const payload = await getJson(`/api/packages?q=${query}`);
  $("#install-state").textContent = payload.install_enabled ? "Install aktif" : "Install terkunci";
  $("#package-list").innerHTML = payload.packages.map((pkg) => `
    <div class="package-row">
      <div>
        <strong>${pkg.name}</strong>
        <span>${pkg.category} - ${pkg.description}</span>
      </div>
      <button data-install="${pkg.name}">Install</button>
    </div>
  `).join("");
}

async function installPackage(name) {
  $("#activity-log").textContent = `Mengirim perintah install ${name}...`;
  try {
    const payload = await getJson("/api/packages/install", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    $("#activity-log").textContent = payload.message || `${name} selesai diproses.`;
  } catch (error) {
    $("#activity-log").textContent = `Install gagal: ${error.message}`;
  }
}

async function refreshAll() {
  $("#connection-state").textContent = "Updating";
  try {
    await Promise.all([refreshSummary(), refreshServices(), refreshRuntime(), refreshPackages()]);
    $("#connection-state").textContent = "Online";
    $("#connection-state").className = "status-pill online";
  } catch (error) {
    $("#connection-state").textContent = "Offline";
    $("#connection-state").className = "status-pill offline";
    $("#activity-log").textContent = `API belum siap: ${error.message}`;
  }
}

document.addEventListener("click", (event) => {
  const installTarget = event.target.closest("[data-install]");
  if (installTarget) {
    installPackage(installTarget.dataset.install);
  }
  if (event.target.matches("[data-refresh]")) {
    refreshAll();
  }
});

$("#package-search").addEventListener("input", () => refreshPackages());

refreshAll();
setInterval(refreshAll, POLL_MS);
window.addEventListener("resize", renderCharts);
