#!/bin/bash
# エラーが出た時点で終了するためのもの(最終手段)
# -e で有効化
# +e で無効化
set -e


# usage
# 完成後にヘルプを追記する
function help(){
    then echo -e "Usage\n./shredder.sh target"
    return 0
}

if [ -z "$1" ]
    help
    exit 0
fi


# target
# 第1引数で取得
tgt="$1"


# sudoのバージョン情報をnullに投げる
sudo -V > /dev/null 2>&1


# check file or block 0:block 1:file
# ファイルとブロックデバイスの確認(ディレクトリもここ？)
echo ""
test -b "$tgt"
if [ $? != 0 ]; then
    tgttype=1
else
    tgttype=0
fi

# other dd options
# ToDoに書いたオプションまとめ
ddopt="oflag=direct,sync conv=notrunc,noerror,fsync status=progress"

### ここまで共通

### ここからファイル向け

# 対象がファイルの場合は'df $tgt'
# で格納されているドライブを確認して
# そのドライブのセクタサイズを取得する
tgt_dev=`df $tgt|grep "/dev"|cut -f 1 -d " "`


# dd block size
# fdiskなどで削除対象のブロックサイズを取得予定
ddbs=`fdisk -l /dev/$tgt_dev|grep Sector|awk '{print $(NF-1)}'`
# ddbs=512 <- old_version


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


# delete cache
# メモリ上のキャッシュ削除
echo "delete cache data..."
sync && echo 3 > /proc/sys/vm/drop_caches
dd of="$tgt" $ddopt count=0 > /dev/null 2>&1

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

# パターンでの処理はそれぞれ関数化して番号を割り振って引数として受け取る
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

# ディレクトリは'rm -ri'で削除
# ファイルの場合は削除確認
echo ""
if [ $tgttype == 1 ];then
    rm -i "$tgt"
fi

### ここまでファイル向け

### ここからsdaなどブロックデバイス向け

### ここまでブロックデバイス向け

### 終了処理

echo -e "\n---- done ----\n"

exit 0
