# 🛠️ VektorSec — Installation & Setup Guide

**Windows desktop build** · version **1.2.4** · PentestDB @ Developer By Raysiya

> ⚠️ **Authorized testing only.** Use VektorSec only against systems you own or are
> contractually permitted to test. You are responsible for your actions.
>
> Short version of this document: **[README.md](./README.md)**.

This guide covers everything after you receive the installer: verification, installation,
the local database, first login, model configuration, licensing, verification, troubleshooting,
updating and uninstalling. **No Node.js, no pnpm, no Docker and no Administrator rights are
required** — the installer embeds its own runtime.

---

## 📑 Contents

1. [Requirements](#1--requirements)
2. [Verify and install the application](#2--verify-and-install-the-application)
3. [Install the local database (MongoDB + Redis)](#3--install-the-local-database-mongodb--redis)
4. [First launch: accounts, 2FA and the AI model](#4--first-launch-accounts-2fa-and-the-ai-model)
5. [Verify the installation](#5--verify-the-installation)
6. [License, trial and activation](#6--license-trial-and-activation)
7. [Configuration you can change yourself](#7--configuration-you-can-change-yourself)
8. [Files, folders and ports](#8--files-folders-and-ports)
9. [Troubleshooting](#9--troubleshooting)
10. [Update, uninstall, move to another machine](#10--update-uninstall-move-to-another-machine)
11. [Security, licensing and EULA](#11--security-licensing-and-eula)
12. [Support](#12--support)

---

## 1. 📋 Requirements

| Item | Minimum | Recommended | Notes |
|---|---|---|---|
| OS | Windows 10 / 11 (x64), Windows Server 2016+ | Windows 11 | ARM64 is not supported |
| CPU | 2 cores | 4 cores | Model inference happens in the cloud, not locally |
| RAM | 4 GB | 8 GB | More if you run the optional Kali container |
| Free disk | 3 GB | 10 GB | App ≈ 700 MB, local DB ≈ 700 MB, plus evidence/screenshots |
| Internet | Once, for the DB install | Always | Needed to reach your AI provider and the internet targets you test |
| Rights | Standard user | — | Per-user install (`%LOCALAPPDATA%\Programs\VektorSec`), no UAC |
| Antivirus | Allow the install folder | — | Security tooling is frequently flagged heuristically; add an exclusion if `VektorSec.exe` is quarantined |
| Docker | Not required | — | Only for the Sandbox / Kali container feature |
| VC++ runtime | Microsoft Visual C++ 2015–2022 (x64) | — | Only MongoDB needs it: `mongod.exe` links against `MSVCP140.dll` / `VCRUNTIME140.dll`. The MongoDB zip ships `vc_redist.x64.exe` — see §3.4 if the database will not start. VektorSec itself and Redis need no VC++ runtime |
| AI provider | One API key | — | OpenAI, Anthropic or any OpenAI-compatible endpoint |

**Optional, only for specific features**

| Feature | Needs |
|---|---|
| Sandbox / Kali container | Docker Desktop (WSL2) with ≥ 8 GB assigned |
| Exploit box over SSH | An SSH-reachable Linux box (Kali recommended) |
| Burp Suite / Caido integration | Burp with the RPC extension, or a Caido instance |
| Browser Agent (GUI) | Nothing extra — it runs inside the app |

---

## 2. 📥 Verify and install the application

### 2.1 Check the file before running it

```powershell
Get-FileHash ".\VektorSec-Setup-1.2.4-customer.exe" -Algorithm SHA256 | Format-List
(Get-Item ".\VektorSec-Setup-1.2.4-customer.exe").Length
```

Compare both values with the ones the vendor published for this file. **If they differ, stop
and request a fresh copy** — do not run it.

### 2.2 Run the installer

1. Double-click `VektorSec-Setup-1.2.4-customer.exe`.
2. SmartScreen may warn *"Windows protected your PC"* (the build has no commercial code-signing
   certificate) → **More info** → **Run anyway**.
3. **Next** → read and accept the EULA → choose the destination folder (default
   `%LOCALAPPDATA%\Programs\VektorSec`) → **Install**.
4. The installer creates a desktop shortcut, a Start-menu entry and `Uninstall VektorSec.exe`.

Nothing is written to `C:\Program Files` and no elevation is requested, because the whole
application, its settings and its data live in your own user profile.

### 2.3 Know your install folder

Later steps reference `<install>`. It is the folder you picked in step 3:

```powershell
$install = Join-Path $env:LOCALAPPDATA 'Programs\VektorSec'   # default for a per-user install
Test-Path "$install\VektorSec.exe"                            # must print True
```

If it prints `False`, find the real folder: right-click the desktop shortcut → **Properties**
→ *Target*, and use the directory part. Reuse the same `$install` value in every command
below. The install folder also contains the database script at
`<install>\resources\app\scripts\local-db.ps1` — that nested path is correct, there is **no**
`<install>\scripts\` folder.

---

## 3. 🗄️ Install the local database (MongoDB + Redis)

The desktop build speaks to MongoDB (`127.0.0.1:27017`) and Redis (`127.0.0.1:6379`), exactly
like the server deployment. The installer deliberately does **not** bundle them; a script
inside the app downloads portable builds into your profile and starts them.

> 🔴 **Do not skip this step.** Without the database the UI still opens but the backend dies in
> a restart loop, and the login page answers `Gateway upstream error`.

### 3.1 Option A — use the shipped installer (default, needs internet)

```powershell
$install = Join-Path $env:LOCALAPPDATA 'Programs\VektorSec'

# one time: downloads MongoDB 7.0 + Redis 5.0 (~5 minutes) and starts both
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" install

# confirm both servers are listening
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" status
```

What ends up on disk:

| Path | Contents |
|---|---|
| `%APPDATA%\VektorSec\runtime\mongodb\bin\mongod.exe` | MongoDB server binary |
| `%APPDATA%\VektorSec\runtime\redis\redis-server.exe` | Redis server binary |
| `%APPDATA%\VektorSec\data\mongo` | MongoDB data files (your engagements) |
| `%APPDATA%\VektorSec\data\redis` | Redis persistence files |

Rules that matter:

- **Run the script as the same Windows user that launches VektorSec.** It writes into that
  user's `%APPDATA%`; running it from another account (or as Administrator for another user)
  installs the database somewhere the app cannot see.
- After installation you never start them by hand again: on every launch the app starts both
  servers itself and skips them if the ports are already open.
- Use the full path. `-File scripts\local-db.ps1` only works inside a source checkout and fails
  with *"The argument … does not exist"*.

Available actions: `install`, `start`, `stop`, `status`.

### 3.2 Option B — copy a prepared runtime (offline machines)

Machine without internet (air-gapped lab, customer site)? Prepare the runtime on any machine
with internet, then copy it:

```powershell
# on a machine with internet
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" install

# copy the whole runtime folder to a USB stick
Copy-Item "$env:APPDATA\VektorSec\runtime" -Destination "E:\vektorsec-runtime" -Recurse
```

```powershell
# on the offline machine (VektorSec must be installed first, app closed)
New-Item -ItemType Directory -Force "$env:APPDATA\VektorSec\runtime" | Out-Null
Copy-Item "E:\vektorsec-runtime\*" -Destination "$env:APPDATA\VektorSec\runtime" -Recurse -Force

# the two folders you copied (mongodb, redis)
Get-ChildItem "$env:APPDATA\VektorSec\runtime" | Select-Object Name
```

The copy is complete when `%APPDATA%\VektorSec\runtime\mongodb\bin\mongod.exe` exists.

### 3.3 Option C — keep using servers you already run

Already have MongoDB and Redis (a lab server, a VPS, a Docker host)? Do not install the
portable runtime; point the app at your servers instead. Edit
`%APPDATA%\VektorSec\data\config.toml` with the app closed:

```toml
[database]
mongo_uri = "mongodb://user:password@10.0.0.5:27017/vektorsec?authSource=admin"
mongo_database = "vektorsec"
redis_url = "redis://10.0.0.5:6379"
```

- The file is created on the first launch. If it does not exist yet, start the app once, close
  it, then edit.
- Only values containing `CHANGE_ME` or the Docker host names `mongodb:` / `redis:` are
  rewritten on the next start; a hand-edited URI is left alone.
- To stop the app from launching portable servers on top of yours, add
  `VEKTORSEC_LOCAL_DB=0` to `%APPDATA%\VektorSec\data\.env`.
- Make sure nothing else in your stack fights over the data: one engagement database, one
  `mongo_database` name.

### 3.4 Troubleshooting this step

| Message | Meaning | Fix |
|---|---|---|
| `The argument 'scripts\local-db.ps1' … does not exist` | Relative path from the source repo | Use `"$install\resources\app\scripts\local-db.ps1"` |
| Download fails / proxy error | No direct internet, or a corporate proxy | Use Option B (copy a prepared runtime) |
| `status` says both ports are shut after `install` | The script ran under a different user, or antivirus blocked `mongod.exe` | Re-run it in your own session; whitelist `%APPDATA%\VektorSec\runtime` |
| Port 27017/6379 already in use | Another MongoDB/Redis is running | Either point the app at it (Option C) or stop the other service |
| `mongod.exe` exits immediately, `status` shows 27017 shut, the event log mentions `MSVCP140.dll` / `VCRUNTIME140.dll` | The Microsoft Visual C++ 2015–2022 runtime is missing — MongoDB 7.0 needs it (Redis and VektorSec do not) | Run `%APPDATA%\VektorSec\runtime\mongodb\bin\vc_redist.x64.exe` once, then `local-db.ps1 start`. Offline machine: the same file sits in the MongoDB zip you copied in Option B |

---

## 4. 👤 First launch: accounts, 2FA and the AI model

### 4.1 Launch

Start **VektorSec** from the desktop shortcut (or the Start menu). On a cold start the window
needs **10–20 seconds**: the shell boots the backend on `:8081`, the UI gateway on `:3001`, and
the portable database if it is installed. A white window during that time is normal.

Windows console windows that flash by are the backend/gateway processes — leave them alone;
closing them kills the session.

### 4.2 Accounts

| Path | What to do |
|---|---|
| **Sign up** on the login screen | Creates a normal `user` account with your e-mail and password. Recommended for daily work. |
| **Administrator** | `admin@vektorsec.local` is seeded on the very first launch. Its random password is printed **once** in the log (see below). Use it for admin-panel work. |

```powershell
Select-String -Path "$env:APPDATA\VektorSec\logs\backend.log" -Pattern 'Temporary password'
```

Notes:

- The log line appears only on the first boot. Keep the password somewhere safe — **this build
  has no in-app password change screen**, so a lost admin password means contacting the vendor
  with your HWID (they can reset it for you).
- If you prefer to choose the password up front: close the app, set `[admin] password` in
  `%APPDATA%\VektorSec\data\config.toml`, delete nothing else, and start the app — but this only
  takes effect while no admin account exists yet. An existing admin is never overwritten.

### 4.3 Two-factor authentication (2FA)

The backend default is to **require TOTP enrolment**: after the password, a QR code appears —
scan it with Google Authenticator, Authy or 1Password and enter the 6-digit code once.

On a single-user desktop you can sign in with e-mail + password only:

```powershell
# %APPDATA%\VektorSec\data\.env   (create the file if it does not exist)
Add-Content "$env:APPDATA\VektorSec\data\.env" "`nAUTH_REQUIRE_2FA_SETUP=0"
```

Close and reopen the app. Remove that line to get the QR flow back. Keep 2FA **on** if the
machine is shared, on a VPS, or reachable by other people.

### 4.4 Configure the AI model (required before the first engagement)

VektorSec ships the agent, not the model. You bring a provider key:

1. **Settings → Models**.
2. Add a preset: provider (**OpenAI**, **Anthropic**, or **OpenAI-compatible** with a base URL),
   model name, and your API key.
3. Assign it as **Orchestrator** (the agent that plans and decides).
4. Optional: **Racers** (parallel agents for the same objective) and a **Browser Agent** model.
   The Browser Agent only lists Magnitude-compatible presets; for MiniMax use provider
   *OpenAI-Compatible* with base URL `https://api.minimax.io/v1`.
5. Save. Usage is billed by your provider — VektorSec does not proxy or resell model tokens.

If you skip this, sessions stop with *"No model selected"* / a *Configure Models* prompt.

### 4.5 Other settings worth knowing

| Tab | Purpose |
|---|---|
| **My Account** | Your profile details |
| **Billing** | Plan / license information |
| **Capabilities** | CLI tools and Python packages available on the exploit box |
| **Agent Behavior** | Turn limits, approval policy (human-in-the-loop), safety rails |
| **SSH / Exploit Box** | The Linux box the agent runs commands on (password or private key) |
| **Burp Suite**, **Caido**, **Mythic C2** | Integrations for those tools |
| **Browser Agent** | Display/VNC settings of the headless browser |
| **MCP Access** | Model Context Protocol endpoints |

The UI switches between **Thai and English** at any time from the language selector.

---

## 5. ✅ Verify the installation

With the app window open:

```powershell
# both must return 200
(Invoke-WebRequest http://127.0.0.1:3001 -UseBasicParsing).StatusCode
(Invoke-WebRequest http://127.0.0.1:8081/api/ready -UseBasicParsing).StatusCode

# database status
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" status

# what the backend said on startup
Get-Content "$env:APPDATA\VektorSec\logs\backend.log" -Tail 30
```

A healthy `backend.log` contains the Mongo/Redis connection, the admin bootstrap line (first
run only) and no repeating errors. Endless repeats of `Secret MONGO_URI not found`,
`ECONNREFUSED 127.0.0.1:27017` or `Redis` errors mean §3 is incomplete or your own servers are
unreachable.

Optional end-to-end check: create a workspace, open a session, ask the orchestrator to run
something harmless (`whoami`, `nmap -sV` against a host you are allowed to test) and confirm the
output and the audit-trail entry appear.

---

## 6. 🔑 License, trial and activation

### 6.1 The 15-day trial

| Rule | Detail |
|---|---|
| Length | 15 days per machine, starting at the first launch |
| Requirements | None — no key, no card, no e-mail; every tool works |
| Binding | The machine **HWID**, plus a signed local record, a monotonic clock check and a registry marker |
| Tampering | Editing or deleting those markers is a licence violation; the app shows *"trial data is not valid"* and locks |
| After it ends | Tool APIs answer `402 LICENSE_REQUIRED`; login and `/license` stay reachable so you can activate whenever you like |

The banner on `/license` counts down and warns during the last days. Nothing expires
mid-session: an already running session can finish.

### 6.2 Activating a key

1. **/license → Copy HWID** (the *Machine ID (HWID)* field).
2. Send it to the vendor together with the package you want.
3. Paste the key you receive (**it always starts with `VEKL1.`**) into **License key**.
4. **Activate license**.

What is verified, and why it can fail:

| Check | Failure |
|---|---|
| Ed25519 signature against the vendor's embedded public key | Tampered or hand-made key → rejected |
| HWID equality | Key issued for another machine → *"This key cannot be used on this machine"* |
| Expiry date | Expired key → rejected (renew) |
| Format | Truncated / extra spaces when copy-pasting → rejected |

The check is **offline** — no license server is contacted, so activation works on air-gapped
machines. The key is stored in `%APPDATA%\VektorSec\data\license.key`; keep a copy with your
records.

**Remove key** on `/license` deactivates this machine (for example before transferring a
laptop). The key stays valid for the machine it was issued to.

### 6.3 Renewal and top-up

The *Top Up* panel on `/license` shows the accepted method and the price configured in your
build (USDT — Ethereum ERC-20 — or an invoice, depending on your agreement).

1. Pay the agreed amount to the address shown.
2. Copy the prepared message from the panel — it contains **TxID + HWID + package**.
3. Send it to the vendor ([Telegram @PentestDB](https://t.me/PentestDB)).
4. You receive a new key → **Activate license**.

This build verifies payments **manually**: do not expect the app to detect the transfer and
issue a key by itself. Always store the TxID. A transfer on the wrong network cannot be
recovered.

### 6.4 Moving to another machine, reinstalling

| Situation | Result |
|---|---|
| Reinstall / update on the **same** machine | Same HWID → the existing key keeps working |
| New hardware, or Windows reinstalled | New HWID → request a new key (send the new HWID) |
| Two machines | Two licenses — one key per machine |
| Carry data over | Copy `%APPDATA%\VektorSec` while the app is closed (see §10.3) |

---

## 7. ⚙️ Configuration you can change yourself

Two files in `%APPDATA%\VektorSec\data\` control the app. Both are created automatically on the
first launch; **close the app before editing** and reopen it afterwards.

### 7.1 `config.toml` — server settings

```toml
[server]
port = 8081
deployment = "LOCAL"
base_url_frontend = "http://localhost:3001"
cors_origins = "http://localhost:3001"

[database]
mongo_uri = "mongodb://127.0.0.1:27017/vektorsec"
mongo_database = "vektorsec"
redis_url = "redis://127.0.0.1:6379"

[admin]
email = "admin@vektorsec.local"
password = ""          # only used while no admin account exists yet

[session]
secret = "<generated per install — do not share>"
```

Handy entries:

| Change | How |
|---|---|
| Use your own MongoDB/Redis | Set `mongo_uri` / `redis_url` (§3.3) |
| Backend port | `port` under `[server]` (default 8081) |
| Preset admin e-mail | `[admin] email` before the first launch |

### 7.2 `.env` — optional overrides

Plain `KEY=VALUE` lines. The ones customers actually use:

| Key | Effect |
|---|---|
| `AUTH_REQUIRE_2FA_SETUP=0` | Skip forced TOTP enrolment on this machine (§4.3) |
| `VEKTORSEC_LOCAL_DB=0` | Never start the portable MongoDB/Redis (you run your own) |

> ℹ️ Database settings belong in `config.toml`, not here. The backend reads `config.toml`
> first and only fills keys that are still empty from `.env`, so `MONGO_URI` / `REDIS_URL`
> written into `.env` are ignored while `[database]` in `config.toml` defines them (§3.3).

Your build may already contain vendor-supplied commercial settings in this file (top-up
address, price, contact). **Do not delete lines you did not add** — leave them in place.

Anything else (API base URLs, integration hosts, SSH profiles) belongs in the app's **Settings**
screens, not in these files.

---

## 8. 📂 Files, folders and ports

### 8.1 Everything on disk

| Path | What it holds | Safe to delete? |
|---|---|---|
| `<install>` (default `%LOCALAPPDATA%\Programs\VektorSec`) | Application files, `resources\app\scripts\local-db.ps1`, `Uninstall VektorSec.exe` | Only via the uninstaller |
| `%APPDATA%\VektorSec\data\config.toml` | Server settings, session secret | No — a new secret invalidates open sessions |
| `%APPDATA%\VektorSec\data\.env` | Optional overrides + vendor commercial settings | No |
| `%APPDATA%\VektorSec\data\license.key` | The activation key | No (back it up) |
| `%APPDATA%\VektorSec\data\mongo`, `...\data\redis` | **Your engagements, sessions, findings, reports** | Never, unless you want them gone |
| `%APPDATA%\VektorSec\runtime` | Portable MongoDB/Redis binaries | Yes — reinstalled on demand |
| `%APPDATA%\VektorSec\logs\backend.log`, `frontend.log`, `mongod.log`, `redis.log` | Logs | Yes, when troubleshooting is done |

### 8.2 Ports

| Port | Service | Reachable from |
|---|---|---|
| 3001 | UI gateway (the window) | `127.0.0.1` only |
| 8081 | Backend API | `127.0.0.1` only |
| 27017 | MongoDB | `127.0.0.1` only |
| 6379 | Redis | `127.0.0.1` only |
| 4242 / 4200 / 5901 / 9020 | Optional Kali / VNC / websockify when the sandbox is used | Local container network |

Only `VektorSec.exe` (3001/8081), `mongod.exe` (27017) and `redis-server.exe` (6379) should be
listening. If another program owns 3001 or 8081 the app refuses to start and names the port —
close that program (usually a second VektorSec instance or a dev server) and relaunch.

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3001,8081,27017,6379 |
  Select-Object LocalAddress,LocalPort,OwningProcess
```

---

## 9. 🧯 Troubleshooting

### 9.1 Start here

```powershell
# 1. what did the backend say?
Get-Content "$env:APPDATA\VektorSec\logs\backend.log" -Tail 50

# 2. are the four ports alive?
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3001,8081,27017,6379 |
  Select-Object LocalPort,OwningProcess

# 3. is the database installed and running?
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" status

# 4. license state: open /license in the app
```

### 9.2 Symptom → cause → fix

| Symptom | Cause | Fix |
|---|---|---|
| Double-click does nothing | Stale `ELECTRON_RUN_AS_NODE` environment variable | `Remove-Item Env:ELECTRON_RUN_AS_NODE`, start from the shortcut |
| Blank or frozen window | Cold start (10–20 s), or a busy gateway port | Wait; check 3001; close the owner of the port and relaunch |
| Login: **Gateway upstream error** | Backend down — MongoDB/Redis missing or unreachable | §3; look for `Secret MONGO_URI not found` / `ECONNREFUSED 27017` in `backend.log` |
| Login: wrong password | The admin password was generated, not chosen | `Select-String -Path "$env:APPDATA\VektorSec\logs\backend.log" -Pattern 'Temporary password'`; if the line is gone, ask the vendor to reset (send HWID) |
| A QR code appears at login | Mandatory TOTP enrolment (default) | Scan once, or `AUTH_REQUIRE_2FA_SETUP=0` in `data\.env` + restart (§4.3) |
| Tools answer `402 LICENSE_REQUIRED` | Trial over, or the key does not match this HWID | `/license` → activate a key for this machine (§6.2) |
| *"This key cannot be used on this machine"* | Key issued for another HWID, or truncated on paste | Copy the whole key (`VEKL1.…`), confirm the HWID you sent the vendor |
| Banner: *"trial data is not valid"* | Trial record/marker edited, or the clock moved backwards | The trial cannot be repaired — activate a key |
| No `logs` folder | The backend never started successfully | Keep the app open ~20 s; if it still does not appear, reinstall |
| `EADDRINUSE` on 8081 / 3001 | Another instance is already running | `taskkill /IM VektorSec.exe`, or stop the process owning the port |
| App starts but no model | No preset / no orchestrator assigned | Settings → Models (§4.4) |
| `mongod.exe` quarantined | Heuristic detection of a security tool | Add exclusions for `<install>` and `%APPDATA%\VektorSec` |
| Works, then fails after a reboot | The portable database was not restarted | Launch the app (it starts the DB); or `local-db.ps1 status` / `start` |

### 9.3 Collecting a support bundle

```powershell
$out = "$env:USERPROFILE\Desktop\vektorsec-support.txt"
"=== ports ===" | Out-File $out
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3001,8081,27017,6379 |
  Out-File $out -Append
"=== backend.log (tail) ===" | Out-File $out -Append
Get-Content "$env:APPDATA\VektorSec\logs\backend.log" -Tail 200 | Out-File $out -Append
```

Send that file with your **HWID**, the app version and the SHA-256 of the installer. It contains
log lines, not your engagement data — but skim it before sending.

---

## 10. 🔄 Update, uninstall, move to another machine

### 10.1 Update to a newer version

1. Close VektorSec: close the window (that quits the app and its child processes). If the window
   is gone but the ports are still held, run `taskkill /IM VektorSec.exe`.
2. Back up `%APPDATA%\VektorSec` (copy it somewhere else) — cheap insurance for major versions.
3. Verify the new installer's SHA-256, then run it. It installs over the old version; the data
   folder, the license key and your settings are untouched.
4. Start the app and check the version in `/license` / Settings.

The database (`%APPDATA%\VektorSec\data\mongo`) contains schema migrations that run
automatically on startup — going *back* to an older version is not supported. Keep the previous
installer only for reinstalling the same version.

### 10.2 Uninstall

1. **Settings → Apps → Installed apps → VektorSec → Uninstall**, or run
   `<install>\Uninstall VektorSec.exe`.
2. The uninstaller removes the **application files only**. `%APPDATA%\VektorSec` — your
   engagements, settings and license key — stays where it is, so a later reinstall picks it up
   again. Delete that folder yourself if you want a completely clean removal (the license key is
   lost, but the same key still works on the same machine).
3. The portable database is not removed automatically. To reclaim the space:

```powershell
powershell -ExecutionPolicy Bypass -File "$install\resources\app\scripts\local-db.ps1" stop
Remove-Item "$env:APPDATA\VektorSec\runtime" -Recurse -Force   # only after uninstalling
```

### 10.3 Move to another machine

| Step | Command / action |
|---|---|
| 1. Back up on the old machine | Copy `%APPDATA%\VektorSec` with the app closed |
| 2. Install + database on the new machine | §2 and §3 |
| 3. Copy the data over | Paste the backup into `%APPDATA%\VektorSec` (new machine, app closed) |
| 4. Activate | `/license` → **Copy HWID** → send it to the vendor → new key → **Activate license** |
| 5. Clean up the old machine | `/license` → **Remove key**, then uninstall |

The license key travels with the data folder, but it is bound to the **old** HWID — it will be
rejected on the new machine until you activate the new key. Prefer exporting reports and
re-creating workspaces over copying a live database from a running instance.

---

## 11. 🔐 Security, licensing and EULA

- **Product licence:** Business Source License 1.1 (Licensor **PentestDB**, Change Date
  **2030-11-01**) — the text ships as `<install>\resources\LICENSE`.
- **End-user agreement:** shown by the installer and installed as `<install>\resources\EULA.txt`.
  Accepting it is a condition of use.
- **Allowed:** install and use the app on the number of machines you licensed, for authorized
  security testing.
- **Not allowed:** copying, reselling, renting, sublicensing, patching or repacking the
  application, removing the license check, sharing keys between machines.
- **Key verification:** offline Ed25519 signature + HWID + expiry, verified **fail-closed**. The
  private key never leaves the vendor; a modified binary or key is rejected.
- **Trial integrity:** HWID binding, a signed local record, a monotonic clock check and a
  registry marker. Editing them breaks the app on purpose.
- **Your data:** stays in the local MongoDB on your machine. The vendor receives nothing about
  your engagements; API keys are stored in the app's encrypted Vault, so keep secrets there
  rather than in chat messages.
- **Your responsibility:** you must be authorized to test every target you touch. Scope Guard,
  approval prompts and audit trails are safety aids, not a legal permission.

---

## 12. 📞 Support

| Channel | Use it for |
|---|---|
| [Telegram @PentestDB](https://t.me/PentestDB) | Purchase, renewal, HWID/key issues, installation help |
| [GitHub PentestDB](https://github.com/PentestDB) | Release notes, public documentation |

**Ready-to-send checklist**

1. App version (`/license` or Settings) and installer SHA-256.
2. **HWID** (`/license` → *Copy HWID*).
3. `vektorsec-support.txt` from §9.3 (or the last 200 lines of `backend.log`).
4. Steps you performed, expected result, actual result + screenshot.
5. The exact error text — `Gateway upstream error`, `402 LICENSE_REQUIRED`,
   *"This key cannot be used on this machine"* and similar messages identify the cause fastest.

---

<div align="center">

**VektorSec 1.2.4 — customer build**
PentestDB @ Developer By Raysiya

*Authorized testing only*

</div>
