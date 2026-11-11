# คู่มือติดตั้ง VektorSec — Customer Edition (Ubuntu / Debian)

> **สำหรับชุดติดตั้งที่ผู้ขายส่งให้เท่านั้น** — ไฟล์ `VektorSec-<version>-customer-linux-x64.tar.gz`
> ภายในมีแอปพร้อมตัวติดตั้ง (`install.sh`) ไม่ต้องโหลดโค้ดจากอินเทอร์เน็ต
> UI เปิดผ่าน **browser** จึงไม่ต้องมีจอหรือเดสก์ท็อปบนเครื่อง server
>
> English version: [`INSTALL.en.md`](INSTALL.en.md)

```
vektorsec-1.2.7/
├── install.sh                     ตัวติดตั้ง (ระบบ, service, data dir)
├── README.txt                     สรุปสั้นสำหรับเปิดอ่านบน server
├── INSTALL.md                     เอกสารนี้ (ไทย)
├── INSTALL.en.md                  คู่มือภาษาอังกฤษ
├── VERSION
├── systemd/vektorsec.service      unit ที่จะถูกติดตั้ง
├── systemd/vektorsec.env.example  ตัวอย่างไฟล์ตั้งค่า (/etc/default/vektorsec)
└── app/                           ตัวแอป (backend + gateway + headless shell)
```

---

## 1) สิ่งที่ต้องเตรียม

| รายการ | ต้องการ |
|---|---|
| ระบบปฏิบัติการ | Ubuntu **20.04 / 22.04 / 24.04** หรือ Debian 11+ (x86_64) — ต้องมี `systemd` และ `apt` · Kali/Parrot (Debian testing) และดิสโทรที่สืบจาก Ubuntu (Mint, Pop!_OS) ใช้ package MongoDB ของชุดที่ใกล้ที่สุดให้อัตโนมัติ |
| สิทธิ์ | `root` (`sudo`) |
| พอร์ต | **3001/tcp** เปิดให้เครื่องอื่นในวงเข้าถึง (เปลี่ยนได้ด้วย `--port`) |
| ทรัพยากร | RAM ≥ 4 GB, ดิสก์ว่าง ≥ 5 GB |
| ฐานข้อมูล | MongoDB 7.0 + Redis — สคริปต์ติดตั้งให้อัตโนมัติ หรือใช้ตัวที่มีอยู่/Atlas |
| อินเทอร์เน็ต | ใช้ตอนติดตั้ง dependency (Node 22 / MongoDB / Redis) และตอน online activation |

> ถ้าเครื่องลูกค้า **ไม่มีอินเทอร์เน็ต**: เตรียม Node.js ≥ 22, MongoDB และ Redis ไว้ก่อน
> แล้วติดตั้งด้วย `sudo bash install.sh --no-deps`

---

## 2) ติดตั้ง

```bash
# 1) คัดลอกชุดติดตั้งขึ้นเครื่อง (ทำจากเครื่องของคุณ)
scp VektorSec-1.2.7-customer-linux-x64.tar.gz user@SERVER:/tmp/

# 2) (ถ้ามีไฟล์ .sha256 แนบมา) ตรวจความถูกต้องก่อน
cd /tmp
sha256sum -c VektorSec-1.2.7-customer-linux-x64.tar.gz.sha256

# 3) แตกไฟล์และติดตั้ง
tar xzf VektorSec-1.2.7-customer-linux-x64.tar.gz
cd vektorsec-1.2.7
sudo bash install.sh
```

ติดตั้งเสร็จจะเห็นบรรทัดสุดท้ายว่า  
**`backend พร้อมใช้งาน — GET http://127.0.0.1:3001/api/ready = 200`** พร้อมรายการ URL ที่เปิดได้จากเครื่องอื่น

> `install.sh` ไม่ได้หยุดแค่ “หน้าเว็บขึ้น” — มันรอจนกว่า `GET /api/ready` ตอบ 200
> ซึ่งหมายถึง backend + MongoDB + Redis พร้อมจริง (ระยะเวลา 240 วินาที ปรับได้ด้วย
> `VEKTORSEC_READY_TIMEOUT=600 sudo -E bash install.sh`)
> ถ้าเกินเวลาจะพิมพ์ log ที่ต้องดูแล้ว **จบด้วย error** (ไม่บอกว่าเสร็จทั้งที่ยังใช้ไม่ได้)
> เพราะถ้า backend ยังไม่พร้อม ทุกครั้งที่กด **Create account / Login** จะขึ้น
> `Gateway upstream error`

### ตัวเลือกของ `install.sh`

| คำสั่ง | ความหมาย |
|---|---|
| `sudo bash install.sh` | ติดตั้งครบ: Node 22 + MongoDB 7.0 + Redis + service + เปิด auto-start |
| `sudo bash install.sh --no-deps` | ติดตั้งเฉพาะแอป (ใช้ Node/Mongo/Redis ที่มีอยู่แล้ว) |
| `sudo bash install.sh --port 8080` | เปลี่ยนพอร์ต UI (เขียนลง `/etc/default/vektorsec` ให้ด้วย) |
| `bash install.sh --help` | แสดงตัวเลือกทั้งหมด |

### สิ่งที่สคริปต์ทำ

