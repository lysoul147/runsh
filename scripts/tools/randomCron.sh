#!/usr/bin/env bash

#Author:lysoul147@github

#版本 0.8 


RootDir=$(cd $(dirname $0); cd .. ; cd ..; pwd)
EnvFile="${RootDir}/env/env.sh"
source ${EnvFile}

#绝对值计算
function abs (){
	echo ${1#-};
}

#生成一个$1-$2之间的随机数,作为小时数
function RandomNum(){
	min=$1
	max=$2
    diff=$(($max-$min+1))
	num=$(($RANDOM%$diff + $min ))
}

#传入一个参数$1,调用RandomNum生成一组个数为x的随机小时数，用,隔开
function setHour(){
	for (( i = 0; i < $1; i++ )); do
		[[ $i == 0 ]] && RandomNum "5" "23" && hourlist=${num} && continue
		RandomNum "5" "23"
		limitHour
		while [[ $(echo "$hourlist" | grep -x "${num}") || $w == 1 ]]; do
			RandomNum "5" "23"
			limitHour
		done
		hourlist=$(echo -e "${hourlist}\n${num}")
	done
	hourlist=$(echo "${hourlist}" | sort -n -u | sed ":a;N;s/\n/,/g;$!ba")
	[[ $1 -ge 18 ]] && hourlist="5-23"
}

#传入一个参数$1,调用RandomNum生成一组个数为x的随机分钟数，用,隔开
function setMin(){
	for (( i = 0; i < $1; i++ )); do
		[[ $i == 0 ]] && RandomNum "0" "58" && minlist=${num} && continue
		RandomNum "0" "58"
		limitMin
		while [[ $(echo "$minlist" | grep -x "${num}") || $z == 1 ]]; do
			RandomNum "0" "58"
			limitMin
		done
		minlist=$(echo -e "${minlist}\n${num}")
	done
	minlist=$(echo "${minlist}" | sort -n -u | sed ":a;N;s/\n/,/g;$!ba")
}

#判断num与minlist中每个数的差的绝对值都大于minLimitmin并且小于minLimitmax
function limitMin(){
	for x in $minlist; do
		if [[ $(abs "$(($x-$num))") -lt ${minLimitmin} || $(abs "$(($x-$num))") -ge ${minLimitmax} ]]; then
			z=1
			break
		else
			z=0 #用z判断生成的随机数是否能通过校验，0表示通过
			continue
		fi
	done
}

#判断num与hourlist中每个数的差的绝对值都大于hourLimitmin并且小于hourLimitmax
function limitHour(){
	for y in $hourlist; do
		if [[ $(abs "$(($y-$num))") -lt ${hourLimitmin} ]]; then
			w=1
			break
		else
			w=0 #用y判断生成的随机数是否能通过校验，0表示通过
			continue
		fi
	done
}

#用于拆分解析运行的分钟数和时间数的个数，传入一个数$1,拆分为minCount，hourCount,并且minCount*hourCount=$1
function Count(){
	#判断传入的数是否为偶数，如果不是则+1
	if [[ $(($1%2)) == 1 && $1 -gt 13 ]]; then
		tempnum=$(($1 + 1))
	else
		tempnum=$1
	fi
	#如果传入的数>20，则通过循环使符合条件的minCount尽可能大
	for (( i = 1; i < 6; i++ )); do
		[[ $tempnum -le 20 ]] && break
		[[ ! $(($tempnum%$i)) == 0 ]] && continue
		hourCount=$(($tempnum/$i))
		minCount=$i
	done
	#如果传入的数<=20，则通过循环使符合条件的minCount尽可能小
	for (( i = 4; i >= 2; i-- )); do
		[[ $tempnum -gt 20 ]] && break
		[[ ! $(($tempnum%$i)) == 0 ]] && continue
		hourCount=$(($tempnum/$i))
		minCount=$i
	done
	#处理一些特殊情况
	[[ $1 -lt 13 ]] && hourCount=$1 && minCount=1
	[[ $tempnum -gt 40 && $minCount -le 2 ]] && minCount=$(($minCount+2)) && hourCount=$(($hourCount/2))
	[[	$1 == 37 || $1 == 38 ]] && hourCount=10 && minCount=4
	#echo "生成的分钟次数为${minCount}次,小时次数为${hourCount}次"
}

#根据分钟运行次数限制生成的分钟数的间隔
function setMinLimit(){
	case $minCount in
		1 )
			minLimitmin=30
			minLimitmax=60
			;;
		2 )
			minLimitmin=20
			minLimitmax=25
			;;
		3 )
			minLimitmin=14
			minLimitmax=47
			;;
		4 )
			minLimitmin=9
			minLimitmax=52
			;;
		5 )
			minLimitmin=7
			minLimitmax=54
			;; 
	esac
}

function setHourLimit(){
	case $hourCount in
		[2-4] )
			hourLimitmin=3
			;;
		[5-6] )
			hourLimitmin=2
			;;
		* )
			hourLimitmin=0
			;;
	esac
}


function parameterTest(){
	[[ ! $(echo ${1} | grep '^[0-9]') ]] && echo "${1}不是合法的运行次数，请输入1-60之间的数字" && return 1
	[[ ${1} -lt 1 || ${1} -gt 60 ]] && echo "${1}不是合法的运行次数，请输入1-60之间的数字" && return 1
	return 0
}


function crontablistTest(){
	#判断是否填写crontab.list的值
	[[ ! ${CrontabList} ]] && echo -e "\n未填写Crontab.list文件路径 ❌，请打开本脚本填写" && exit 1
	#判断crontab.list与当前运行的crontab.list是否一致
	[[ ! -f ${CrontabList} ]] && echo -e "\nCrontab.list文件不存在 ❌，请检查填写是否正确" && exit 1
	[[ $(diff -q <(crontab -l) <(cat "${CrontabList}")) ]] && echo -e "当前运行crontab.list与你设置的crontab.list不一致❗️" 
	setrandomCronFile
	return 0
}

