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
    right.className = "nowrap";
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

// 週表示切替と生成\nconst toggleBtn=document.getElementById("toggleView");\nconst weekDiv=document.getElementById("weekView");\n\nif(toggleBtn){\n  toggleBtn.addEventListener("click",()=>{\n    if(logList.style.display!=="none"){\n      logList.style.display="none";\n      buildWeek();\n      weekDiv.style.display="block";\n      toggleBtn.textContent="一覧表示";\n    }else{\n      weekDiv.style.display="none";\n      logList.style.display="block";\n      toggleBtn.textContent="週表示";\n    }\n  });\n}\n\nfunction buildWeek(){\n  const data=load();\n  const weeks={};\n  data.forEach(e=>{\n    const d=new Date(e.date);\n    const key=getISOWeekString(d);\n    if(!weeks[key]) weeks[key]=new Array(7).fill(false);\n    weeks[key][d.getDay()]=true;\n  });\n  weekDiv.innerHTML="";\n  const sortedKeys=Object.keys(weeks).sort().reverse();\n  const days=["日","月","火","水","木","金","土"];\n  // header\n  const header=document.createElement("div");\n  header.style.display="grid";\n  header.style.gridTemplateColumns="repeat(7,2rem)";\n  days.forEach(d=>{const c=document.createElement("div");c.textContent=d;c.style.fontWeight="bold";c.style.textAlign="center";weekDiv.appendChild(c);});\n  // rows\n  sortedKeys.forEach(k=>{\n    const row=document.createElement("div");\n    row.style.display="grid";\n    row.style.gridTemplateColumns="repeat(7,2rem)";\n    weeks[k].forEach(val=>{\n      const cell=document.createElement("div");\n      cell.style.border="1px solid #555";\n      cell.style.height="2rem";\n      cell.style.display="flex";\n      cell.style.alignItems="center";\n      cell.style.justifyContent="center";\n      cell.textContent=val?"✓":"";\n      row.appendChild(cell);\n    });\n    weekDiv.appendChild(row);\n  });\n}\nfunction getISOWeekString(d){\n  const t=new Date(d.getFullYear(),0,1);\n  const dayMS=86400000;\n  return d.getFullYear()+"-"+Math.ceil((((d-t)/dayMS)+t.getDay()+1)/7);\n}\n\n// Service Worker registration for offline usage
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js');
  });
}
