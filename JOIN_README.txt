VektorSec 1.2.4 — ไฟล์ติดตั้งแบบแบ่งพาร์ท / split installer parts
=====================================================================

ไฟล์เต็ม (full file) : VektorSec-Setup-1.2.4-customer.exe
ขนาด (size)         : 345,005,284 bytes (≈ 329 MB)
จำนวนพาร์ท (parts)   : 17 ไฟล์ × 20 MB (20,971,520 bytes)
SHA-256 ของไฟล์เต็ม  : 338684A654571EFC5AA568A5746EAB96A124AFA65E5BE9993AA29BF59903F6D7

⚠️ ต้องมีครบทั้ง 17 ไฟล์ก่อนต่อ (all 17 parts are required).

---------------------------------------------------------------------
วิธีต่อไฟล์ (Windows) — เลือก 1 วิธี
---------------------------------------------------------------------

[A] ดับเบิลคลิก JOIN.bat   ← ง่ายที่สุด (ต่อไฟล์ + ตรวจ SHA-256 ให้เลย)
    ต้องวางไฟล์ VektorSec-Setup-1.2.4-customer.exe.001 … .017 ไว้ในโฟลเดอร์เดียวกัน

[B] Command Prompt (cmd) — เข้าไปในโฟลเดอร์นี้แล้วรัน:
    copy /b VektorSec-Setup-1.2.4-customer.exe.001+VektorSec-Setup-1.2.4-customer.exe.002+VektorSec-Setup-1.2.4-customer.exe.003+...+"VektorSec-Setup-1.2.4-customer.exe" VektorSec-Setup-1.2.4-customer.exe

[C] PowerShell:
    $parts = Get-ChildItem 'VektorSec-Setup-1.2.4-customer.exe.0*' | Sort-Object Name
    $out = [System.IO.File]::Create("$PWD\VektorSec-Setup-1.2.4-customer.exe")
    foreach ($p in $parts) { $fs = [System.IO.File]::OpenRead($p.FullName); $fs.CopyTo($out); $fs.Close() }
    $out.Close()

[D] 7-Zip: คลิกขวาที่ไฟล์ VektorSec-Setup-1.2.4-customer.exe.001 → 7-Zip → Extract here (7-Zip ต่อให้อัตโนมัติ)

---------------------------------------------------------------------
ตรวจสอบความถูกต้อง (verify) — ต้องได้ค่านี้
---------------------------------------------------------------------
    Get-FileHash .\VektorSec-Setup-1.2.4-customer.exe -Algorithm SHA256
    338684A654571EFC5AA568A5746EAB96A124AFA65E5BE9993AA29BF59903F6D7

หรือ (ไม่ต้องเปิด PowerShell):
    certutil -hashfile VektorSec-Setup-1.2.4-customer.exe SHA256

ถ้า hash ไม่ตรง → ไฟล์พาร์ทใดพาร์ทหนึ่งเสีย/โหลดไม่ครบ ให้โหลดพาร์ทนั้นใหม่
ถ้า hash ตรง → ดับเบิลคลิกไฟล์ .exe เพื่อติดตั้งได้เลย (อ่านวิธีติดตั้งใน README.md)

---------------------------------------------------------------------
ติดตั้งทับรุ่นเดิม (upgrade) — ทำแบบนี้ทุกครั้ง
---------------------------------------------------------------------
1) ปิดแอป VektorSec ให้สนิทก่อน (ตรวจใน Task Manager ว่าไม่มี VektorSec.exe /
   node.exe ของ gateway เหลืออยู่) — ถ้าเปิดค้างไว้ ตัวติดตั้งจะเขียนไฟล์ทับไม่ได้
   แล้วจะดูเหมือน " reinstalled แต่ไม่เปลี่ยน "
2) ดับเบิลคลิกตัวติดตั้งที่ต่อเสร็จแล้ว → ติดตั้งทับตำแหน่งเดิมได้เลย
3) เปิดแอปใหม่ ตรวจว่ารุ่นที่ Settings/หน้าแรกตรงกับ 1.2.4

---------------------------------------------------------------------
ถ้า MongoDB ไม่ยอมสตาร์ท — ต้องลง Microsoft Visual C++ (x64)
---------------------------------------------------------------------

ตัว VektorSec (Electron) และ Redis ไม่ต้องใช้ VC++ แต่ MongoDB 7.0 ต้องใช้
(mongod.exe อ้างอิง MSVCP140.dll / VCRUNTIME140.dll / VCRUNTIME140_1.dll)

1) เช็กว่ามีอยู่แล้วหรือยัง — พิมพ์อะไรออกมา = มีแล้ว ข้ามได้:
   (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -EA SilentlyContinue).Version

2) ถ้าไม่มี ให้รันตัวติดตั้งที่แถมมากับ zip ของ MongoDB
   (ตัวนี้ต้องกด Yes ที่ UAC / Administrator — ขั้นตอนเดียวในคู่มือที่ต้องใช้ admin):
   & "$env:APPDATA\VektorSec\runtime\mongodb\bin\vc_redist.x64.exe"

3) สั่งฐานข้อมูลใหม่:
   powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Programs\VektorSec\resources\app\scripts\local-db.ps1" start

อาการที่บอกว่ายังขาด VC++: mongod.exe ปิดตัวเองทันที · local-db.ps1 status
ขึ้น 27017 ปิดอยู่ · Event Viewer ฟ้อง MSVCP140.dll / VCRUNTIME140.dll หาไม่เจอ
(บนเครื่องที่ไม่มีเน็ต ไฟล์ vc_redist.x64.exe ตัวนี้อยู่ใน zip ของ MongoDB ที่คัดลอกมา)

---------------------------------------------------------------------
Parts
---------------------------------------------------------------------
  VektorSec-Setup-1.2.4-customer.exe.001     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.002     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.003     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.004     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.005     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.006     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.007     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.008     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.009     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.010     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.011     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.012     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.013     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.014     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.015     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.016     20971520 bytes
  VektorSec-Setup-1.2.4-customer.exe.017      9460964 bytes

⚠️ Acceptable use: VektorSec is for authorized security testing only.
