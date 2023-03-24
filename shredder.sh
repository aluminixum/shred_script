#!/bin/bash

# usage
if [ -z "$1" ]; then echo -e "Usage\n./shredder.sh target"; exit 1; fi

# dd block size
ddbs=512

# target
tgt="$1"

# get file size (byte)
echo "get size..."
tsize=`wc -c "$1"|cut -f 1 -d " "`
echo "$tsize byte"

# calc dd count
# file size / 512(block size) + 1block(512byte)
echo "calc count..."
tcount=`expr $tsize \/ $ddbs \+ 1`
echo "$tcount count"

# other option
ddopt="conv=notrunc,noerror,fdatasync"

# delete cache
echo "delete cache data..."
dd of="$tgt" oflag=nocache conv=notrunc,fdatasync count=0 > /dev/null 2>&1

# start dd shredder
echo -e "\n---- start ----\n"
echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0x00"
dd if=/dev/zero of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0xBB"
tr "\000" "\273" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0x33"
tr "\000" "\063" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0xFF"
tr "\000" "\277" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0x77"
tr "\000" "\167" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
echo "write:0x00"
dd if=/dev/zero of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1

# check file or block
echo ""
test -b "$tgt"
if [ $? != 0 ];then rm -i "$tgt";fi
echo -e "\n---- done ----\n"
exit 0
