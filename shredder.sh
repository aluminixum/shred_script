#!/bin/bash

# usage
# 完成後にヘルプを追記する
if [ -z "$1" ]
    then echo -e "Usage\n./shredder.sh target"
    exit 1
fi

# dd block size
# fdiskなどで削除対象のブロックサイズを取得予定
ddbs=512

# target
tgt="$1"

# check file or block 0:block 1:file
# ファイルとブロックデバイスの確認(ディレクトリもここ？)
echo ""
test -b "$tgt"
if [ $? != 0 ]; then
    tgttype=1
else
    tgttype=0
fi

# get file size (byte)
# ファイルサイズは取得出来るのでブロックサイズでの余りを足せばいい？
echo "get size..."
tsize=`wc -c "$1"|awk '{print $1}'`
echo "$tsize byte"

# calc dd count
# file size / 512(block size) + 1block(512byte)
# とりあえず512byteのドライブが多いからやっつけで
echo "calc count..."
tcount=`expr $tsize \/ $ddbs \+ 1`
echo "$tcount count"

# other dd options
# ToDoに書いたオプションまとめ
ddopt="oflag=direct,sync conv=notrunc,noerror,fsync status=progress"

# delete cache
# メモリ上のキャッシュ削除
echo "delete cache data..."
sync && echo 3 > /proc/sys/vm/drop_caches
dd of="$tgt" oflag=nocache conv=notrunc,fdatasync count=0 > /dev/null 2>&1

# ここから下は関数化してループ処理をつくる
# start dd shredder
echo -e "\n---- start ----\n"

# Using /dev/urandom
echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1

# Output 20 lines from the head
hexdump -C "$tgt"|head -n 20

# /dev/zero
echo "write:0x00"
dd if=/dev/zero of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

# 000を273(oct)で置換して書き込み
echo "write:0xBB"
tr "\000" "\273" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

echo "write:0x33"
tr "\000" "\063" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

echo "write:0xFF"
tr "\000" "\377" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

echo "write:0x77"
tr "\000" "\167" < /dev/zero|dd of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

echo "write:random"
dd if=/dev/urandom of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20

echo "write:0x00"
dd if=/dev/zero of="$tgt" bs=$ddbs count=$tcount $ddopt > /dev/null 2>&1
hexdump -C "$tgt"|head -n 20
sync

# check file or block
# ファイルの場合は削除確認
echo ""
if [ $tgttype == 1 ];then
    rm -i "$tgt"
fi

echo -e "\n---- done ----\n"

exit 0