1. ตรวจเครื่อง (root, systemd, apt, สถาปัตยกรรม) และพิมพ์ชื่อระบบ
2. ติดตั้ง **Node.js 22** จาก NodeSource ถ้ายังไม่มี/เวอร์ชันเก่ากว่า
3. ติดตั้ง **MongoDB 7.0** (repo ทางการ) และ **Redis** แล้วเปิด service ทั้งสอง
4. สร้าง system user **`vektorsec`** (ไม่มี home, ไม่มี login shell)
5. ติดตั้งแอปที่ `/opt/vektorsec/app` (หยุด service เดิมก่อนอัปเดตทุกครั้ง)
6. เตรียม state ที่ `/var/lib/vektorsec/{data,logs}` **(ไม่เขียนทับข้อมูลเดิม)**
7. ติดตั้ง unit `/etc/systemd/system/vektorsec.service` + `/etc/default/vektorsec` (ถ้ายังไม่มี)
8. เปิดพอร์ต 3001 ใน `ufw` (ถ้า ufw ทำงานอยู่) และ `systemctl enable` ให้เปิดเองตอนบูต
9. `restart` service แล้วรอ **`GET /api/ready` ตอบ 200** ไม่เกิน **240 วินาที** (backend + MongoDB + Redis พร้อมจริง ไม่ใช่แค่หน้าเว็บขึ้น) — ถ้าไม่ผ่านจะพิมพ์ `backend.log`, journal และสถานะ `mongod`/`redis-server` แล้วจบด้วย error

### พาธที่ติดตั้ง

| พาธ | คืออะไร |
|---|---|
| `/opt/vektorsec/app` | ตัวแอป (service เขียนไม่ได้ — อัปเกรดด้วย root เท่านั้น) |
| `/opt/vektorsec/{README.txt,VERSION}` | เอกสารและเวอร์ชันที่ติดตั้งอยู่ |
| `/var/lib/vektorsec/data` | `config.toml`, `.env`, **`license.key`** ← หัวใจของ license |
| `/var/lib/vektorsec/logs` | `backend.log`, `frontend.log` |
| `/etc/systemd/system/vektorsec.service` | unit ของ service |
| `/etc/default/vektorsec` | ไฟล์ตั้งค่า (พอร์ต, bind, MONGO_URI…) — สร้างครั้งแรกครั้งเดียว |

---

## 3) เปิดใช้งานครั้งแรก

เปิด browser ไปที่

```
http://<IP-ของเครื่องนี้>:3001        # จากเครื่องอื่นในวง LAN
http://localhost:3001                # บนเครื่อง server เอง
```

ถ้าไม่รู้ IP: `hostname -I` หรือดูรายการที่ `sudo journalctl -u vektorsec -n 40 --no-pager`

> **แอปยังไม่เปิดให้ใช้งานจนกว่าจะ activate** — หน้าแรกที่เห็นคือแผง **Activate VektorSec**
> (มี HWID ให้คัดลอก + ลิงก์ Discord/Telegram/Facebook) การสมัครสมาชิก/เข้าสู่ระบบจะยังไม่ทำงาน
> จนกว่าจะใส่คีย์ของเครื่องนี้ (ดูข้อ 4) นี่คือพฤติกรรมที่ตั้งใจไว้ ไม่ใช่ระบบเสีย

### บัญชีผู้ดูแลระบบ (admin)

ครั้งแรกที่ backend เริ่มทำงาน ระบบจะสร้าง admin ให้ 1 บัญชี

* อีเมล: **`admin@vektorsec.local`** (ถ้าไม่ได้กำหนด `ADMIN_EMAIL`)
* รหัสผ่าน: **สุ่มขึ้นมาแล้วพิมพ์ใน log ครั้งเดียว** — หาได้ด้วย

```bash
sudo grep -a "Temporary password" /var/lib/vektorsec/logs/backend.log
```

> อยากกำหนดเองตั้งแต่แรก: ใส่ `ADMIN_EMAIL=` / `ADMIN_PASSWORD=` ใน
> `/var/lib/vektorsec/data/.env` **ก่อน** start service ครั้งแรก
> (ถ้ามี admin อยู่แล้ว ระบบจะไม่แตะบัญชีเดิม)

หลัง login ครั้งแรก: **เปลี่ยนรหัสผ่านทันที** และเปิด 2FA (TOTP) ในหน้า Settings

---

## 4) License — HWID และการขอ key (สำคัญ)

### 4.1 License จ่ายเงินเท่านั้น (ไม่มีช่วงทดลองใช้ฟรี)

* ชุดนี้ **ไม่มีช่วงทดลองใช้ฟรี และไม่รับคีย์ `--type trial`** (ทั้ง Windows และ Ubuntu ใช้กติกาเดียวกัน) —
  หน้า `/license` จะขึ้นข้อความสีแดง `License required` พร้อม HWID ของเครื่องและลิงก์กลุ่ม
  Discord / Telegram / Facebook
* หน้า `/login` และ `/register` ยังเห็นฟอร์มอยู่ แต่มี **ป๊อปอัปบล็อกเต็มหน้าจอ (กดปิดไม่ได้)**
  แสดง HWID + ปุ่มคัดลอก + ลิงก์กลุ่มเดียวกัน และลิงก์ “มีคีย์แล้ว → `/license`” —
  ล็อกอิน/สมัครไม่ได้จนกว่าจะ activate คีย์เสียเงิน (ป๊อปอัปเช็ก `/api/license/state` ทุก 8 วินาที
  แล้วเปิดเองเมื่อคีย์เข้า)
