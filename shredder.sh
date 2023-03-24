#!/bin/bash
if [ -z "$1" ]; then echo -e "Usage\n./shredder.sh target"; exit 1; fi
tgt="$1"
tsize=`wc -c "$1"|cut -f 1 -d " "`
echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
echo "write:0xFF"
tr "\000" "\377" < /dev/zero|dd of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
echo "write:0x77"
tr "\000" "\167" < /dev/zero|dd of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
echo "write:0x33"
tr "\000" "\063" < /dev/zero|dd of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
echo "write:0x00"
dd if=/dev/zero of="$tgt" bs=$tsize count=1 > /dev/null 2>&1
sync
rm -f "$tgt"
echo "done"
exit 0
