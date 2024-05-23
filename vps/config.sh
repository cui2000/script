#! /bin/bash
# 此脚本用于更新配置项
# 脚本目录及配置文件
script_path=/home/soft/script
file_path=$script_path/config.ini

# 创建配置文件
function init() {
  if [ ! -f "$script_path/config.ini" ]; then
    mkdir -p $script_path
    echo "创建配置文件：$file_path"
    touch "$file_path"
    echo "script_path $script_path" >> $file_path
    echo "config_path $script_path" >> $file_path
  fi
}

# 更新配置文件
function setValue() {
  key="$1"
  newValue="$2"
  oldValue=$(getValue $key)
  if [ "$oldValue" != "$newValue" ]; then
    if [ -z "$oldValue" ]; then
      echo "$key $newValue" >>$file_path
    else
      sed -i "s/$key $oldValue/$key $newValue/g" $file_path
    fi
  fi
}

function getValue() {
  key="$1"
  eval "cat $file_path | awk '/^$key/{print \$2}'"
}
init
op="$1"
key="$2"
newValue="$3"
if [ "$op" = "get" ]; then
  if [ ! -z "$key" ]; then
    getValue $key
  fi
elif [ "$op" = "set" ]; then
  setValue "$key" "$newValue"
fi
