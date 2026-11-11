# VektorSec — Customer Edition installation guide (Ubuntu / Debian)

> **For the bundle the vendor sends you only** — the file is
> `VektorSec-<version>-customer-linux-x64.tar.gz`. It already contains the application and
> its installer (`install.sh`); nothing is downloaded from git.
> The UI runs in a **browser**, so the server needs no desktop session or display.
>
> ฉบับภาษาไทย: [`INSTALL.md`](INSTALL.md)

```
vektorsec-1.2.7/
├── install.sh                     the installer (OS deps, service, data dirs)
├── README.txt                     one-page summary to read on the server
├── INSTALL.md                     Thai guide
├── INSTALL.en.md                  this guide
├── VERSION
├── systemd/vektorsec.service      the unit that gets installed
├── systemd/vektorsec.env.example  sample settings file (/etc/default/vektorsec)
└── app/                           the application (backend + gateway + headless shell)
```

---

## 1) Requirements

| Item | Needed |
|---|---|
| OS | Ubuntu **20.04 / 22.04 / 24.04** or Debian 11+ (x86_64) with `systemd` and `apt` · Kali/Parrot (Debian testing) and Ubuntu derivatives (Mint, Pop!_OS) automatically use the closest published MongoDB build |
| Privileges | `root` (`sudo`) |
| Ports | **3001/tcp** reachable from your LAN (changeable with `--port`) |
| Resources | RAM ≥ 4 GB, ≥ 5 GB free disk |
| Databases | MongoDB 7.0 + Redis — installed automatically, or reuse your own / Atlas |
| Internet | Only for installing dependencies (Node 22 / MongoDB / Redis) and for online activation |

> **Offline server**: pre-install Node.js ≥ 22, MongoDB and Redis, then run
> `sudo bash install.sh --no-deps`.

---

## 2) Install

```bash
# 1) copy the bundle to the server (run this on your own machine)
scp VektorSec-1.2.7-customer-linux-x64.tar.gz user@SERVER:/tmp/

# 2) verify the download (the .sha256 file ships next to the tarball)
cd /tmp
sha256sum -c VektorSec-1.2.7-customer-linux-x64.tar.gz.sha256

# 3) unpack and install
tar xzf VektorSec-1.2.7-customer-linux-x64.tar.gz
cd vektorsec-1.2.7
sudo bash install.sh
```

The last line says **`backend พร้อมใช้งาน — GET http://127.0.0.1:3001/api/ready = 200`**
("the backend is ready") followed by every URL that other machines can use.

> `install.sh` does not stop at "the web page loads": it waits until `GET /api/ready`
> answers **200**, which means the backend, MongoDB and Redis are actually serving
> (240 s by default — override with `VEKTORSEC_READY_TIMEOUT=600 sudo -E bash install.sh`).
> On timeout it prints the log you need and **exits with an error** instead of declaring
> success — because while the backend is still down, every **Create account / Login**
> attempt is answered with `Gateway upstream error`.

### `install.sh` options

| Command | Meaning |
|---|---|
| `sudo bash install.sh` | Full install: Node 22 + MongoDB 7.0 + Redis + service + auto-start |
| `sudo bash install.sh --no-deps` | Application only (use the Node/Mongo/Redis you already run) |
| `sudo bash install.sh --port 8080` | Different UI port (also written to `/etc/default/vektorsec`) |
| `bash install.sh --help` | Show all options |

### What the installer does

1. Preflight: root, systemd, apt, architecture, prints the detected OS
2. Installs **Node.js 22** from NodeSource when missing or too old
3. Installs **MongoDB 7.0** (official repo) and **Redis**, then enables both services
4. Creates the system user **`vektorsec`** (no home, no login shell)
5. Installs the application to `/opt/vektorsec/app` (stops the old service first)
6. Prepares state in `/var/lib/vektorsec/{data,logs}` — **existing data is never overwritten**
7. Installs `/etc/systemd/system/vektorsec.service` and `/etc/default/vektorsec` (if absent)
8. Opens port 3001 in `ufw` (when ufw is active) and `systemctl enable`s the service
9. Restarts the service and waits up to **240 s** for **`GET /api/ready` to answer 200** — i.e. the backend + MongoDB + Redis really serving, not just the web page; on failure it prints `backend.log`, the journal and the `mongod`/`redis-server` state, then exits with an error