* ขั้นตอนขอ license:
  1. คัดลอก HWID จากหน้า `/license` (ปุ่ม `Copy HWID` หรือ `Copy HWID + request`)
  2. เข้ากลุ่มทั้งสาม: https://discord.gg/kVgAMFAY5 , https://t.me/PentestDB ,
     https://www.facebook.com/groups/developerpt
  3. ส่ง HWID ให้ผู้ขาย (หรือแจ้งการชำระเงิน) → ได้รับ **คีย์เสียเงิน** (`--type 30d|60d|1y`) กลับมา
  4. วางคีย์ที่หน้า `/license` แล้วกด Activate — นับ 30 วันจากวันที่ activate
* ระหว่างที่ยังไม่ได้รับคีย์ สถานะคือ `trial-registration-required` และเครื่องมือถูกล็อก
  (ตั้งใจ ไม่ให้เครื่องออกสิทธิ์เองได้) — หน้า `/license`, `/api/license/state` และไฟล์ log
  จะบอก HWID + ลิงก์กลุ่มทุกครั้ง; ถ้าใส่คีย์ทดลองจะได้สถานะ `trial-key-not-allowed`
* เวลานับจาก **trusted clock ไม่ใช่เวลาของเครื่อง** — แก้เวลาหรือเปลี่ยน timezone ที่เครื่องไม่ทำให้ได้วันเพิ่ม
  และการแก้ไฟล์ภายในจะได้สถานะ `trial-tampered`
* ไฟล์ trial ถูกเซ็น และมี **สำเนาที่สองอยู่นอกโฟลเดอร์ข้อมูล** — `/var/lib/vektorsec/.license-trial.anchor` (และ `~/.local/state/vektorsec/` เมื่อ data dir อยู่ใต้ home) — เพราะฉะนั้น `rm -rf /var/lib/vektorsec/data` หรือแตกชุดติดตั้งใหม่ **ไม่ทำให้ได้ 15 วันใหม่**: แอปจะตอบ `marker-only` แล้วขอ key
  (ฝั่ง Windows ทำหน้าที่เดียวกันด้วย `HKCU\Software\VektorSec`)
* หมดอายุแล้ว เครื่องมือทุกตัวจะตอบ `402 LICENSE_REQUIRED` และ UI พาไปหน้า `/license`

### 4.2 หลักการ: license ผูกกับ HWID ของเครื่อง และ **ผู้ขายออก key ให้เท่านั้น**

เหมือนรุ่น Windows ทุกอย่าง:

```
ลูกค้า                                    ผู้ขาย (Raysiya)
──────                                    ────────────────
1. เปิด http://<host>:3001/license
2. เห็น Machine ID (HWID) → กด "คัดลอก HWID"
3. ส่ง HWID + ชื่อบริษัท/แพ็กเกจ ───────►  4. ออก key จากเครื่องของผู้ขาย
   (https://t.me/PentestDB)                 node scripts/gen-unlock-token.js --license …
                                            (private key ไม่เคยอยู่ในชุดที่ส่งลูกค้า)
5. วาง key ที่หน้า /license       ◄──────   ส่ง key (VEKL1.…) กลับให้
   → "เปิดใช้งาน license"
```

* key 1 ใบใช้ได้กับ **HWID เดียว** — เอาไปใช้กับเครื่องอื่นไม่ได้
* **1 ครั้งที่ activate = 30 วัน** นับจากวันที่ activate, key ใหม่ = +30 วัน (ไม่สะสม), วาง key เดิมซ้ำไม่รีเซ็ตวัน
* key เก็บที่ `/var/lib/vektorsec/data/license.key` — **อัปเกรด/ติดตั้งทับไม่ต้อง activate ใหม่**

### 4.3 ขั้นตอนฝั่งลูกค้า (ทำครั้งเดียวต่อเครื่อง)

1. เข้า `http://<IP>:3001/license`
2. ในกล่อง **Machine ID (HWID)** กด **“คัดลอก HWID”**
3. ส่งข้อความพร้อม
   * HWID (รูปแบบ `HWID-XXXX-XXXX-XXXX-XXXX`)
   * ชื่อบริษัท/หน่วยงาน + ผู้ติดต่อ
   * แพ็กเกจที่ต้องการ (30 วัน / 60 วัน / 1 ปี / unlimited)
   * เวอร์ชันที่ติดตั้ง: `cat /opt/vektorsec/VERSION`
4. ได้รับ key (ขึ้นต้นด้วย `VEKL1.`) → กลับมาหน้าเดิม → วางในช่อง → **“เปิดใช้งาน license”**
5. ตรวจว่าแถบสถานะเปลี่ยนเป็น “license ใช้งานอยู่ เหลือ N วัน”

### 4.4 ขั้นตอนฝั่งผู้ขาย — ออก key (ทำที่เครื่องของผู้ขายเท่านั้น)

