#!/usr/bin/env bash

#Author:lysoul147@github

#版本 0.9.1


#第一位			第二位			第三位
#↑      		#↑      		#↑
#↑0启用延迟		#↑0启用输出		#↑0使用node
#↑1关闭延迟		#↑1关闭输出		#↑1使用bash
								#↑2使用python 

#000 --> 使用【node】【延迟】执行并【打印日志】
#001 --> 使用【bash】【延迟】执行并【打印日志】
#002 --> 使用【python3】【延迟】执行并【打印日志】
#010 --> 使用【node】【延迟】执行并【不打印日志】
#011 --> 使用【bash】【延迟】执行并【不打印日志】
#012 --> 使用【python3】【延迟】执行并【不打印日志】
#100 --> 使用【node】【不延迟】执行并【打印日志】
#101 --> 使用【bash】【不延迟】执行并【打印日志】
#102 --> 使用【python3】【不延迟】执行并【打印日志】
#110 --> 使用【node】【不延迟】执行并【不打印日志】--> 这是默认的选项
#111 --> 使用【bash】【不延迟】执行并【不打印日志】
#112 --> 使用【python3】【不延迟】执行并【不打印日志】


ScriptsRootDir=$(cd $(dirname $0); cd scripts ; pwd)
ScriptsDirList=$(cd ${ScriptsRootDir}; find | grep -v -E "node_modules/|activity/")
ScriptsNameList=$(echo  "$ScriptsDirList" | awk -F/ '{printf $NF"\n"}' | grep -E ".js$|.py$|.sh$" | sort)
LogDir=$(cd $(dirname $0); cd log ; pwd)
EnvDir=$(cd $(dirname $0); cd env ; pwd)
FileName=$([[ $(echo $1 | grep '@') ]] && echo $1 | cut -f1 -d'@' || echo $1)
EnvName=$([[ $(echo $1 | grep '@') ]] && echo $1 | cut -f2 -d'@')
Extension=
ScriptsDir=


function FindScriptsPath(){
    for scripts in $ScriptsDirList; do
        if [[ $(echo $scripts | awk -F/ '{printf $NF"\n"}') == "${FileName}.${Extension}" ]]; then
            TempScriptsDir=$(echo $scripts | awk -F/ 'OFS="/"{$NF="";print}')
            ScriptsDir=$(cd $ScriptsRootDir; cd ${TempScriptsDir}; pwd)
            return
        fi
    done
}

function FindFileName(){
    for name in ${ScriptsNameList}; do
        if [[ $name == "${FileName}.${Extension}" ]]; then
            return
        fi
    done
    >&2 echo -e "\n在Scripts文件夹中没有找到【${FileName}.${Extension}】脚本，清将脚本放入文件夹中或检查后缀参数是否正确"
    >&2 echo -e "当前Scripts目录下的脚本有：\n"
    >&2 echo -e "$ScriptsNameList\n"
    exit 1
}