### Installed paths

| Path | What it is |
|---|---|
| `/opt/vektorsec/app` | The application (not writable by the service — upgrades run as root) |
| `/opt/vektorsec/{README.txt,INSTALL.md,INSTALL.en.md}` | Documentation + installed version (`VERSION`) |
| `/var/lib/vektorsec/data` | `config.toml`, `.env`, **`license.key`** ← your activation lives here |
| `/var/lib/vektorsec/logs` | `backend.log`, `frontend.log` |
| `/etc/systemd/system/vektorsec.service` | The service unit |
| `/etc/default/vektorsec` | Settings (port, bind address, MONGO_URI…) — created once |

---

## 3) First start

Open a browser at

```
http://<this-host-ip>:3001      # from another machine on the LAN
http://localhost:3001           # on the server itself
```

Don't know the IP? `hostname -I`, or read the list printed by
`sudo journalctl -u vektorsec -n 40 --no-pager`.

> **The app is not usable until it is activated** — the first screen is the **Activate VektorSec**
> panel (HWID to copy + the Discord/Telegram/Facebook links). Registration and sign-in stay closed
> until this machine's key is pasted (see §4). That is the intended behaviour, not a broken install.

### Administrator account

On first boot the backend creates one admin account:

* email: **`admin@vektorsec.local`** (unless `ADMIN_EMAIL` is set)
* password: **randomly generated and printed to the log once**

```bash
sudo grep -a "Temporary password" /var/lib/vektorsec/logs/backend.log
```

> To pick your own credentials, put `ADMIN_EMAIL=` / `ADMIN_PASSWORD=` in
> `/var/lib/vektorsec/data/.env` **before** the first start. An existing admin is never touched.

After the first login: **change the password immediately** and enable 2FA (TOTP) in Settings.

---

## 4) License — HWID and how keys are issued (read this)

### 4.1 Paid license only (there is no free trial)

* This bundle has **no free trial and does not accept a `--type trial` key** (Windows
  follows the same rule). `/license` shows a red **"License required"** notice with
  this machine's HWID and the Discord / Telegram / Facebook links.
* `/login` and `/register` look normal but cannot be used: a **full-screen popup that
  cannot be dismissed** covers the form, showing the HWID + a copy button, the same
  three channels and a "I already have a key → `/license`" link. Signing in or
  registering stays impossible until a paid key is activated (the popup re-checks
  `/api/license/state` every 8 seconds and lifts itself).
* To get a license:
  1. Copy the HWID from `/license` (`Copy HWID`, or `Copy HWID + request` for a ready-made message).
  2. Join all three channels: https://discord.gg/kVgAMFAY5 , https://t.me/PentestDB ,
     https://www.facebook.com/groups/developerpt
  3. Send the HWID to the vendor (or the payment confirmation) and receive a **paid** key
     (`--type 30d|60d|1y`) back.
  4. Paste that key on `/license` and press Activate - the 30 days count from the activation.
* Until the key arrives the verdict is `trial-registration-required` and the tools
  stay locked (deliberate: a machine must not grant itself access). `/license`,
  `GET /api/license/state` and the backend log all repeat the HWID and the channel links:
  a pasted trial key answers `trial-key-not-allowed`.
* Time is measured by a **trusted clock, not by the machine's clock**, so editing
  the system time or the timezone buys no extra days, and tampering with the local record
  yields `trial-tampered`.
* The trial record is signed, and a **second copy lives outside this directory** —
  `/var/lib/vektorsec/.license-trial.anchor` (plus `~/.local/state/vektorsec/` when the state
  directory is under a home directory) — so deleting `/var/lib/vektorsec/data` (or unpacking the
  bundle again) does **not** restart the 15 days: the app answers `marker-only` and asks for a key.
  On Windows the same job is done by `HKCU\Software\VektorSec`.