```bash
# ครั้งแรกครั้งเดียว: สร้างกุญแจ master (Ed25519) — เก็บ private key ให้ปลอดภัย
node scripts/gen-unlock-token.js --init-keys

# ออก key ผูกกับ HWID ของลูกค้า
node scripts/gen-unlock-token.js --license --client "Acme Co., Ltd." \
    --type 30d --hwid HWID-ABCD-1234-5678-90EF

# ตัวเลือก
#   --type 30d | 60d | 1y | unlimited   (คีย์ `trial` มีไว้สำหรับ maintainer build/QA เท่านั้น —
#                                        บิลด์ลูกค้าปฏิเสธด้วย reason `trial-key-not-allowed`)
#   --expires 2026-12-31       กำหนดวันหมดอายุในตัว key เอง (ไม่ใช้กับ unlimited)
#   --client "ชื่อลูกค้า"        ชื่อจะฝังอยู่ใน key (ตรวจย้อนหลังได้)

# ตรวจ key ก่อนส่งให้ลูกค้า
node scripts/gen-unlock-token.js --verify "VEKL1…" --hwid HWID-ABCD-1234-5678-90EF
```

* ประวัติ key ที่เคยออก: `<DATA_DIR>/license-issued.jsonl` (หน้า **Admin → License Keys** ของเครื่องผู้ขายอ่านไฟล์เดียวกัน) — ใช้ค้นหาหรือออกซ้ำเมื่อลูกค้าทำ key หาย
* public key ถูกฝังในแอป (`backend/src/utils/drm/embeddedKey.ts`) → ตรวจ key ได้แบบ offline ไม่ต้องต่อเน็ต
* **private key ไม่อยู่ในชุดติดตั้งของลูกค้า** หน้า Admin → License Keys บนเครื่องลูกค้าจึงออก key ไม่ได้
* ถ้าเปลี่ยน/ทำ master key หาย = ต้องออก public key ใหม่แล้ว rebuild ชุดติดตั้ง (public key ฝังอยู่ในแอป)

### 4.5 HWID มาจากอะไร (และเมื่อไรต้องขอ key ใหม่)

HWID คำนวณจากตัวระบุฮาร์ดแวร์ของเครื่อง — บน Linux คือ `/etc/machine-id` ร่วมกับค่า DMI / board serial

| สถานการณ์ | HWID | ต้องขอ key ใหม่? |
|---|---|---|
| อัปเกรด VektorSec ทับ (`sudo bash install.sh` ชุดใหม่) | เท่าเดิม | ไม่ต้อง — `license.key` ยังอยู่ |
| `systemctl restart` / reboot | เท่าเดิม | ไม่ต้อง |
| โคลน VM ทั้งลูก (พา `/etc/machine-id` + SMBIOS เดิมไปด้วย) | เท่าเดิม | ไม่ต้อง |
| ลง OS ใหม่ / สร้าง VM ใหม่ / ย้ายไปเครื่องอื่น | **เปลี่ยน** | **ต้อง** — ส่ง HWID ใหม่มาให้ผู้ขายออก key ให้ |

> แนะนำ: activate บนเครื่องที่จะใช้จริง และหลีกเลี่ยงการสร้าง `/etc/machine-id` ใหม่
> (`systemd-machine-id-setup`, การ clone แบบ “new machine-id”) หลัง activate

### 4.6 ย้าย/โอน license

แจ้งผู้ขายพร้อม **HWID ใหม่ + HWID เดิม** — ผู้ขายออก key ใหม่ให้ (key เดิมยังใช้กับเครื่องเดิมได้จนหมดอายุ)

---

## 5) คำสั่งที่ใช้บ่อย

```bash
sudo systemctl status vektorsec          # สถานะ + log ล่าสุด
sudo systemctl restart vektorsec         # รีสตาร์ท (ใช้หลังแก้ /etc/default/vektorsec)
sudo systemctl stop vektorsec            # หยุดชั่วคราว
sudo journalctl -u vektorsec -f          # log สดของ service
tail -f /var/lib/vektorsec/logs/backend.log    # log ของ backend
tail -f /var/lib/vektorsec/logs/frontend.log   # log ของ gateway/UI
node /opt/vektorsec/app/electron/headless.js --check   # ดู port/path ที่ระบบใช้จริง
ss -ltnp | grep 3001                     # ตรวจว่าพอร์ต UI เปิดอยู่ (ใครเปิด)
cat /opt/vektorsec/VERSION               # เวอร์ชันที่ติดตั้ง
```

> `journalctl` แสดงข้อความของ service เอง ส่วน log ของ backend/gateway (รวมรหัสผ่าน admin
> ชั่วคราวครั้งแรก) อยู่ในไฟล์ใน `/var/lib/vektorsec/logs` ตามที่ระบุข้างบน

---

## 6) ไฟล์ / พอร์ต / การตั้งค่า

| ค่า | ค่าปริยาย | แก้ที่ |
|---|---|---|
| พอร์ต UI (browser) | `3001` | `FRONTEND_PORT` ใน `/etc/default/vektorsec` |
| bind ของ UI | `0.0.0.0` (เข้าจาก LAN ได้) | `FRONTEND_HOSTNAME` (ใส่ `127.0.0.1` เมื่อมี nginx/Caddy ข้างหน้า) |
| พอร์ต backend | `8081` บน `127.0.0.1` เท่านั้น | `PORT` — **อย่าเปิดออกภายนอก** |
| MongoDB | `mongodb://127.0.0.1:27017/vektorsec` | `MONGO_URI` |
| Redis | `redis://127.0.0.1:6379` | `REDIS_URL` |
| state / data / logs | `/var/lib/vektorsec` | `VEKTORSEC_USER_DATA_DIR`, `DATA_DIR` |
| proxy headers | ปิด | `VEKTORSEC_TRUST_PROXY=1` (เมื่ออยู่หลัง reverse proxy ของคุณเอง) |

