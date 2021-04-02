#!/usr/bin/env bash

#Author:lysoul147@github

#V0.1

RootDir=$(cd $(dirname $0); cd .. ; cd ..; pwd)
EnvFile="${RootDir}/env/env.sh"
source ${EnvFile}

FileName=$(echo $(basename $0 | cut -d . -f1))

function PrintProcess(){
        TargetPIDList=$(ps -eo pid,etimes,cmd | grep "$1"| grep -v -E "${Filter}") #获取进程PID及运行时间,过滤掉grep、pm2、和本文件相关进程
        echo -e "\n显示【$1】进程运行时间\n"
        if [[ ${TargetPIDList} ]]; then
                IFS=$'\n'
                for process in ${TargetPIDList}; do
                TargetTime=$(echo ${process} | awk '{print $2}')
                TargetCMD=$(echo ${process} | awk '{print $3,$4,$5,$6,$7}')
                min=$((${TargetTime}/60))
                scd=$((${TargetTime}%60))
                if [[ "${TargetTime}" -gt "$((${TimeCleanMin} * 60))" ]]; then
                        echo -e "-->【${TargetCMD}】\n运行时间：${min}分${scd}秒，超过${TimeCleanMin}分钟，可以清理❗️ "
                    else
                        [[ $(echo ${process} | grep -v "\-c") ]] && echo -e "-->【${TargetCMD}】\n运行时间：${min}分${scd}秒，无需清理 ✅ "
                fi
                done
        else
                echo -e "没有【${1}】相关的进程"
        fi
}

function KillProcess(){
        TargetPIDList=$(ps -eo pid,etimes,cmd | grep "$1"| grep -v -E "${Filter}") #获取进程PID及运行时间,过滤掉Filter
        echo -e "\n清理运行时长超过${TimeCleanMin}分钟的进程【$1】\n"
        if [[ ${TargetPIDList} ]]; then
                IFS=$'\n'
                for process in ${TargetPIDList}; do
                TargetTime=$(echo ${process} | awk '{print $2}')
                TargetCMD=$(echo ${process} | awk '{print $3,$4,$5,$6,$7}')
                min=$((${TargetTime}/60))
                scd=$((${TargetTime}%60))
                if [[ "${TargetTime}" -gt "$((${TimeCleanMin} * 60))" ]]; then
                        kill -15 $(echo ${process} | awk '{print $1}')
                        echo -e "-->【${TargetCMD}】\n运行时间：${min}分${scd}秒，已清理 ❌ "
                    else
                        [[ $(echo ${process} | grep -v "\-c") ]] && echo -e "-->【${TargetCMD}】\n运行时间：${min}分${scd}秒，无需清理 ✅ "
                fi
                done
        else
                echo -e "\n没有【${1}】相关的进程\n"
        fi
}

function muiltTarget(){
        for value in $@; do
                [[ $value == "-k" ]] && continue
                [[ $(echo $value | grep '^[0-9]') ]] && continue
                [[ $z == 1 ]] && KillProcess $value
                [[ $z != 1 ]] && PrintProcess $value
        done
}

#拼接手动设置的过滤关键字和默认关键字
if [[ $SetFilter ]]; then
        Filter="${SetFilter}|${FileName}|grep|pm2|jd_crazy_joy_coin"
else
        Filter="${FileName}|grep|pm2|jd_crazy_joy_coin"
fi


#参数判断
for key in $@; do #遍历参数，如果有-k，则z存在
        [[ $key = "-k" ]] && z=1
done

for value in $@; do #遍历参数，如果有数值，则参数中最大值给SetTime，并存在e
        if [[ $(echo $value | grep '^[0-9]') ]]; then
                if [[ $SetTime -lt $value ]]; then 
                        SetTime=$value
                fi
                e=1
        fi
done
[[ $e == 1 ]] && TimeCleanMin=${SetTime}

case $# in
        0 ) #使用默认的Target和TimeCleanMin，仅显示相关进程信息
                PrintProcess ${Target}
                ;;
        1 )
                if [[ $e == 1 ]]; then
                        PrintProcess ${Target}
                elif [[ $(echo $1 | grep '^[a-zA-Z]') ]]; then
                        Target=$1
                        PrintProcess ${Target}
                elif [[ $z == 1 ]]; then
                        KillProcess ${Target}
                else
                        echo "参数无法识别"
                fi
                ;;
        * ) 
                muiltTarget $@
                ;;
esac

echo -e "\n结束"