* When it ends, every tool answers `402 LICENSE_REQUIRED` and the UI sends you to `/license`.

### 4.2 The model: the license is bound to this machine's HWID, and **only the vendor issues keys**

Exactly like the Windows edition:

```
Customer                                    Vendor (Raysiya)
────────                                    ────────────────
1. open http://<host>:3001/license
2. the page shows the Machine ID (HWID)
   → click "Copy HWID"
3. send the HWID + company/package ───────► 4. the vendor mints the key on their own machine
   (https://t.me/PentestDB)                   node scripts/gen-unlock-token.js --license …
                                              (the private key never ships to you)
5. paste the key on /license      ◄──────     vendor sends the key (VEKL1.…) back
   → "Activate license"
```

* One key works on **one HWID** — it cannot be reused on another machine
* **One activation = 30 days** counted from the activation day; a **new** key adds another 30 days
  (terms never stack); re-pasting the same key does not restart the window
* The key is stored in `/var/lib/vektorsec/data/license.key` —
  **upgrading/reinstalling keeps it, no re-activation needed**

### 4.3 Customer steps (once per machine)

1. Open `http://<IP>:3001/license`
2. In the **Machine ID (HWID)** box click **“Copy HWID”**
3. Send a message with
   * the HWID (`HWID-XXXX-XXXX-XXXX-XXXX`)
   * company name + contact person
   * the package you want (30 days / 60 days / 1 year / unlimited)
   * the installed version: `cat /opt/vektorsec/VERSION`
4. You receive a key (it starts with `VEKL1.`) → paste it on the same page →
   **“Activate license”**
5. Check that the status bar now says the license is active with N days left

### 4.4 Vendor steps — minting a key (vendor machine only)

```bash
# once, on the vendor machine: create the master (Ed25519) key pair
node scripts/gen-unlock-token.js --init-keys

# mint a key bound to the customer's HWID
node scripts/gen-unlock-token.js --license --client "Acme Co., Ltd." \
    --type 30d --hwid HWID-ABCD-1234-5678-90EF

# options
#   --type 30d | 60d | 1y | unlimited   (`trial` keys are for the maintainer build / QA only —
#                                        a customer build refuses them: `trial-key-not-allowed`)
#   --expires 2026-12-31       hard expiry baked into the key (not for unlimited)
#   --client "name"            baked into the key, for later lookups

# check a key before sending it
node scripts/gen-unlock-token.js --verify "VEKL1…" --hwid HWID-ABCD-1234-5678-90EF
```

* Issued-key history: `<DATA_DIR>/license-issued.jsonl` (the vendor's **Admin → License Keys**
  page reads the same file) — use it to look a key up or re-issue one the customer lost
* The public key is embedded in the build (`backend/src/utils/drm/embeddedKey.ts`), so keys are
  verified **offline**
* **The private key is never part of the bundle**, therefore Admin → License Keys on a customer
  install cannot mint keys
* Losing/rotating the master key means re-issuing the public key and rebuilding the bundle

### 4.5 Where the HWID comes from (and when a new key is needed)

The HWID is derived from hardware identifiers — on Linux `/etc/machine-id` together with the
DMI / board serial values.

| Situation | HWID | New key needed? |
|---|---|---|
| Upgrading VektorSec in place (`sudo bash install.sh` with a newer bundle) | unchanged | No — `license.key` stays |
| `systemctl restart` / reboot | unchanged | No |
| Full VM clone (carries `/etc/machine-id` + the same SMBIOS) | unchanged | No |
| OS reinstall / new VM / moving to another machine | **changes** | **Yes** — send the new HWID so the vendor can mint a key |

> Recommended: activate on the machine that will actually run it, and avoid regenerating
> `/etc/machine-id` (`systemd-machine-id-setup`, “new machine-id” style clones) afterwards.

### 4.6 Moving / transferring a license