หลังแก้ `/etc/default/vektorsec` ต้อง `sudo systemctl restart vektorsec` ทุกครั้ง

```bash
sudoedit /etc/default/vektorsec
sudo systemctl restart vektorsec
```

> ในไฟล์นี้ **ไม่มีสวิตช์ที่ปิด DRM ได้** — trusted clock, trial anchor และ hard license
> enforcement ถูก pin โดยตัวแอปเอง (`electron/backend-runner.js`, `packaged: true`)
> แก้ไฟล์นี้ได้แค่ “ฟังที่ไหน/ต่อ DB ตัวไหน”

---

## 7) ความปลอดภัย

* เปิดเฉพาะพอร์ต UI (`3001/tcp`) ให้เครื่องในวง — **อย่าเปิด** `8081`, `27017`, `6379` ออกอินเทอร์เน็ต
* ต้องการ HTTPS: วาง nginx/Caddy หน้า 3001 (ดูตัวอย่าง `deploy/nginx.example.conf`) แล้วตั้ง
  `FRONTEND_HOSTNAME=127.0.0.1` + `VEKTORSEC_TRUST_PROXY=1`
* ไฟล์ใน `/var/lib/vektorsec/data` เป็นความลับ (มี `license.key`, session secret) — สิทธิ์ `0750` เจ้าของคือ user `vektorsec`
* `/var/lib/vektorsec/.license-trial.anchor` คือ anchor ของ trial — **อย่า copy ไปเครื่องอื่น**
  (ผูกกับ HWID และทำหน้าที่แค่ยืนยันว่าเครื่องนี้ใช้สิทธิ์ทดลองไปแล้ว)
* native addon กันแก้ (`backend/native`, `drm_addon.node`) ต้องคอมไพล์บนเครื่อง build ที่เป็นแพลตฟอร์มเดียวกัน
  (`npm run build:native` — MSVC บน Windows, `build-essential` บน Ubuntu) ถ้าไม่มี addon ระบบจะใช้ตัวเก็บ
  fingerprint ใน JS: license ยังตรวจได้ตามปกติ **แต่ trial จะไม่ถูกแจกเลย** — เพราะ key ที่ใช้เซ็น record
  จะกลายเป็น `HARDWARE_ID_SALT` ซึ่งอยู่ในชุดที่แจกให้ลูกค้าอ่านได้ (= ลูกค้าเซ็น record เองได้ไม่จำกัด)
  ตัว build จึงปิดทางนี้ด้วยการตอบ `reason: "trial-signing-unavailable"` และล็อกเครื่องมือไว้จนกว่าจะใส่
  license key (หรือให้ license server เป็นคนแจกหน้าต่าง trial ผ่าน `VEKTORSEC_LICENSE_SERVER_URL`)
  `scripts/package-linux-customer.mjs` จะ **ไม่ยอมสร้างแพ็กเกจ** ถ้าไม่มี addon แบบ ELF ติดไปด้วย
  (ถ้าตั้งใจขายแบบไม่มี trial จริง ๆ ให้ใส่ `--allow-js-trial`)
* เปลี่ยนรหัส admin ครั้งแรกทันที และเปิด 2FA; อย่าใช้รหัสเดียวกับระบบอื่น
* ตัวแอปอยู่ใน `/opt/vektorsec` แบบอ่านได้อย่างเดียวสำหรับ service — แก้โค้ดไม่ได้ระหว่างรัน

---

## 8) สำรองข้อมูล / อัปเดต / ถอนการติดตั้ง

### สำรอง (ทำก่อนอัปเกรดทุกครั้ง)

```bash
sudo tar czf ~/vektorsec-data-$(date +%F).tar.gz -C /var/lib/vektorsec data
```

เก็บไฟล์นี้ไว้ — มี `config.toml`, `.env` และ **`license.key`** (เอากลับมาแล้วไม่ต้อง activate ใหม่)

### อัปเดตเวอร์ชัน (ไม่เสียข้อมูล / ไม่เสีย license)

```bash
tar xzf VektorSec-<version-ใหม่>-customer-linux-x64.tar.gz
cd vektorsec-<version-ใหม่>
sudo bash install.sh
```

สคริปต์จะหยุด service → เปลี่ยนโค้ดใน `/opt/vektorsec/app` → เริ่มใหม่ โดย **ไม่แตะ `/var/lib/vektorsec`**
จึงยังใช้ `license.key` เดิม, admin เดิม และข้อมูลเดิม

> **node ต้องเป็น path ที่ systemd มองเห็น**: unit รัน `ExecStart=/usr/bin/env node` แปลว่า user
> `vektorsec` ต้องหา `node` เจอใน `/usr/local/bin` หรือ `/usr/bin` — ถ้าติดตั้ง Node ด้วย **nvm**
> (`/root/.nvm/...`) service จะมองไม่เห็นและอ่าน `/root` ไม่ได้ด้วย → unit ตายด้วย
> `env: 'node': No such file or directory` แก้ด้วยการ copy ไปทั้งระบบ (symlink ไป `/root` ไม่พอ):
> `sudo install -m 0755 "$(readlink -f "$(command -v node)")" /usr/local/bin/node` แล้ว
> `sudo systemctl restart vektorsec`
> บน **Kali** แนะนำ `sudo bash install.sh --no-deps` — ถ้า node ≥ 22 อยู่ใน PATH ของ root สคริปต์จะข้าม
> NodeSource เอง แต่ถ้า node เก่ากว่านั้นมันจะไปดึงจาก NodeSource ซึ่งไม่รับ `kali-rolling`
> (repo ของ MongoDB ที่สคริปต์เพิ่มก็เป็นชุดของ Debian) → `--no-deps` ตัดขั้นนั้นออกและใช้ของเดิม

