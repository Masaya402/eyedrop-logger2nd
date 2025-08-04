const TYPES = ["ピレノキシン","エピナスチン","プラノプロフェン"];
const MAX_DAYS = 180;
const STREAK_KEY = "eyedrop_streak";
const STORAGE_KEY = "eyedrop_entries";

const typeSelect = document.getElementById("typeSelect");
const dropBtn = document.getElementById("dropBtn");
let newestFirst = true;
const logList = document.getElementById("log");
const streakMsg = document.getElementById("streakMsg");

// placeholder
const ph = document.createElement("option");
ph.value = "";
ph.textContent = "薬剤を選択";
ph.disabled = true;
ph.selected = true;
typeSelect.appendChild(ph);

typeSelect.addEventListener("change",()=>{
  typeSelect.className = drugClass(typeSelect.value);
  typeSelect.style.color = drugColor(typeSelect.value);
});

TYPES.forEach(t => {
  const opt = document.createElement("option");
  opt.value = t;
  opt.textContent = t;
  opt.className = drugClass(t);
  opt.style.color = drugColor(t);
  typeSelect.appendChild(opt);
});

dropBtn.addEventListener("click", () => {
  const entry = { date: new Date().toISOString(), type: typeSelect.value };
  const data = load();
  data.unshift(entry);
  save(prune(data));
  render();
  checkDailyComplete();
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
function checkDailyComplete(){
  const today = new Date();
  const y = today.getFullYear(), m = today.getMonth(), d = today.getDate();
  const data = load();
  const todayEntries = data.filter(e => {
    const t = new Date(e.date);
    return t.getFullYear() === y && t.getMonth() === m && t.getDate() === d;
  });
  if(todayEntries.length >= 2){
    // streak handling
    const todayStr = today.toISOString().substring(0,10); // YYYY-MM-DD
    const info = JSON.parse(localStorage.getItem(STREAK_KEY) || '{"last":"","count":0}');
    let count = 1;
    if(info.last === todayStr){
      count = info.count; // already counted today
    }else{
      const yest = new Date(today); yest.setDate(yest.getDate()-1);
      const yestStr = yest.toISOString().substring(0,10);
      count = (info.last === yestStr) ? info.count + 1 : 1;
      localStorage.setItem(STREAK_KEY, JSON.stringify({last: todayStr, count}));
    }
    if(streakMsg){
      streakMsg.textContent = `本日の点眼記録達成！継続${count}日目`;
    }
    if(!window._celebrated){
      window._celebrated = true;
      confetti({spread:90,particleCount:120});
    }
  }else{
    if(streakMsg) streakMsg.textContent = "";
  }
}

function render() {
  let data = load();
  data.sort((a,b)=> newestFirst ? new Date(b.date)-new Date(a.date) : new Date(a.date)-new Date(b.date));
  logList.innerHTML = "";
  data.forEach((e, idx) => {
    const li = document.createElement("li");
    const left = document.createElement("span");
    left.textContent = e.type;
    left.className = drugClass(e.type);
    const right = document.createElement("span");
    right.className = "nowrap";
    const d = new Date(e.date);
    right.textContent = d.toLocaleDateString() + " " + formatTime(d);
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
  checkDailyComplete();
}
render();

document.getElementById("clearBtn").addEventListener("click",()=>{
  if(confirm("すべての記録を削除しますか？")){
    save([]);
    render();
  }
});

// 週表示切替と生成
const toggleBtn = document.getElementById("toggleView");
const weekDiv = document.getElementById("weekView");
const orderBtn = document.getElementById("orderBtn");
const printBtn = document.getElementById("printBtn");
if(printBtn){ printBtn.addEventListener("click",()=>window.print()); }

const manualBtn = document.getElementById("manualBtn");
if(manualBtn){
  manualBtn.addEventListener("click",()=>{
    let dateStr = prompt("YYYY-MM-DD HH:mm の形式で入力", "");
    if(!dateStr) return;
    dateStr = dateStr.trim();
    // replace space with T for ISO
    if(dateStr.includes(" ")) dateStr = dateStr.replace(" ", "T");
    const d = new Date(dateStr);
    if(isNaN(d)) { alert("日時の形式が不正です"); return; }
    const entry = {date:d.toISOString(), type:typeSelect.value};
    const data=load();
    data.unshift(entry);
    save(prune(data));
    render();
    checkDailyComplete();
  });
}

const themeBtn = document.getElementById("themeBtn");
if(themeBtn){
  themeBtn.addEventListener("click",()=>{
    const html = document.documentElement;
    const current = html.dataset.theme;
    if(current === "light"){
      html.dataset.theme = "dark";
      themeBtn.textContent = "☀️";
    }else{
      html.dataset.theme = "light";
      themeBtn.textContent = "🌙";
    }
  });
}
if(orderBtn){
  orderBtn.addEventListener("click",()=>{
    newestFirst = !newestFirst;
    orderBtn.textContent = newestFirst ? "新→旧" : "旧→新";
    if(logList.style.display !== "none"){
      render();
    }else{
      buildWeek();
    }
  });
}

if (toggleBtn) {
  toggleBtn.addEventListener("click", () => {
    if (logList.style.display !== "none") {
      logList.style.display = "none";
      buildWeek();
      weekDiv.style.display = "block";
      toggleBtn.textContent = "一覧表示";
    } else {
      weekDiv.style.display = "none";
      logList.style.display = "block";
      toggleBtn.textContent = "週表示";
    }
  });
}

function buildWeek(){
  weekDiv.innerHTML="";
  let data = load();
  data.sort((a,b)=> newestFirst ? new Date(b.date)-new Date(a.date) : new Date(a.date)-new Date(b.date));
  // weeks[key] => array[7] each is array of {drug,time}
  const weeks={};
  // always include next week placeholder to allow future scheduling
  const next = new Date();
  next.setDate(next.getDate()+7);
  const nextKey = getISOWeekString(next);
  if(!weeks[nextKey]) weeks[nextKey] = [[],[],[],[],[],[],[]];

  data.forEach(e=>{
    const d=new Date(e.date);
    const key=getISOWeekString(d);
    if(!weeks[key]) weeks[key]=[[],[],[],[],[],[],[]];
    weeks[key][d.getDay()].push({drug:e.type,time:formatTime(d)});
  });
  let sortedKeys = Object.keys(weeks).sort();
  if(newestFirst) sortedKeys = sortedKeys.reverse();
  const dowLabel=["日","月","火","水","木","金","土"];
  sortedKeys.forEach(k=>{
    const [year,week]=k.split("-").map(Number);
    const weekStart=dateOfISOWeekSun(year,week);
    // compute date labels
    const dates=[];
    for(let i=0;i<7;i++){
      const d=new Date(weekStart);
      d.setDate(d.getDate()+i);
      dates.push(`${d.getMonth()+1}/${d.getDate()}`);
    }
    const maxRows=Math.max(...weeks[k].map(a=>a.length));
    // build table
    const tbl=document.createElement("table");
    tbl.className="weekTbl";
    // head
    const thead=document.createElement("thead");
    const hr=document.createElement("tr");
    for(let i=0;i<7;i++){
      const th=document.createElement("th");
      th.textContent=`${dowLabel[i]} ${dates[i]}`;
      hr.appendChild(th);
    }
    thead.appendChild(hr);
    tbl.appendChild(thead);
    // body
    const tbody=document.createElement("tbody");
    for(let r=0;r<maxRows;r++){
      const tr=document.createElement("tr");
      for(let c=0;c<7;c++){
        const td=document.createElement("td");
        const entry=weeks[k][c][r];
        if(entry){
          td.innerHTML = `<div>${entry.drug}</div><div class="time">${entry.time}</div>`;
          td.className = drugClass(entry.drug);
        }
        tr.appendChild(td);
      }
      tbody.appendChild(tr);
    }
    tbl.appendChild(tbody);
    // prepend to keep recent weeks top
    weekDiv.appendChild(tbl);
  });
}

function drugColor(name){
  if(name==="プラノプロフェン") return "#8bc34a";
  if(name==="エピナスチン") return "orange";
  return "black";
}

function drugClass(name){
  if(name==="プラノプロフェン") return "drug-pra";
  if(name==="エピナスチン") return "drug-epi";
  return "drug-pire";
}

function formatTime(d){
  return d.getHours()+":"+d.getMinutes().toString().padStart(2,"0");
}
function dateOfISOWeekSun(year,week){
  const firstJan=new Date(year,0,1);
  const firstSun=new Date(firstJan);
  firstSun.setDate(firstJan.getDate()-firstJan.getDay());
  const target=new Date(firstSun);
  target.setDate(firstSun.getDate()+ (week-1)*7);
  return target;
}
function getISOWeekString(d){
  const t=new Date(d.getFullYear(),0,1);
  const dayMS=86400000;
  return d.getFullYear()+"-"+Math.ceil((((d-t)/dayMS)+t.getDay()+1)/7);
}

// Service Worker registration for offline usage
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('service-worker.js');
  });
}