Send the vendor the **new HWID + the old HWID**; a new key is minted (the old key keeps working
on the old machine until it expires).

---

## 5) Common commands

```bash
sudo systemctl status vektorsec          # status + recent log lines
sudo systemctl restart vektorsec         # restart (needed after editing /etc/default/vektorsec)
sudo systemctl stop vektorsec            # stop temporarily
sudo journalctl -u vektorsec -f          # live service log
tail -f /var/lib/vektorsec/logs/backend.log    # backend log
tail -f /var/lib/vektorsec/logs/frontend.log   # gateway/UI log
node /opt/vektorsec/app/electron/headless.js --check   # resolved ports/paths
ss -ltnp | grep 3001                     # is the UI port open, and by whom
cat /opt/vektorsec/VERSION               # installed version
```

> `journalctl` shows the service's own messages; the backend/gateway output (including the
> one-time temporary admin password) goes to the files under `/var/lib/vektorsec/logs`.

---

## 6) Files, ports and settings

| Value | Default | Where to change |
|---|---|---|
| UI port (browser) | `3001` | `FRONTEND_PORT` in `/etc/default/vektorsec` |
| UI bind address | `0.0.0.0` (LAN reachable) | `FRONTEND_HOSTNAME` (use `127.0.0.1` behind nginx/Caddy) |
| Backend port | `8081`, loopback only | `PORT` — **never expose it** |
| MongoDB | `mongodb://127.0.0.1:27017/vektorsec` | `MONGO_URI` |
| Redis | `redis://127.0.0.1:6379` | `REDIS_URL` |
| state / data / logs | `/var/lib/vektorsec` | `VEKTORSEC_USER_DATA_DIR`, `DATA_DIR` |
| proxy headers | off | `VEKTORSEC_TRUST_PROXY=1` (only behind your own proxy) |

Every change in `/etc/default/vektorsec` needs a restart:

```bash
sudoedit /etc/default/vektorsec
sudo systemctl restart vektorsec
```

> Nothing in that file can weaken the DRM — the trusted clock, the trial anchor and hard license
> enforcement are pinned by the application itself (`electron/backend-runner.js`, `packaged: true`).
> The file only decides *where the app listens* and *which databases it uses*.

---

## 7) Security

* Publish only the UI port (`3001/tcp`) to your LAN — **never** expose `8081`, `27017`, `6379`
* Want HTTPS? Put nginx/Caddy in front of 3001 (see `deploy/nginx.example.conf`), then set
  `FRONTEND_HOSTNAME=127.0.0.1` and `VEKTORSEC_TRUST_PROXY=1`
* `/var/lib/vektorsec/data` is sensitive (`license.key`, session secret) — mode `0750`, owned by `vektorsec`
* `/var/lib/vektorsec/.license-trial.anchor` is the trial anchor — do not copy it to another machine
  (it is HWID-bound and only proves *this* box already used its 15 days)
* The anti-tamper addon (`backend/native`, `drm_addon.node`) is compiled on the build machine for
  its own platform (`npm run build:native`, MSVC on Windows, `build-essential` on Ubuntu). When it is
  absent the JS collector takes over: the licence still verifies, **but no trial is granted at all** —
  the MAC key would fall back to `HARDWARE_ID_SALT`, which ships inside the very bundle the customer
  can read (i.e. they could sign their own record and never run out of trial days). The build therefore
  answers `reason: "trial-signing-unavailable"` and keeps the tools locked until a license key is
  entered (or `VEKTORSEC_LICENSE_SERVER_URL` lets the license server hand out the window).
  `scripts/package-linux-customer.mjs` **refuses to build** a bundle without the ELF addon; an
  intentional key-only edition needs `--allow-js-trial`
* Change the admin password on day one and enable 2FA; do not reuse another system's password
* The code in `/opt/vektorsec` is read-only for the service, so a compromised process cannot edit it

---

## 8) Backup, upgrade, uninstall

### Backup (before every upgrade)

```bash
sudo tar czf ~/vektorsec-data-$(date +%F).tar.gz -C /var/lib/vektorsec data
```