### ถอนการติดตั้ง

```bash
sudo systemctl disable --now vektorsec
sudo rm -f /etc/systemd/system/vektorsec.service
sudo systemctl daemon-reload
sudo rm -rf /opt/vektorsec
# ลบข้อมูลทั้งหมด (รวม license.key) — ทำเมื่อต้องการจริง ๆ เท่านั้น
sudo rm -rf /var/lib/vektorsec /etc/default/vektorsec
sudo userdel vektorsec 2>/dev/null || true
```

> MongoDB / Redis ที่สคริปต์ติดตั้งให้จะยังอยู่ — ถอนเองด้วย
> `sudo apt-get remove --purge mongodb-org redis-server` เมื่อไม่ใช้แล้ว

---

## 9) แก้ปัญหา

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `install.sh` ขึ้น “service vektorsec หยุดระหว่างรอ” | ดู `sudo journalctl -u vektorsec -n 80 --no-pager` และ `tail -50 /var/lib/vektorsec/logs/backend.log` — มักเป็น MongoDB ยังไม่ขึ้น (`systemctl status mongod`) หรือ `MONGO_URI` ผิด |
| รอ 240 วินาทีแล้ว `install.sh` ยังไม่ผ่าน `GET /api/ready` | `systemctl status mongod redis-server` · `ss -ltnp \| grep 3001` (พอร์ตชนกับแอปอื่นหรือไม่) · ลอง `--port 8080` |
| กด **Create account / Login** แล้วขึ้น **`Gateway upstream error`** | gateway (`:3001`) ตอบแทน backend (`:8081`) เพราะ backend ยังไม่พร้อม — เช็กด้วย `curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/api/ready` (ต้องได้ `200`; ถ้า `502` = backend ไม่ได้รัน) · `tail -50 /var/lib/vektorsec/logs/backend.log` (หา `Secret MONGO_URI not found` / `REDIS_URL not found`) · `systemctl status mongod redis-server` · แก้แล้ว `sudo systemctl restart vektorsec` (install.sh รุ่นนี้รอจนพร้อมก่อนจบอยู่แล้ว) |
| `systemctl status mongod` ขึ้น **“Unit mongod.service could not be found”** | MongoDB ยังไม่ถูกติดตั้งบนเครื่องนี้ (install.sh รุ่นก่อนแค่เตือนแล้วไปต่อ) → backend ต่อฐานข้อมูลไม่ได้ และหน้าเว็บขึ้น `Gateway upstream error` ทุกครั้ง · ติดตั้งเอง: `sudo apt-get install -y curl gnupg` · `curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \| sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg` · `echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \| sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list` · `sudo apt-get update && sudo apt-get install -y mongodb-org` · `sudo systemctl enable --now mongod` · แล้ว `sudo bash install.sh` ซ้ำ (ใช้ชุดเดิม ไม่ต้องแตกไฟล์ใหม่) — หรือใช้ MongoDB เครื่องอื่น/Atlas แล้วตั้ง `MONGO_URI` ใน `/etc/default/vektorsec` |
| `sudo apt-get install -y mongodb-org` ขึ้น **“E: Unable to locate package mongodb-org”** | apt ยังไม่รู้จัก repo ของ MongoDB — keyring หรือไฟล์ repo ถูกเขียนไม่ครบ (หรือ `apt-get update` ไม่ผ่าน) · เช็ก `cat /etc/apt/sources.list.d/mongodb-org-7.0.list` และ `stat -c %s /usr/share/keyrings/mongodb-server-7.0.gpg` (ต้องมากกว่า 0 byte) · `sudo apt-get update 2>&1 \| grep -iE 'mongo\|^E:\|^W:'` · ถ้าไม่มีบรรทัด `deb ...` ให้เขียนใหม่ด้วยคำสั่งชุดในแถวก่อนหน้า แล้ว `sudo apt-get update` · ยืนยันว่า apt เห็นแพ็กเกจ: `apt-cache policy mongodb-org-server` ต้องขึ้น `Candidate: 7.0.x` (ถ้าเป็น `(none)` = repo ยังไม่ถูกอ่าน) · ถ้าเห็นแล้วแต่ลงไม่ผ่าน ให้เอาเฉพาะตัวเซิร์ฟเวอร์: `sudo apt-get install -y mongodb-org-server` · เครือข่ายที่บล็อก `repo.mongodb.org`: ใช้ Docker (`docker run -d --name mongo -p 27017:27017 mongo:7`) หรือ Atlas แล้วตั้ง `MONGO_URI` |
| `apt-get update` ขึ้น **“Signature verification failed … SHA1 is not considered secure since 2026-02-01”** หรือ **“The repository … is not signed”** | apt รุ่นใหม่ (Debian 13 / Kali 2026) ตรวจลายเซ็นด้วย `sqv` (Sequoia) ซึ่งปฏิเสธคีย์ของ MongoDB เพราะยังใช้ SHA‑1 → repo ถูกปิดใช้งาน แพ็กเกจจึง “หาไม่พบ” ทั้งที่ไฟล์ repo/คีย์ถูกต้อง · ทางลัด — ใช้ repo เดียวกันแต่ไม่ตรวจลายเซ็น (ยังเป็น HTTPS): `echo "deb [trusted=yes] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \| sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list` · `sudo apt-get update` · `sudo apt-get install -y mongodb-org-server` · `sudo systemctl enable --now mongod` · หรือโหลด `.deb` ตรงจาก repo: `BASE=https://repo.mongodb.org/apt/debian` · `F=$(curl -fsS "$BASE/dists/bookworm/mongodb-org/7.0/main/binary-amd64/Packages" \| awk '/^Package: mongodb-org-server$/{f=1} f&&/^Filename:/{print $2; exit}')` · `curl -fsSLO "$BASE/$F"` · `sudo apt-get install -y ./$(basename "$F")` — `install.sh` รุ่นใหม่ลอง `trusted=yes` แล้วต่อด้วย `.deb` ให้อัตโนมัติ · หมายเหตุ: คีย์ของ repo 8.0 เป็น SHA‑512 จึงผ่าน `sqv` แต่ backend ชุดนี้ปัก `mongoose 7` (driver 5) ซึ่งรองรับเซิร์ฟเวอร์ถึง 7.0 เท่านั้น — อย่าขยับไป 8.0 เพื่อแก้ปัญหานี้ · **ขั้นตอนละเอียดอยู่ในหัวข้อ “ถ้า Kali / Debian 13 ไม่ยอมรับคีย์ MongoDB” ด้านล่างตาราง** |
| `mongod` ติดตั้งแล้วแต่ตายทันที (`Illegal instruction`) | CPU รุ่นเก่าไม่มีชุดคำสั่ง **AVX** ซึ่ง MongoDB 5.0 ขึ้นไปบังคับ → ใช้ MongoDB บนเครื่องอื่น/Atlas แล้วตั้ง `MONGO_URI` (หรือรัน MongoDB ใน Docker บนเครื่องที่รองรับ) |
| เข้าแล้วได้ 502 / หน้าเว็บพังหลังอัปเกรด | เคลียร์แคช/.next ที่เขียนค้าง: `sudo systemctl restart vektorsec` แล้วดู `frontend.log`; ถ้ายังพังให้ติดตั้งใหม่ด้วยชุดเดิม |
| login ไม่ได้ / ลืมรหัส admin | ครั้งแรกให้หาใน `backend.log` (`Temporary password`) · ถ้าตั้งเองไม่ได้ ให้ติดต่อผู้ขาย (มีขั้นตอน reset admin ให้) |
| หน้า `/license` ขึ้นว่า key ใช้กับเครื่องนี้ไม่ได้ | HWID ไม่ตรง (คนละเครื่อง) หรือ key หมดอายุ — ส่ง HWID ที่หน้า `/license` มาให้ผู้ขายตรวจ/ออกใหม่ |
| ทุกเครื่องมือขึ้น `402 LICENSE_REQUIRED` | ยังไม่ได้ activate หรือ key หมดอายุ → ใส่ key ที่หน้า `/license` |
| ขึ้น `trial-tampered` | ไฟล์ภายในถูกแก้/ถูกลบ/เวลาเครื่องถูกหมุน → ต้องใช้ license key |
| ขึ้น `trial-signing-unavailable` | ชุดที่ติดตั้งไม่มี `drm_addon.node` (build โดยไม่มี native addon) จึงไม่แจก trial เพื่อความปลอดภัย → ติดตั้งใหม่ด้วยชุดทางการ หรือใส่ license key |
| ขึ้น `trial-registration-required` | ชุดนี้ไม่มีช่วงทดลองใช้ฟรี: คัดลอก HWID จาก `/license` เข้ากลุ่ม Discord/Telegram/Facebook แล้วส่ง HWID ให้ผู้ขาย จากนั้นนำคีย์เสียเงิน (`--type 30d|60d|1y`) ที่ได้รับมากด Activate |
| ขึ้น `trial-key-not-allowed` | ใส่คีย์ทดลอง (`--type trial`) ซึ่งบิลด์ลูกค้าไม่รับ — ต้องใช้คีย์เสียเงิน (`--type 30d|60d|1y`) ของเครื่องนี้ |
| เปลี่ยนพอร์ตแล้วเปิดไม่ได้ | ต้อง `systemctl restart vektorsec` และเปิดพอร์ตใหม่ใน firewall ด้วย |
| ต้องการดูว่าระบบใช้ค่าอะไรอยู่ | `node /opt/vektorsec/app/electron/headless.js --check` |

