#!/bin/bash

# 想定外のエラーが出た時点で終了するためのもの(最終手段)
# -e で有効化
# +e で無効化
set -e

# sudoのバージョン情報をnullに投げて処理
# 追記:sudoがコアパッケージになかったのでコメントアウト
#sudo -V > /dev/null 2>&1

# root環境での実行する想定
# 'id -u'でuidが0でのみ実行、
# それ以外の場合はエラーメッセージ出力(仮)
if [ $(id -u) -ne 0 ]; then
  echo "error : root user only"
  exit 1
fi

# 区切り文字を改行のみにする（デフォルトはスペース、タブ、改行）
# default IFS=$' \t\n'
IFS=$'\n'

# usage
# 完成後にヘルプを追記する
function help() {
  echo -e "Usage\n./shredder.sh target"
  return 0
}

if [ -z "$1" ]; then
  help
  exit 0
fi

# target
# 第1引数で取得
# tgt="$1"

# other dd options
# ToDoに書いたオプションまとめ
# ddopt='oflag=nocache conv=notrunc,noerror,fsync status=progress'
ddoopt='oflag=nocache,sync'
# ddoopt='oflag=direct,sync'
ddcopt='conv=notrunc,noerror,fsync'
ddprog='status=progress'

### ここまで共通

# shredder
# ファイル単位での消去は共通なので
# ファイル位置かinode番号を引数で受け取る
function file_shred() {
  # ファイル位置パスを引数で受け取る
  local tfile="$1"

  # ファイルの格納されてるドライブを確認
  tgt_dev=$(df $tfile | grep "/dev" | cut -f 1 -d " "|rev|sed -e "s/[0-9]//g"|cut -f 1 -d "/"|rev)
  if [ -e "$tgt_dev" ]; then
    # tmpfsやdrvfsなどの場合
    #ddbs=512
    ddbs=$(cat /sys/block/"$tgt_dev"/queue/physical_block_size)
  else
    # デバイスのブロックサイズ(論理ではなく物理)を取得
    #ddbs=$(cat /sys/block/$tgt_dev/queue/physical_block_size)
    ddbs=512
  fi

  # get file size (byte)
  # ファイルサイズは取得出来るのでブロックサイズでの余りを足せばいい？
  echo "get size..."
  tsize=$(wc -c "$tgt" | awk '{print $1}')
  echo "$tsize byte"

  # calc dd count
  # file size / block size + 1block
  # とりあえず512byteのドライブが多いからやっつけで
  echo "calc count..."
  ddcount=$(expr $tsize \/ $ddbs \+ 1)
  echo "$ddcount count"

  # delete cache
  # メモリ上のキャッシュ削除
  echo "delete cache data..."
  sync && echo 3 > /proc/sys/vm/drop_caches
  dd of="$tfile" $ddoopt $ddcopt $ddprog count=0 > /dev/null 2>&1

  # ここから下は関数化してループ処理をつくる
  # start dd shredder
  echo -e "\n---- start ----\n"

  # Using /dev/urandom
  echo "write:random"
  dd if=/dev/urandom of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1

  # Output 20 lines from the head
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  # /dev/zero
  echo "write:0x00"
  dd if=/dev/zero of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  # パターンでの処理はそれぞれ関数化して番号を割り振って引数として受け取る
  # 000を273(oct)で置換して書き込み

  echo "write:0x55"
  tr "\000" "\125" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xAA"
  tr "\000" "\252" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0x33"
  tr "\000" "\063" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xCC"
  tr "\000" "\314" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0x77"
  tr "\000" "\167" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xEE"
  tr "\000" "\356" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:random"
  dd if=/dev/urandom of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0x00"
  dd if=/dev/zero of="$tfile" bs=$ddbs count=$ddcount $ddoopt $ddcopt $ddprog > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z
  sync
}

### ここからファイル向け

# ファイル向け関数
function file_and_dir() {
  # local変数としてtmode(FileTarGeT)に第1引数の$1を代入
  ftgt="$1"

  # ファイルかフォルダか判断
  f_or_d=$(
    test -d "$ftgt"
    echo $?
  )
  if [ $f_or_d -eq 1 ]; then
    # 'ls -i'でinode番号を表示
    # 'cut -f 1 -d " "'でinode番号のみ変数へ
    # inode_num=$(ls -i "$ftgt" | cut -f 1 -d " ")
    file_shred "$ftgt"
    rm -i "$ftgt"
  elif [ $f_or_d -eq 0 ]; then
    # findでファイルのみ表示
    for files in $(find "$ftgt" -type f); do
      file_shred "$files"
    done
    rm -r -i "$ftgt"
  else
    echo "ERROR"
    exit 1
  fi
  # ファイルでもディレクトリでもforで回数指定する処理をここに書いたほうがいいかも
}

### ここからsdaなどブロックデバイス向け

function block_delete() {
  if [ -e "$tgt_dev" ]; then
    # tmpfsやdrvfsなどの場合
    #ddbs=512
    ddbs=$(cat /sys/block/"$tgt_dev"/queue/physical_block_size)
  else
    # デバイスのブロックサイズ(論理ではなく物理)を取得
    #ddbs=$(cat /sys/block/$tgt_dev/queue/physical_block_size)
    ddbs=512
  fi
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
  dd if=/dev/urandom of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1

  # Output 20 lines from the head
  head -c "$ddbs" "$tgt"|od -Ax -tx1z

  # /dev/zero
  echo "write:0x00"
  dd if=/dev/zero of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tgt"|od -Ax -tx1z

  # パターンでの処理はそれぞれ関数化して番号を割り振って引数として受け取る
  # 000を273(oct)で置換して書き込み
  
  echo "write:0x55"
  tr "\000" "\125" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xAA"
  tr "\000" "\252" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0x33"
  tr "\000" "\063" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xCC"
  tr "\000" "\314" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0x77"
  tr "\000" "\167" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xEE"
  tr "\000" "\356" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:0xFF"
  tr "\000" "\377" < /dev/zero | dd of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tfile"|od -Ax -tx1z

  echo "write:random"
  dd if=/dev/urandom of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tgt"|od -Ax -tx1z

  echo "write:0x00"
  dd if=/dev/zero of="$tgt" bs=$ddbs $ddopt > /dev/null 2>&1
  head -c "$ddbs" "$tgt"|od -Ax -tx1z
  sync
}

### ここまでブロックデバイス向け

### main
# check file or block 0:block 1:file&dir
# ファイルとブロックデバイスの確認
# ディレクトリの場合は1で
# 'find $tgt'で階層内のファイルを取得

tloc=`pwd -P`
ttgt="$1"
tgt=`echo $tloc/$ttgt`


echo ""
if [ ! -e $tgt ]; then
    tgt="$1"
fi

tgt_type=$(
  test -b "$tgt"
  echo $?
)
if [ $tgt_type -eq 0 ]; then
  #tgt_type=0
  block_delete "$tgt"
elif [ $tgt_type -eq 1 ]; then
  #tgt_type=1
  file_and_dir "$tgt"
else
  echo "### ERROR ###"
  exit 1
fi

### 終了処理

echo -e "\n---- done ----\n"

exit 0
