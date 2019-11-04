#!/bin/bash

#自动化运维之批量分发文件，实现了分组、独立用户、全部用户操作，支持文件分发

list="/root/admin_list"

if [ ! -f $1 ] || [ $# -lt 2 ]
then
  echo -e "\033[31m ERROR: \033[0m 您输入的源文件不存在..."
  echo -e "\033[31m USAGE: \033[0m ssh_file.sh 本地文件 远程路径"
	exit 1
fi

target=`echo $@ | awk '{print $NF}'`
src=`echo $@ | awk '{$NF="";print}'`
for i in `echo "$src"`
do
	if [ ! -e $i ]
	then
		echo -e "\033[31m  ERROR：本地文件 $i 不存在，请检查后重新输入\033[0m"
		exit 1
	fi
done

ALL(){
for act_ip in `cat $list | grep -v "\<group\>" | sed '1,${s/[ ].*//}'`
do
	act_name=`cat -n $list | awk '/^[ ]+\<'$act'\>/{print $3}' | tr -d "#"`
  echo -e "\033[32m  ===================================== \033[0m"
  echo -e "\033[34m |       $act_name : $act_ip       |\033[0m"
  echo " "
  scp $src $act_ip:$target
  echo " "
done
}

GRP(){
for grp in $grps
do
	echo -e "\033[32m  ===================================== \033[0m"
	echo -e "\033[34m |          当前操作的组：$grp          |\033[0m"
for act_grp in `cat $list | sed -n '/'$grp'\]/,/\[group/{p}' | awk '!/^[[]/{print $1}'`
do
	act_name=`cat -n $list | awk '/^[ ]+\<'$act_grp'\>/{print $3}' | tr -d "#"`
  echo -e "\033[32m  ===================================== \033[0m"
 	echo -e "\033[34m |       $act_name : $act_grp       |\033[0m"
 	echo " "
  scp $src $act_grp:$target
  echo " "
done
done
}

SIG(){
for err in `echo $chos`
do
	cat -n $list | grep -E "^[ ]+\<$err\>" 1>/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo -e "\033[32m===================================== \033[0m"
		echo -e "\033[31m  ERROR:输入的编号<$err>有错误，未执行任何操作，请检查...\033[0m"
		echo -e "\033[32m===================================== \033[0m"
		exit 1
	fi
done

for act in  $chos
do
	cat -n $list | awk '/^[ ]+\<'$act'\>/{print $2}' | grep "\[\<group\>" >/dev/null 2>&1
	[ $? -eq 0 ] && continue
	act_ip=`cat -n $list | awk '/^[ ]+\<'$act'\>/{print $2}'`
	act_name=`cat -n $list | awk '/^[ ]+\<'$act'\>/{print $3}' | tr -d "#"`
	echo -e "\033[32m  ===================================== \033[0m"
	echo -e "\033[34m |       $act_name : $act_ip       |\033[0m"
	echo " "
  scp $src $act_ip:$target
	echo " "
done
}

echo -e "\033[32m  ===================================== \033[0m"
cat -n $list
echo -e "\033[32m  ===================================== \033[0m"
read -p "  请输入你要操作的主机编号或组名：" chos

[[ $chos =~ ^[[:alpha:]] ]] && grps=$chos && x="2"
[[ $chos =~ ^[[:digit:]] ]] && x="3"
[[ $chos =~ ^[[:digit:]]+-[[:digit:]] ]] && x="4"
[[ $chos =~ "all" ]] && x="1"
[[ $chos =~ "q"|"Q" ]] && exit 0

case $x in
	1)
	ALL
	;;
	2)
	GRP
	;;
	3)
	SIG
	;;
	4)
  hd=`echo $chos | awk -F "-" '{print $1}'`
  ed=`echo $chos | awk -F "-" '{print $2}'`
  unset chos
  for((i=$hd;i<=$ed;i++))
  do
    chos=`echo "$chos $i "`
  done
  echo $chos >/dev/null
  SIG
  ;;
	*)
	echo "输入选择错误，不进行任何操作..."
	exit 1
esac