### ถ้า Kali / Debian 13 ไม่ยอมรับคีย์ MongoDB (ขึ้น `is not signed` / `SHA1 is not considered secure`)

**อาการที่เห็น** — `sudo apt-get update` ตอบประมาณนี้:

```text
W: Signature verification failed: https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 InRelease:
   Sub-process /usr/bin/sqv returned an error code (1), error message is:
   Signing key on E58830201F7DD82CD808AA84160D26BB1785BA38 is not bound:
   No binding signature at time 2026-11-02T17:01:03Z   because: Policy rejected
   non-revocation signature (PositiveCertification) requiring second pre-image
   resistance   because: SHA1 is not considered secure since 2026-02-01T00:00:00Z
E: The repository 'https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 InRelease' is not signed.
```

แล้วต่อด้วย `apt-cache policy mongodb-org-server` → `N: Unable to locate package mongodb-org-server`,
`apt-get install -y mongodb-org` → `E: Unable to locate package mongodb-org`,
`systemctl enable --now mongod` → `Failed to enable unit: Unit mongod.service does not exist`

**สาเหตุ** — apt รุ่นใหม่ (Debian 13 / Kali 2026 / Parrot ล่าสุด) ตรวจลายเซ็นด้วย `sqv` (Sequoia) ซึ่งตั้ง policy ว่า **SHA‑1 ใช้ไม่ได้ตั้งแต่ 2026‑02‑01** แต่คีย์ของ MongoDB 7.0 ยังลงนามตัวเองด้วย SHA‑1 → `sqv` ถือว่าคีย์ “ไม่ถูกผูก” → apt ปิด repo ทิ้ง ทั้งที่ไฟล์ `/etc/apt/sources.list.d/mongodb-org-7.0.list` และ `/usr/share/keyrings/mongodb-server-7.0.gpg` ถูกต้องครบ (โหลด `Release` ได้ HTTP 200 แต่ `InRelease` ไม่ผ่านการตรวจ) — ไม่ใช่ปัญหาที่โค้ดชื่อรุ่น (codename) ของ repo