function Help(){
	if [[ $# -eq 0 ]]; then
		echo -e "\n请带参数运行，第一个参数必须为脚本名称（不带后缀）"
		echo -e "当前Scripts目录下的脚本有：\n"
		echo -e "$ScriptsNameList\n"
		exit 1
	fi
}

function MakeLogDir(){
	if [[ ${EnvName} ]]; then
		[[ ! -d ${LogDir}/${FileName}@${EnvName} ]] && mkdir ${LogDir}/${FileName}@${EnvName}
		LogDirName=${LogDir}/${FileName}@${EnvName}
		LogFileName=${LogDir}/${FileName}@${EnvName}/$(date "+%Y-%m-%d-%H-%M").log
	else
		[[ ! -d ${LogDir}/${FileName} ]] && mkdir ${LogDir}/${FileName}
		LogDirName=${LogDir}/${FileName}
		LogFileName=${LogDir}/${FileName}/$(date "+%Y-%m-%d-%H-%M").log
	fi
}

function PrintLog(){
	if [[ $b == 0 ]]; then
		echo -e "$1" | tee -a ${LogFileName}
	else
		echo -e "$1"  >> ${LogFileName}
	fi
}

function Env(){
	if [[ -n ${EnvName} ]]; then
		if [[ -f ${EnvDir}/${EnvName}.sh ]]; then
			source ${EnvDir}/${EnvName}.sh
			MakeLogDir #生成Log文件夹
			PrintLog "\n环境变量：${EnvName}.sh"
		else
			>&2 echo -e "\nenv文件夹下没有找到${EnvName}.sh的环境变量文件，请先创建环境变量文件"
			exit 1
		fi
	else
		if [[ -f $EnvDir/env.sh ]]; then
			source $EnvDir/env.sh
			MakeLogDir #生成Log文件夹
			PrintLog "\n环境变量：env.sh"
		else
			MakeLogDir #生成Log文件夹
			PrintLog "\n环境变量：未找到文件"
		fi
	fi
}

function IsRandomDelay(){
	for key in $@; do
		if [[ $key == "-delay" ]]; then
			a="0"
			return
		fi
	done
	a="1"
}

function IsShowLog(){
	for key in $@; do
		if [[ $key == "-v" ]]; then
			b="0"
			return
		elif [[ $(echo $key | grep "\-v@") ]]; then
			local datehour=$(echo $key | cut -f2 -d"@" | cut -f1 -d"_")
			if [[ $(echo $key | grep "_") ]]; then
				local datemin=$(echo $key | cut -f2 -d"@" | cut -f2 -d"_")
			fi
			if [[ $(date +%k) == "$datehour" ]]; then
				if [[ $datemin ]]; then
					if [[ $(date +%M) == "$datemin" ]]; then
						b="0"
						return
					else
						b="1"
						return
					fi
				else
					b="0"
					return
				fi
			fi
		fi
	done
	b="1"
}

function FindLogTime(){
	if [[ ${EnvName} ]]; then
		LogDirName=${LogDir}/${FileName}@${EnvName}
	else
		LogDirName=${LogDir}/${FileName}
	fi
	if [[ -d ${LogDirName} ]]; then
		LogTimes=$(ls -l ${LogDirName}/ | grep "^-.\+.log$" | wc -l )
	else
		LogTimes=0
	fi
}

function IsShowLogTimes(){
	FindLogTime
    for key in $@; do
        if [[ $(echo $key | grep "\-t@") ]]; then
        	local setLogTimes=$(echo $key | cut -f2 -d"@" )
            if [[ $((LogTimes + 1)) == ${setLogTimes} ]]; then
                b="0"
                return
            else
                b="1"
                return
            fi
		fi
    done
}

function IsExe(){
    for key in $@; do
        if [[ $key == "sh" ]]; then
                c="1"
                Extension=sh
                return
        elif [[ $key == "py" ]]; then
                c="2"
                Extension=py
                return
        fi
    done
    c="0"
    Extension=js
}

function RodomDelay(){
		min=60
		max=180
		diff=$(($max-$min))
		num=$(($RANDOM%$diff + $min ))
		PrintLog "等待${num}秒,按Ctrl+C结束"
		sleep ${num}
}

function Execute(){
	case $1 in
		000 )
			PrintLog "脚本名：${FileName}.js"
			RodomDelay
			cd ${ScriptsDir}
			node ${FileName}.js | tee -a ${LogFileName}
			;;
		001 )
			PrintLog "脚本名：${FileName}.sh"
			RodomDelay
			cd ${ScriptsDir}
			bash ${FileName}.sh | tee -a ${LogFileName}
			;;
		002 )
			PrintLog "脚本名：${FileName}.py"
			RodomDelay
			cd ${ScriptsDir}
			python3 ${FileName}.py | tee -a ${LogFileName}
			;;
		010 )
			PrintLog "脚本名：${FileName}.js"
			RodomDelay
			cd ${ScriptsDir}
			node ${FileName}.js >> ${LogFileName}
			;;
		011 )
			PrintLog "脚本名：${FileName}.sh"
			RodomDelay
			cd ${ScriptsDir}
			bash ${FileName}.sh >> ${LogFileName}
			;;
		012 )
			PrintLog "脚本名：${FileName}.py"
			RodomDelay
			cd ${ScriptsDir}
			python3 ${FileName}.py >> ${LogFileName}
			;;
		100 )
			PrintLog "脚本名：${FileName}.js"
			cd ${ScriptsDir}
			node ${FileName}.js | tee -a ${LogFileName}
			;;
		101 )
			PrintLog "脚本名：${FileName}.sh"
			cd ${ScriptsDir}
			bash ${FileName}.sh | tee -a ${LogFileName}
			;;
		102 )
			PrintLog "脚本名：${FileName}.py"
			cd ${ScriptsDir}
			python3 ${FileName}.py | tee -a ${LogFileName}
			;;
		110 )
			PrintLog "脚本名：${FileName}.js"
			cd ${ScriptsDir}
			node ${FileName}.js >> ${LogFileName}
			;;
		111 )
			PrintLog "脚本名：${FileName}.sh"
			cd ${ScriptsDir}
			bash ${FileName}.sh >> ${LogFileName}
			;;
		112 )
			PrintLog "脚本名：${FileName}.py"
			cd ${ScriptsDir}
			python3 ${FileName}.py >> ${LogFileName}
			;;
		* )
			>&2 echo -e "\n不要这么顽皮\n" 
	esac
}

#参数初始化检测
Help $@
IsRandomDelay $@
IsShowLog $@
IsShowLogTimes $@
IsExe $@

if [[ $(echo $2 | grep '^[0-9]') && $(echo ${#2}) -eq 3 ]]; then
	CmdCode=$2
	a=$(echo ${CmdCode:0:1})
	b=$(echo ${CmdCode:1:1})
	c=$(echo ${CmdCode:2:1})
else
	CmdCode=${a}${b}${c}
fi

#验证文件名以及查找文件路径
FindFileName
FindScriptsPath

#导入环境变量
Env
PrintLog "脚本运行开始：$(date +'%Y-%m-%d %H:%M:%S')"
Execute ${CmdCode}
PrintLog "\n脚本运行完成,$(date +'%Y-%m-%d %H:%M:%S')\n"