Keep that file: it holds `config.toml`, `.env` and **`license.key`** (restoring it avoids a
re-activation).

### Upgrade (no data loss, no license loss)

```bash
tar xzf VektorSec-<new-version>-customer-linux-x64.tar.gz
cd vektorsec-<new-version>
sudo bash install.sh
```

The installer stops the service, replaces `/opt/vektorsec/app` and starts again **without touching
`/var/lib/vektorsec`**, so your `license.key`, admin account and data survive.

> **Node must be visible to systemd**: the unit runs `ExecStart=/usr/bin/env node`, so the service user
> (`vektorsec`) needs `node` in `/usr/local/bin` or `/usr/bin`. If you installed Node with **nvm**
> (`/root/.nvm/...`) the service cannot see it - and cannot read `/root` either - and the unit dies with
> `env: 'node': No such file or directory`. Copy it system-wide (a symlink into `/root` is not enough):
> `sudo install -m 0755 "$(readlink -f "$(command -v node)")" /usr/local/bin/node` then
> `sudo systemctl restart vektorsec`. On Kali prefer `sudo bash install.sh --no-deps`: with Node >= 22
> on root's PATH the script skips NodeSource by itself, but below that it pulls Node 22 from NodeSource,
> which rejects `kali-rolling` (the MongoDB repo it adds is the Debian one too).

### Uninstall

```bash
sudo systemctl disable --now vektorsec
sudo rm -f /etc/systemd/system/vektorsec.service
sudo systemctl daemon-reload
sudo rm -rf /opt/vektorsec
# delete all state (including license.key) — only when you really mean it
sudo rm -rf /var/lib/vektorsec /etc/default/vektorsec
sudo userdel vektorsec 2>/dev/null || true
```

> MongoDB / Redis installed by the script stay behind — remove them with
> `sudo apt-get remove --purge mongodb-org redis-server` if nothing else needs them.

---

