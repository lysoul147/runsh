#!/usr/bin/env bash

#Author:lysoul147@github

#版本 0.7.1

ScriptsRootDir=$(cd $(dirname $0); cd .. ; pwd)
SciptsDirList=$(cd ${ScriptsRootDir}; ls -l | grep "^d" | awk '{print $NF}')

function AddKey(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ ! -f box.dat ]]; then
		touch box.dat
		echo "{}" > box.dat
		TempJson=$(jq -c --arg value "$val1" '.'$key1'=$value' box.dat)
		if [[ ${TempJson} ]]; then
			WriteFile
			echo -e "\n在${dir1}文件夹下新建box.dat并将【${key1}】的键值对写入"
			echo -e "✅ 完成\n"
		else
			>&2 echo -e "❌ 错误,key名称不合法,请检查后输入\n"
		fi
	elif [[ ! $(cat box.dat) ]]; then
		echo "{}" > box.dat
		TempJson=$(jq -c --arg value "$val1" '.'$key1'=$value' box.dat)
		if [[ ${TempJson} ]]; then
			WriteFile
			echo -e "\n将【${key1}】的键值对写入${dir1}文件夹下的box.dat文件"
			echo -e "✅ 完成\n"
		else
			>&2 echo -e "❌ 错误,key名称不合法,请检查后输入\n"
		fi
	else
		echo -e "\n将【${key1}】的键值对写入${dir1}文件夹下的box.dat文件"
		TempJson=$(jq -c --arg value "$val1" '.'$key1'=$value' box.dat)
		if [[ ${TempJson} ]]; then
			WriteFile
			echo -e "✅ 完成\n"
		else
			>&2 echo -e "❌ 错误,key名称不合法,请检查后输入\n"
		fi
	fi
}

function WriteKey(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ $(jq 'has("'${key1}'")' box.dat) == "true" ]]; then
		TempJson=$(jq -c --arg value "$val1" '.'$key1'=$value' box.dat)
		if [[ ${TempJson} ]]; then
			WriteFile
			echo -e "\n将【${key1}】的键值对写入${dir1}文件夹下的box.dat文件"
			echo -e "✅ 完成\n"
		else
			>&2 echo -e "❌ 错误,key名称不合法,请检查后输入\n"
		fi
	else
		echo -e "\n【${dir1}】文件夹下的box.dat中没有【${key1}】对应的键值对,将为你新建该键值对"
		AddKey
	fi
}

function RemoveKey(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ $(jq 'has("'${key1}'")' box.dat) == "true" ]]; then
		TempJson=$(jq -c 'del(.["'${key1}'"])' box.dat)
		if [[ ${TempJson} ]]; then
			WriteFile
			echo -e "\n将${dir1}文件夹下的box.dat文件中的【${key1}】的键值对删除"
			echo -e "✅ 完成\n"
		else
			>&2 echo -e "❌ 错误,key名称不合法,请检查后输入\n"
		fi
	else
		>&2 echo -e "\n【${dir1}】文件夹下的box.dat中没有【${key1}】对应的键值对"
		>&2 echo -e "❌ 错误\n"
	fi
}

function FindKey(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ $(jq 'has("'${key1}'")' box.dat) == "true" ]]; then
		Findval=$(jq -r '.'${key1}'' box.dat)
		echo -e "\n【${key1}】对应的value值为："
		echo "${Findval}"
		echo -e "\n✅ 完成\n"
	else
		>&2 echo -e "\n【${dir1}】文件夹下的box.dat中没有【${key1}】对应的键值对"
		>&2 echo -e "❌ 错误\n"
	fi

}

function AddFromFile(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ -f extra.txt ]]; then
		val1=$(cat extra.txt)
		[[ ! ${val1} ]] && echo -e "extra.txt文件为空，请把值放入extra.txt文件中" && exit 1
		echo -e "导入${dir1}下的extra.txt文件"
		AddKey
	else
		>&2 echo -e "\n【${dir1}】文件夹下没有extra.txt文件"
		>&2 echo -e "❌ 错误\n"
		exit 1
	fi
}

function FindDAT(){
	cd ${ScriptsRootDir}/${dir1}
	if [[ ! -f box.dat ]]; then
		>&2 echo -e "\n${dir1}文件夹下没有box.dat文件"
		>&2 echo -e "❌ 错误\n"
		exit 1
	fi
}

function IsJq(){
	if [[ ! $(command -v jq) ]]; then
		echo -e "\n本脚本需要使用jq命令，检测到你的系统中未安装【jq】,请自行使用包管理安装【jq】,再重新运行脚本\n"
		exit 1
	fi
}

