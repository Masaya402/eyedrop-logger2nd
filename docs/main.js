const TYPES = ["Type A", "Type B", "Type C"];
const MAX_DAYS = 180;
const STORAGE_KEY = "eyedrop_entries";

const typeSelect = document.getElementById("typeSelect");
const dropBtn = document.getElementById("dropBtn");
const logList = document.getElementById("log");

TYPES.forEach(t => {
  const opt = document.createElement("option");
  opt.value = t;
  opt.textContent = t;
  typeSelect.appendChild(opt);
});

dropBtn.addEventListener("click", () => {
  const entry = { date: new Date().toISOString(), type: typeSelect.value };
  const data = load();
  data.unshift(entry);
  save(prune(data));
  render();
});

function load() {
  return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
}
function save(arr) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(arr));
}
function prune(arr) {
  const cutoff = Date.now() - MAX_DAYS * 24 * 60 * 60 * 1000;
  return arr.filter(e => new Date(e.date).getTime() >= cutoff);
}
function render() {
  const data = load();
  logList.innerHTML = "";
  data.forEach(e => {
    const li = document.createElement("li");
    const left = document.createElement("span");
    left.textContent = e.type;
    const right = document.createElement("span");
    const d = new Date(e.date);
    right.textContent = d.toLocaleDateString() + " " + d.toLocaleTimeString();
    li.appendChild(left);
    li.appendChild(right);
    logList.appendChild(li);
  });
}
render();

// Service Worker registration for offline usage
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js');
  });
}
