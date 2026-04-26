# ⚡ MynaTask

> 🧠 Lightweight Task Manager + Process Analyzer built with **PowerShell + WPF**
> 🎨 Cyberpunk UI • ⚡ Fast • 🛠 Developer-friendly

---

## 🚀 Features

### 🔍 Realtime Process Viewer

* View all running processes
* CPU & RAM usage
* Executable file path

### 🎨 Cyberpunk UI

* Dark theme with neon styling
* Clean DataGrid layout
* Highlighted selection & rows

### ⚡ Performance Monitor

* Realtime CPU usage (ProgressBar)
* Smooth refresh (optimized, low lag)

### 🧠 Risk Detection (Basic Heuristic)

* Detects:

  * High RAM usage
  * Missing executable path
* Visual indicators:

  * 🟠 Medium risk
  * 🔴 High risk

> ⚠️ This is NOT an antivirus. It’s a developer tool.

### 🔪 Process Control

* Kill process by PID
* Double-click to kill quickly

### 📂 Open File Location

* Open process executable in Explorer

### 🔎 Search / Filter

* Realtime filtering by process name

---

## 🛠 Requirements

* Windows 10 / 11
* PowerShell 5.1+
* .NET Framework (preinstalled on Windows)

---

## ▶️ How to Run

```bash
powershell -ExecutionPolicy Bypass -File MynaTask.ps1
```

---

## ⚠️ Notes

* Some system processes **cannot be terminated** (Access Denied)
* Risk detection is **heuristic-based**, not security-grade
* No kernel-level or SYSTEM-level operations are used

---

## 💡 Roadmap

* 📊 Realtime CPU/RAM graphs (line chart)
* 🌳 Process tree (parent-child view)
* 🧠 Advanced detection (signatures, behavior)
* 🎮 Mini overlay mode
* 🧩 Plugin system

---

## ⭐ Why This Project?

* No build required (runs directly as `.ps1`)
* Modern UI using WPF (not WinForms)
* Lightweight & fast
* Easy to modify and extend

---

## 🧑‍💻 Author

* GitHub: **ItsMynaX**
* Project: **Myna-Task**

---

## 🔥 Pro Tip

If you like this project:

* ⭐ Star the repo
* 🍴 Fork it and customize your own UI
* 🚀 Share it with other devs

---
