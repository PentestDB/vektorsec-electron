@echo off
setlocal
rem Rebuild VektorSec-Setup-1.2.4-customer.exe from 17 parts (20 MiB each).
rem Run this file from inside the folder that contains all the parts.
copy /b VektorSec-Setup-1.2.4-customer.exe.001+VektorSec-Setup-1.2.4-customer.exe.002+VektorSec-Setup-1.2.4-customer.exe.003+VektorSec-Setup-1.2.4-customer.exe.004+VektorSec-Setup-1.2.4-customer.exe.005+VektorSec-Setup-1.2.4-customer.exe.006+VektorSec-Setup-1.2.4-customer.exe.007+VektorSec-Setup-1.2.4-customer.exe.008+VektorSec-Setup-1.2.4-customer.exe.009+VektorSec-Setup-1.2.4-customer.exe.010+VektorSec-Setup-1.2.4-customer.exe.011+VektorSec-Setup-1.2.4-customer.exe.012+VektorSec-Setup-1.2.4-customer.exe.013+VektorSec-Setup-1.2.4-customer.exe.014+VektorSec-Setup-1.2.4-customer.exe.015+VektorSec-Setup-1.2.4-customer.exe.016+VektorSec-Setup-1.2.4-customer.exe.017 "VektorSec-Setup-1.2.4-customer.exe"
echo.
echo Done. Verifying SHA-256 ...
certutil -hashfile "VektorSec-Setup-1.2.4-customer.exe" SHA256
echo Expected: EBF5A804CDBB087477AD0ABD444A2B76CEDE58FF6D925D7F20F491212641ABD7
pause
