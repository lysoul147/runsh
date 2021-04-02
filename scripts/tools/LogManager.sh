#!/usr/bin/env bash

#Author:lysoul147@github

#版本:1.2 

RootDir=$(cd $(dirname $0); cd .. ; cd ..; pwd)
EnvFile="${RootDir}/env/env.sh"
source ${EnvFile}

[[ ! ${DateRMLog} ]] && DateRMLog=7

LogDir=$(cd $(dirname $0); cd ..; cd ..; cd log ; pwd)
LogDirList=$(cd ${LogDir}; ls -l |grep "^d" |awk '{print $NF}')

#自动归档以往日志
for dir in $LogDirList; do
	cd ${LogDir}/${dir}
	[[ ! $(ls | grep ".log") ]] && continue
	LogList=$(cd ${LogDir}/${dir}; ls *.log | sort)
	for log in ${LogList}; do
		today=$(date +%Y-%m-%d)
		day=$(echo $log | awk -F "-" '{OFS="-"}{print $1,$2,$3}' | sed -e 's/.log//g')
		if [[ $day == $today ]]; then
			continue
		else
			LogRotateDir=$(echo $log | awk -F "-" '{OFS="-"}{print $1,$2,$3}' | sed -e 's/.log//g')
			[[ ! -d ${LogDir}/${dir}/${LogRotateDir} ]] && mkdir ${LogDir}/${dir}/${LogRotateDir}
			cd ${LogDir}/$dir && mv $log ${LogDir}/${dir}/${LogRotateDir}/
		fi
	done
done

#自动删除七天前的日期目录，自动删除空log目录
for dir in $LogDirList; do
	cd ${LogDir}/${dir}
	[[ ! $(ls) ]] &&  rmdir ${LogDir}/${dir} && continue
	LogDateDir=$(ls -l |grep "^d" |awk '{print $NF}' | sort)
	for logdir in ${LogDateDir}; do
		today=$(date +%s)
		logdirdate=$(date -d"$logdir" +%s)
		diff=$(($today - $logdirdate))
		if [[ $diff -gt $((${DateRMLog}*86400)) ]]; then
			rm -rf ${LogDir}/${dir}/$logdir
		fi
	done

done