**วิธีที่ 1 — ใช้ repo เดิมแบบ `[trusted=yes]` (เร็วที่สุด, ยังดาวน์โหลดผ่าน HTTPS ของ MongoDB)**

```bash
# 1) เขียนทับไฟล์ repo เดิม: ไม่ตรวจลายเซ็น แต่ยังเป็น HTTPS origin เดียวกัน
echo "deb [trusted=yes] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# 2) อัปเดต index — ต้องไม่มีบรรทัด E: ที่พูดถึง repo.mongodb.org
sudo apt-get update

# 3) ต้องเห็น Candidate: 7.0.x  (ถ้ายังเป็น (none) ให้ใช้วิธีที่ 2)
apt-cache policy mongodb-org-server

# 4) เอาเฉพาะเซิร์ฟเวอร์ (เมตาแพ็กเกจ mongodb-org พ่วง mongos/tools ที่ชอบติด dependency)
sudo apt-get install -y mongodb-org-server

# 5) เปิด service และตรวจว่าฟังพอร์ตจริง
sudo systemctl enable --now mongod
systemctl status mongod --no-pager | head -5
ss -ltnp | grep 27017
```

**วิธีที่ 2 — โหลด `.deb` ตรงจาก repo (ไม่พึ่งการตรวจลายเซ็นของ apt เลย)**

```bash
BASE=https://repo.mongodb.org/apt/debian
F=$(curl -fsS "$BASE/dists/bookworm/mongodb-org/7.0/main/binary-amd64/Packages" \
    | awk '/^Package: mongodb-org-server$/{f=1} f&&/^Filename:/{print $2; exit}')
curl -fsSLO "$BASE/$F"
sudo apt-get install -y "./$(basename "$F")"   # ให้ apt ดึง dependency จาก mirror ของ Kali/Debian
sudo systemctl enable --now mongod
```

เครื่อง ARM: เปลี่ยน `binary-amd64` เป็น `binary-arm64`

**ตรวจว่ากลับมาใช้งานได้ทั้งระบบ**

```bash
sudo systemctl restart vektorsec
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/api/ready   # ต้องได้ 200
```

**หมายเหตุ**

- `install.sh` รุ่นล่าสุดลองให้อัตโนมัติแล้ว 3 ขั้น: signed repo → `[trusted=yes]` → `.deb` ตรง จึงไม่ต้องทำมือ ถ้าเคยรันแล้วล้ม รัน `sudo bash install.sh` ซ้ำด้วยชุดเดิมได้เลย
- อย่าแก้ด้วยการเปลี่ยนไป repo 8.0: คีย์ 8.0 เป็น SHA‑512 และผ่าน `sqv` จริง แต่ backend ชุดนี้ปัก `mongoose 7` (driver 5) ที่รองรับเซิร์ฟเวอร์ถึง 7.0 เท่านั้น
- ทางเลือกที่ไม่ต้องมี MongoDB บนเครื่องนี้: Docker (`docker run -d --name mongo -p 27017:27017 mongo:7`) หรือ MongoDB Atlas แล้วตั้ง `MONGO_URI` ใน `/etc/default/vektorsec`

---

## 10) ติดต่อ / ขอ license

ส่งข้อมูลเหล่านี้มาที่ **https://t.me/PentestDB**

1. **HWID** จากหน้า `/license` (ปุ่ม “คัดลอก HWID”)
2. ชื่อบริษัท/หน่วยงาน + ผู้ติดต่อ
3. แพ็กเกจที่ต้องการ (30 วัน / 60 วัน / 1 ปี / unlimited)
4. เวอร์ชัน + ระบบ: `cat /opt/vektorsec/VERSION` · `grep PRETTY_NAME /etc/os-release`

> license key ออกโดยผู้ขายเท่านั้น (เหมือนรุ่น Windows) — ลูกค้าไม่สามารถสร้าง key เองได้

