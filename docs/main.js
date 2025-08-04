const TYPES = ["プラノプロフェン", "エピナスチン", "ピレノキシン"];
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
  data.forEach((e, idx) => {
    const li = document.createElement("li");
    const left = document.createElement("span");
    left.textContent = e.type;
    const right = document.createElement("span");
    const d = new Date(e.date);
    right.textContent = d.toLocaleDateString() + " " + d.toLocaleTimeString();
    const del = document.createElement("button");
    del.textContent = "削除";
    del.className = "secondary smallDel";
    del.onclick = () => {
      const arr = load();
      arr.splice(idx,1);
      save(arr);
      render();
    };
    li.appendChild(left);
    li.appendChild(right);
    li.appendChild(del);
    logList.appendChild(li);
  });
}
render();

document.getElementById("clearBtn").addEventListener("click",()=>{
  if(confirm("すべての記録を削除しますか？")){
    save([]);
    render();
  }
});

// Service Worker registration for offline usage
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js');
  });
}