#用于校验crontab.list中是否加入了randomCron.sh,以及表达式是否正确
function setrandomCronFile(){
	if [[ ! $(cat ${CrontabList} | grep "${thisDir}/randomCron.sh") ]]; then
		echo -e "rontab.list文件中没有添加本脚本❗️ ，将自动添加“0 0 * * * bash ${thisDir}/randomCron.sh”到crontab.list中"
		echo "######################  设定随机cron脚本  ###########################" >> ${CrontabList}
		echo "#此脚本用于支持配置随机cron，请勿删除或修改cron" >> ${CrontabList}
		echo "0 0 * * * bash ${thisDir}/randomCron.sh" >> ${CrontabList}
		echo "###################################################################" >> ${CrontabList}
	elif [[ ! $(cat ${CrontabList} | grep "^0 0 \* \* \*.\+${thisDir}/randomCron.sh$") ]]; then
		echo -e "crontab.list文件中【bash ${thisDir}/randomCron.sh】的cron表达式错误，自动修正为0 0 * * *"
		sed -i '0,\#.\+ \(bash '${thisDir}'/randomCron.sh\)# s##0 0 * * * \1#' ${CrontabList}
	fi
}

function randomMinCron(){
	if [[ $1 == "-m" ]]; then
		for (( n = 1; n <= ${totalline}; n++ )); do
			line=$(sed -n ''${n}'p' ${CrontabList})
			[[ $(echo "$line" | grep -E "^#|PATH|MAILTO") ]] && continue #排除文档注释、PATH和MAILTO设置行
			[[ ! $(echo "$line") ]] && continue #排除空行
			[[ ! $(echo "$line" | grep '\-r@[0-9]' ) ]] && continue
			minCron=$(echo "$line" | awk -F" " '{printf $1}')
			targetTask=$(echo "$line" | awk -F" " '{printf $8}')
			[[ $(echo "${minCron}" | grep '\-' ) ]] && continue
			minCount=$(echo ${minCron} | grep -o ',' | wc -l)
			let minCount++
			setMinLimit
			setMin "$minCount"
			echo -e "修改第${n}行的【${targetTask}】的cron分钟表达式为:\n【${minlist}】"
			sed -i ''$n's/^[0-9|,]\+ \(.\+\)/'${minlist}' \1/' ${CrontabList}
			echo -e "完成 ✅\n"
		done
		crontab ${CrontabList}
		exit 0
	else
		return
	fi
}

function randomCron(){
	for (( n = 1; n <= ${totalline}; n++ )); do
		line=$(sed -n ''${n}'p' ${CrontabList})
		[[ $(echo "$line" | grep -E "^#|PATH|MAILTO") ]] && continue #排除文档注释、PATH和MAILTO设置行
		[[ ! $(echo "$line") ]] && continue #排除空行
		[[ ! $(echo "$line" | grep '\-r@[0-9]' ) ]] && continue
		isRandomCron=$(echo "$line" | awk -F" " '{printf $NF}')
		[[ ${isRandomCron} ]] && targetTask=$(echo "$line" | awk -F" " '{printf $8}')
		countNum=$(echo ${isRandomCron} | cut -f2 -d'@')
		parameterTest "${countNum}"
		[[ $? == 1 ]] && echo "跳过【${targetTask}】" && continue
		Count $countNum
		setMinLimit
		setMin "$minCount"
		setHourLimit
		setHour "$hourCount"
		if [[ $(echo $line | grep "run.sh") ]]; then
			editCron=$(echo $line | sed -n 's/^.\+ .\+ \(.\+ .\+ .\+ \)bash.\+'${targetTask}' .*\-r@'${countNum}'$/'${minlist}' '${hourlist}' \1/p')
			echo -e "修改第${n}行的【${targetTask}】的cron表达式为:\n【${editCron}】"
			sed -i ''$n's/.\+ .\+ \(.\+ .\+ .\+bash.\+'${targetTask}' .*\-r@'${countNum}'$\)/'${minlist}' '${hourlist}' \1/' ${CrontabList}
			echo -e "完成 ✅\n"
		else
			editCron=$(echo $line | sed -n 's/^[^ ]\+ [^ ]\+ \([^ ]\+ [^ ]\+ [^ ]\+ \).\+\-r@'${countNum}'$/'${minlist}' '${hourlist}' \1/p')
			editCmd=$(echo $line |sed -n 's/^[^ ]\+ [^ ]\+ [^ ]\+ [^ ]\+ [^ ]\+ \(.\+ \-r@'${countNum}'\)/\1/p')
			Cronbefore=$(echo $line |sed -n 's%\(^[^ ]\+ [^ ]\+\) [^ ]\+ [^ ]\+ [^ ]\+ '${editCmd}'%\1%p')
			echo -e "修改第${n}行的【${editCmd}】cron表达式为:\n【${editCron}】"
			sed -i ''$n's%'${Cronbefore}' \([^ ]\+ [^ ]\+ [^ ]\+ '${editCmd}'\)$%'${minlist}' '${hourlist}' \1%' ${CrontabList}
			echo -e "完成 ✅\n"
		fi
	done
}

#定义变量
thisDir=$(cd $(dirname $0); pwd)

#流程控制

crontablistTest
IFS=$'\n'
cronNow=$(cat ${CrontabList})
totalline=$(awk '{print NR}' ${CrontabList} | tail -n1)

randomMinCron $1
randomCron

crontab ${CrontabList}