## 9) Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Installer says the service died while waiting | `sudo journalctl -u vektorsec -n 80 --no-pager` and `tail -50 /var/lib/vektorsec/logs/backend.log` — usually MongoDB not up yet (`systemctl status mongod`) or a wrong `MONGO_URI` |
| `install.sh` never sees `GET /api/ready` = 200 within 240 s | The script already printed `backend.log` + journal before exiting: check `systemctl status mongod redis-server` · `ss -ltnp \| grep -E '3001\|8081\|27017\|6379'` (port taken?) · retry with `--port 8080` |
| **Create account / Login** shows **`Gateway upstream error`** | The gateway (`:3001`) is answering for a backend (`:8081`) that is not ready — check `curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/api/ready` (must be `200`; `502` = backend not running) · `tail -50 /var/lib/vektorsec/logs/backend.log` (look for `Secret MONGO_URI not found` / `REDIS_URL not found`) · `systemctl status mongod redis-server` · then `sudo systemctl restart vektorsec` (this installer already waits for readiness before it reports success) |
| `systemctl status mongod` says **“Unit mongod.service could not be found”** | MongoDB was never installed on this machine (older `install.sh` only warned and carried on), so the backend has no database and the UI answers `Gateway upstream error` every time · install it: `sudo apt-get install -y curl gnupg` · `curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \| sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg` · `echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \| sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list` · `sudo apt-get update && sudo apt-get install -y mongodb-org` · `sudo systemctl enable --now mongod` · then re-run `sudo bash install.sh` (same bundle, no need to unpack again) — or point `MONGO_URI` in `/etc/default/vektorsec` at another MongoDB/Atlas cluster |
| `sudo apt-get install -y mongodb-org` says **“E: Unable to locate package mongodb-org”** | apt does not know the MongoDB repo — the keyring or the repo file was never written completely (or `apt-get update` failed) · check `cat /etc/apt/sources.list.d/mongodb-org-7.0.list` and `stat -c %s /usr/share/keyrings/mongodb-server-7.0.gpg` (must be more than 0 bytes) · `sudo apt-get update 2>&1 \| grep -iE 'mongo\|^E:\|^W:'` · if there is no `deb ...` line, rewrite it with the commands in the row above and run `sudo apt-get update` · confirm apt can see it: `apt-cache policy mongodb-org-server` must show `Candidate: 7.0.x` (`(none)` means the repo is not being read) · if it is visible but the install still fails, take just the server: `sudo apt-get install -y mongodb-org-server` · on a network that blocks `repo.mongodb.org`, run Docker (`docker run -d --name mongo -p 27017:27017 mongo:7`) or use Atlas and set `MONGO_URI` |
| `apt-get update` says **“Signature verification failed … SHA1 is not considered secure since 2026-02-01”** or **“The repository … is not signed”** | Newer apt (Debian 13 / Kali 2026) verifies signatures with `sqv` (Sequoia), whose policy rejects MongoDB's key because its binding signatures are still SHA‑1 → apt disables the repo, so the package is “not found” even though the repo file and keyring are correct · quickest way — same repo, no signature check (still HTTPS): `echo "deb [trusted=yes] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \| sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list` · `sudo apt-get update` · `sudo apt-get install -y mongodb-org-server` · `sudo systemctl enable --now mongod` · or fetch the `.deb` straight from the repo: `BASE=https://repo.mongodb.org/apt/debian` · `F=$(curl -fsS "$BASE/dists/bookworm/mongodb-org/7.0/main/binary-amd64/Packages" \| awk '/^Package: mongodb-org-server$/{f=1} f&&/^Filename:/{print $2; exit}')` · `curl -fsSLO "$BASE/$F"` · `sudo apt-get install -y ./$(basename "$F")` — the current `install.sh` tries `trusted=yes` and then the `.deb` automatically · note: the 8.0 repo's key is SHA‑512 and does pass `sqv`, but this backend pins `mongoose 7` (driver 5), which supports servers only up to 7.0 — do not switch to 8.0 to solve this · **the step-by-step version is the section “If Kali / Debian 13 rejects MongoDB's key” below the table** |
| `mongod` is installed but dies immediately (`Illegal instruction`) | The CPU lacks **AVX**, which MongoDB 5.0+ requires → use MongoDB on another machine/Atlas and set `MONGO_URI` (or run MongoDB in Docker on a machine that supports it) |
| 502 / broken pages after an upgrade | `sudo systemctl restart vektorsec`, then read `frontend.log`; if it persists, reinstall with the same bundle |
| Cannot log in / forgot the admin password | First run: search `backend.log` for `Temporary password`. Otherwise contact the vendor (they have a reset procedure) |
| `/license` says the key does not work on this machine | HWID mismatch (different machine) or the key expired — send the HWID from `/license` so the vendor can check/re-issue |
| Every tool answers `402 LICENSE_REQUIRED` | Nothing is activated yet, or the key expired → enter a key on `/license` |
| State shows `trial-tampered` | The local record was edited/deleted or the clock was rolled → a paid license key is required |
| State shows `trial-signing-unavailable` | This package shipped without `drm_addon.node`, so no trial is granted (its records would be forgeable) → reinstall from the official package, or enter a license key |
| State shows `trial-registration-required` | This edition has no free trial: copy the HWID from `/license`, join the Discord/Telegram/Facebook channels, send the HWID to the vendor and activate the paid key (`--type 30d|60d|1y`) they send back |
| State shows `trial-key-not-allowed` | A trial key (`--type trial`) was pasted; customer builds do not accept it → use the paid key (`--type 30d|60d|1y`) issued for this HWID |
| New port not reachable | `systemctl restart vektorsec` **and** open the new port in the firewall |
| What values is the app using? | `node /opt/vektorsec/app/electron/headless.js --check` |

### If Kali / Debian 13 rejects MongoDB's key (`is not signed` / `SHA1 is not considered secure`)

**Symptom** — `sudo apt-get update` answers something like:

```text
W: Signature verification failed: https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 InRelease:
   Sub-process /usr/bin/sqv returned an error code (1), error message is:
   Signing key on E58830201F7DD82CD808AA84160D26BB1785BA38 is not bound:
   No binding signature at time 2026-11-02T17:01:03Z   because: Policy rejected
   non-revocation signature (PositiveCertification) requiring second pre-image
   resistance   because: SHA1 is not considered secure since 2026-02-01T00:00:00Z
E: The repository 'https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 InRelease' is not signed.
```

and then `apt-cache policy mongodb-org-server` → `N: Unable to locate package mongodb-org-server`,
`apt-get install -y mongodb-org` → `E: Unable to locate package mongodb-org`,
`systemctl enable --now mongod` → `Failed to enable unit: Unit mongod.service does not exist`

**Cause** — newer apt (Debian 13 / Kali 2026 / recent Parrot) verifies signatures with `sqv` (Sequoia),
whose policy says **SHA‑1 is not acceptable since 2026‑02‑01**. MongoDB's 7.0 key still signs itself
with SHA‑1, so `sqv` treats the key as “not bound”, apt disables the repo — even though
`/etc/apt/sources.list.d/mongodb-org-7.0.list` and `/usr/share/keyrings/mongodb-server-7.0.gpg` are
both correct (`Release` downloads with HTTP 200, `InRelease` fails verification). This is **not** a
wrong-codename problem in the repo line.

**Option 1 — keep the same repo as `[trusted=yes]` (fastest; still downloads over MongoDB's HTTPS)**

```bash
# 1) rewrite the repo file: no signature check, same HTTPS origin
echo "deb [trusted=yes] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# 2) refresh the index — there must be no E: line mentioning repo.mongodb.org
sudo apt-get update

# 3) must print Candidate: 7.0.x   (still (none) means this option did not work — use option 2)
apt-cache policy mongodb-org-server

# 4) take the server only (the mongodb-org metapackage drags in mongos/tools, which often
#    fail to resolve on derivatives)
sudo apt-get install -y mongodb-org-server

# 5) enable the unit and confirm it listens
sudo systemctl enable --now mongod
systemctl status mongod --no-pager | head -5
ss -ltnp | grep 27017
```

**Option 2 — fetch the `.deb` straight from the repo (no apt signature check involved)**

```bash
BASE=https://repo.mongodb.org/apt/debian
F=$(curl -fsS "$BASE/dists/bookworm/mongodb-org/7.0/main/binary-amd64/Packages" \
    | awk '/^Package: mongodb-org-server$/{f=1} f&&/^Filename:/{print $2; exit}')
curl -fsSLO "$BASE/$F"
sudo apt-get install -y "./$(basename "$F")"   # apt still resolves deps from the Kali/Debian mirrors
sudo systemctl enable --now mongod
```

On ARM replace `binary-amd64` with `binary-arm64`.

**Verify the whole stack is back**

```bash
sudo systemctl restart vektorsec
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/api/ready   # must be 200
```

**Notes**

- The current `install.sh` already tries this automatically, in order: signed repo → `[trusted=yes]` → direct `.deb`. If an earlier run failed, just re-run `sudo bash install.sh` with the same bundle.
- Do **not** “fix” this by moving to the 8.0 repo: its key is SHA‑512 and does pass `sqv`, but this backend pins `mongoose 7` (driver 5), which supports servers only up to 7.0.
- If you would rather not run MongoDB on this machine: Docker (`docker run -d --name mongo -p 27017:27017 mongo:7`) or MongoDB Atlas, then set `MONGO_URI` in `/etc/default/vektorsec`.

---

## 10) Contact / licensing

Send the following to **https://t.me/PentestDB**

1. the **HWID** from `/license` (use “Copy HWID”)
2. company name + contact person
3. the package you want (30 days / 60 days / 1 year / unlimited)
4. version + OS: `cat /opt/vektorsec/VERSION` · `grep PRETTY_NAME /etc/os-release`

> License keys are minted by the vendor only (same as the Windows edition) — a customer install
> cannot create keys.
