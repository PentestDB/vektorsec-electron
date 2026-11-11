VektorSec 1.2.7 — Linux (x64) — วิธีต่อไฟล์พาร์ทและติดตั้ง
======================================================================

ไฟล์ที่ต้องมีให้ครบ : 27 พาร์ท (.001 ถึง 027)
ขนาดหลังต่อเสร็จ   : 562,721,334 bytes
SHA-256 ที่ถูกต้อง : 962E601E83BCA2DA47432EC2A13058AD6C0BB4F7F354E99B487290C8E664212D

---------------------------------------------------------------------
1) ต่อพาร์ทกลับเป็นไฟล์เดียว
---------------------------------------------------------------------

วางไฟล์ทุกพาร์ทไว้ในโฟลเดอร์เดียวกัน แล้วสั่ง:

    bash JOIN-linux.sh

หรือสั่งเอง (ผลเหมือนกัน) — ต้องเรียงตามชื่อไฟล์ .001 .002 ... :

    cat VektorSec-1.2.7-customer-linux-x64.tar.gz.0* > VektorSec-1.2.7-customer-linux-x64.tar.gz
    sha256sum -c VektorSec-1.2.7-customer-linux-x64.tar.gz.sha256

ต้องขึ้น OK / VektorSec-1.2.7-customer-linux-x64.tar.gz: OK
ถ้าขึ้น FAILED → พาร์ทใดพาร์ทหนึ่งโหลดไม่ครบ ให้เทียบขนาดไฟล์กับ MANIFEST-linux.txt
แล้วโหลดพาร์ทนั้นใหม่ — อย่าติดตั้งถ้า hash ยังไม่ตรง

---------------------------------------------------------------------
2) แตกไฟล์และติดตั้ง (ต้องใช้ sudo / root)
---------------------------------------------------------------------

    tar xzf VektorSec-1.2.7-customer-linux-x64.tar.gz
    cd vektorsec-1.2.7
    sudo bash install.sh

ตัวเลือก:
    sudo bash install.sh --no-deps      # ใช้ Node 22 / MongoDB / Redis ที่มีอยู่แล้ว
    sudo bash install.sh --port 8080    # เปลี่ยนพอร์ต UI (ค่าเริ่มต้น 3001)
    bash install.sh --help              # ตัวเลือกทั้งหมด

สิ่งที่ install.sh ทำ: ติดตั้ง Node.js 22 (ถ้าจำเป็น) + MongoDB 7.0 + Redis → สร้าง system user
vektorsec → วางแอปที่ /opt/vektorsec/app → เก็บข้อมูลที่ /var/lib/vektorsec/{data,logs}
→ ติดตั้ง systemd unit vektorsec.service → เปิดพอร์ตใน ufw → restart แล้วรอจนกว่า
GET http://127.0.0.1:3001/api/ready ตอบ 200 (ไม่เกิน 240 วินาที) จึงจะบอกว่าติดตั้งสำเร็จ

เครื่องที่ต้องใช้: Ubuntu 20.04+ / Debian 11+ / Kali (x64) · RAM 4 GB (แนะนำ 8 GB)
ดิสก์ว่าง ≥ 5 GB · เปิดพอร์ต 3001 ให้เครื่องที่ใช้เบราว์เซอร์เข้ามา

Kali / Debian 13: ถ้าติดตั้ง MongoDB จาก repo ไม่ผ่าน (is not signed / SHA1 is not
considered secure) ดูวิธีแก้ใน INSTALL-linux.md หัวข้อ 9

---------------------------------------------------------------------
3) เปิดใช้งานครั้งแรก + License (สำคัญ)
---------------------------------------------------------------------

เปิดเบราว์เซอร์ที่  http://<ip-ของเครื่องนี้>:3001  (บนเครื่องเองใช้ 127.0.0.1)

บิลด์ลูกค้าเป็นแบบ 'จ่ายเงินเท่านั้น' — ไม่มีช่วงทดลองใช้ฟรี:
  • ครั้งแรกจะเจอหน้า Activation → คัดลอก 'Machine ID (HWID)' ส่งให้ผู้ขาย
  • ผู้ขายออกคีย์ให้ (ขึ้นต้นด้วย VEKL1.) → วางในช่อง License Key → Activate
  • 1 คีย์ = 1 เครื่อง · คีย์ผูกกับ HWID · เปลี่ยนเครื่อง/ลง OS ใหม่ = ต้องขอคีย์ใหม่

บัญชีผู้ดูแลระบบ: admin@vektorsec.local — รหัสผ่านสุ่มพิมพ์ครั้งเดียวใน log:
    sudo grep -i 'Temporary password' /var/lib/vektorsec/logs/backend.log

---------------------------------------------------------------------
4) คำสั่งที่ใช้บ่อย
---------------------------------------------------------------------

    sudo systemctl status vektorsec          # สถานะ service
    sudo journalctl -u vektorsec -f          # ดู log สด
    curl -s http://127.0.0.1:3001/api/ready  # ต้องได้ 200
    sudo systemctl restart vektorsec         # หลังแก้ /etc/default/vektorsec

อัปเดตเวอร์ชันถัดไป: แตกทาร์บอลใหม่แล้ว  sudo bash install.sh  (ทับของเดิมได้เลย)
ข้อมูลเดิม + license.key อยู่ที่ /var/lib/vektorsec/data → ไม่ถูกเขียนทับ

คู่มือเต็ม: INSTALL-linux.md (ไทย) · INSTALL-linux.en.md (English)

---------------------------------------------------------------------
Parts
---------------------------------------------------------------------
  VektorSec-1.2.7-customer-linux-x64.tar.gz.001     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.002     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.003     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.004     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.005     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.006     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.007     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.008     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.009     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.010     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.011     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.012     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.013     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.014     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.015     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.016     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.017     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.018     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.019     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.020     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.021     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.022     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.023     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.024     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.025     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.026     20971520 bytes
  VektorSec-1.2.7-customer-linux-x64.tar.gz.027     17461814 bytes

⚠️ Acceptable use: VektorSec is for authorized security testing only.