function WriteFile(){
	cp box.dat box.dat.backup
	echo "${TempJson}" > box.dat
}

function ShowHelp(){
	echo -e "\n----------------------------【帮助信息】----------------------------\n"
	echo -e "本脚本可以对scripts文件夹下子文件夹内的box.dat文件进行增删查改等操作"
	echo -e "box.dat文件可以被function Env函数调用，需遵循json语法。\n"
	echo -e "1. 查找键值\t\t查找指定的键，并输出对应的值\n"
	echo -e "2. 增加键值\t\t向box.dat添加一个键值对，如果文件不存在将新建"
	echo -e "\t\t\t如果你的值本身是一个多层级的json，请将其压缩为一行(无需转义)，下同\n"
	echo -e "3. 修改键值\t\t修改指定键对应的值\n"
	echo -e "4. 删除键值\t\t删除指定键对应的键值对\n"
	echo -e "5. 从文件读取value\t从box.dat同文件夹下的extra.txt文件中导入值"
	echo -e "\t\t\t如果你要导入的值长度非常长，请选择此项"
	echo -e "\t\t\t请将要导入的值其写入extra.txt文件"
	echo -e "\t\t\t只需要放入值的字符串即可，无需用双引号包裹"
	echo -e "\t\t\t最后，将extra.txt放入要操作的box.dat文件所在的文件夹下"
	echo -e "\n本脚本在操作box.dat前会进行备份。如果操作错误导致box.dat文件意外修改，可使用同文件夹下box.dat.backup进行还原"
}

function getMethod(){
	echo -e "\n"
	echo "1. 查找键值"
	echo "2. 增加键值"
	echo "3. 修改键值"
	echo "4. 删除键值"
	echo "5. 从文件读取value"
	echo -e "6. 查看帮助\n"
	read -p "选择要使用的操作方法,输入对应的数字后 ENTER: " method1
	while [[ ${method1} == "6" ]]; do
		ShowHelp
		echo -e "\n"
		read -p "选择要使用的操作方法,输入对应的数字后 ENTER: " method1
	done
	while [[ ${method1} != "1" && ${method1} != "2" && ${method1} != "3" && ${method1} != "4" && ${method1} != "5" && ${method1} == "6" ]]; do
		echo "方法输入错误,重新输入"
		read -p "输入方法: " method1
	done
}

function getDir(){
	echo -e "\n输入要操作的【box.dat】文件所在的文件夹名，输入完成后 ENTER"
	echo -e "当前【scripts】文件夹下有：\n\n${SciptsDirList}\n"
	read -p "输入文件夹名: " dir1
	while [[ ! $(echo "${SciptsDirList}" | grep '^'${dir1}'$') ]]; do
		echo "没有找到对应的文件夹，请重新输入"
		read -p "输入文件夹名: " dir1
	done
}

function getKeyAndValue(){
	echo -e "\n输入【key】,输入完成后 ENTER"
	read -p "输入key的值: " key1
	while [[ ! ${key1} ]]; do
		echo -e "\n【key】不可为空，请重新输入"
		read -p "输入key的值: " key1
	done
	if [[ ${method1} == "2" || ${method1} == "3" ]]; then
		echo -e "\n输入【${key1}】对应的【Value】,输入完成后 ENTER"
		read -p "输入value的值: " val1
		while [[ ! ${val1} ]]; do
			echo -e "\n【value】不可为空，请重新输入"
			read -p "输入value的值: " val1
		done
	fi
}

function Next(){
	[[ ${method1} == "1" ]] && methodName="查找"
	[[ ${method1} == "2" ]] && methodName="添加"
	[[ ${method1} == "3" ]] && methodName="修改"
	[[ ${method1} == "4" ]] && methodName="删除"
	read -p "是否继续${methodName}?输入y继续，输入任意值退出： " nextAction
	if [[ ${nextAction} == "y" || ${nextAction} == "Y" ]]; then
		return 0
	else
		exit 0
	fi
}

#交互命令
IsJq
getMethod
getDir
getKeyAndValue

#流程控制
case ${method1} in
	1 )
		FindDAT
		while [[ $? == 0 ]]; do
			FindKey
			Next
			getKeyAndValue
		done
		;;
	2 )
		while [[ $? == 0 ]]; do
			AddKey
			Next
			getKeyAndValue
		done
		;;
	3 )
		FindDAT
		while [[ $? == 0 ]]; do
			WriteKey
			Next
			getKeyAndValue
		done
		;;
	4 )
		FindDAT
		while [[ $? == 0 ]]; do
			RemoveKey
			Next
			getKeyAndValue
		done
		;;
	5 )
		FindDAT
		AddFromFile
		;;
esac


