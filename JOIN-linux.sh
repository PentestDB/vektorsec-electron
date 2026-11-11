#!/usr/bin/env bash
# Rebuild VektorSec-1.2.7-customer-linux-x64.tar.gz from 27 parts (20 MiB each).
# Run it from inside the folder that holds all the parts:  bash JOIN-linux.sh
set -euo pipefail
cd "$(dirname "$0")"

BASE="VektorSec-1.2.7-customer-linux-x64.tar.gz"
EXPECTED="962E601E83BCA2DA47432EC2A13058AD6C0BB4F7F354E99B487290C8E664212D"

# every part must be there before concatenating: a missing .0XX would silently
# produce a shorter file and only the hash check would catch it
PARTS=(
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.001"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.002"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.003"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.004"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.005"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.006"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.007"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.008"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.009"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.010"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.011"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.012"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.013"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.014"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.015"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.016"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.017"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.018"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.019"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.020"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.021"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.022"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.023"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.024"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.025"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.026"
  "VektorSec-1.2.7-customer-linux-x64.tar.gz.027"
)

for part in "${PARTS[@]}"; do
  if [ ! -f "$part" ]; then
    echo "missing part: $part" >&2
    exit 1
  fi
done

cat "${PARTS[@]}" > "$BASE"

echo
echo "Rebuilt: $BASE ($(wc -c < "$BASE") bytes)"
echo "Checking SHA-256 ..."
if ! echo "$EXPECTED  $BASE" | sha256sum -c -; then
  echo "" >&2
  echo "SHA-256 mismatch - a part is damaged or incomplete." >&2
  echo "Download the bad part again (compare sizes with MANIFEST-linux.txt)." >&2
  exit 1
fi

echo
echo "OK. Next steps:"
echo "  tar xzf $BASE"
echo "  cd vektorsec-1.2.7"
echo "  sudo bash install.sh"
echo "  then open  http://<this-host>:3001  (see INSTALL-linux.md)"
