VektorSec 1.2.7 — ไฟล์ติดตั้งแบบแบ่งพาร์ท / split installer parts
=====================================================================

ไฟล์เต็ม (full file) : VektorSec-Setup-1.2.7-customer.exe
ขนาด (size)         : 352,491,252 bytes (≈ 336 MB)
จำนวนพาร์ท (parts)   : 17 ไฟล์ × 20 MB (20 MiB = 20,971,520 bytes)
SHA-256 ของไฟล์เต็ม  : 1030812994B4C7C78B6D9F6EAF59402D58CC54E641EC38CC8C5CDE2D98049429

ต้องมีครบทั้ง 17 ไฟล์ก่อนต่อ (all 17 parts are required).

---------------------------------------------------------------------
1) วิธีต่อไฟล์ (Windows) — เลือก 1 วิธี
---------------------------------------------------------------------

[A] ดับเบิลคลิก JOIN.bat   ← ง่ายที่สุด (ต่อไฟล์ + ตรวจ SHA-256 ให้เลย)
    ต้องวางไฟล์ VektorSec-Setup-1.2.7-customer.exe.001 … .017 ไว้ในโฟลเดอร์เดียวกัน

[B] Command Prompt (cmd) — เข้าไปในโฟลเดอร์นี้แล้วรัน:
    copy /b VektorSec-Setup-1.2.7-customer.exe.001+VektorSec-Setup-1.2.7-customer.exe.002+...+"VektorSec-Setup-1.2.7-customer.exe" VektorSec-Setup-1.2.7-customer.exe

[C] 7-Zip: คลิกขวาที่ไฟล์ VektorSec-Setup-1.2.7-customer.exe.001 → 7-Zip → Extract here

---------------------------------------------------------------------
2) ตรวจสอบความถูกต้อง (verify) — ต้องได้ค่านี้
---------------------------------------------------------------------

    Get-FileHash .\VektorSec-Setup-1.2.7-customer.exe -Algorithm SHA256
    1030812994B4C7C78B6D9F6EAF59402D58CC54E641EC38CC8C5CDE2D98049429

ถ้า hash ไม่ตรง → พาร์ทใดพาร์ทหนึ่งโหลดไม่ครบ ให้เทียบขนาดกับ MANIFEST.txt แล้วโหลดใหม่
ถ้า hash ตรง → ดับเบิลคลิกไฟล์ .exe เพื่อติดตั้งได้เลย (ดู README.md)

---------------------------------------------------------------------
3) License (สำคัญ)
---------------------------------------------------------------------

บิลด์ลูกค้าเป็นแบบ 'จ่ายเงินเท่านั้น' — ครั้งแรกจะเจอหน้า Activation:
คัดลอก Machine ID (HWID) ส่งให้ผู้ขาย → รับคีย์ VEKL1.… → Activate (1 คีย์ = 1 เครื่อง)

คู่มือเต็ม: INSTALL.md (Windows) · README.md · README.th.md

⚠️ Acceptable use: VektorSec is for authorized security testing only.
