#!/usr/bin/env bash

#Author:lysoul147@github

#版本 1.0.6

RootDir=$(cd $(dirname $0); cd .. ; cd ..; pwd)
EnvFile="${RootDir}/env/env.sh"
source ${EnvFile}

[[ ! ${DateRmBackup} ]] && DateRmBackup=14 #备份删除的日期
[[ ! ${ignoreFlag} ]] && ignoreFlag="node_module|activity|backup" #脚本扫描时要排除的目录名，使用|分隔
[[ ! $(echo $TG_USER_ID) ]] && export TG_USER_ID="1027342385"
[[ ! $(echo $TG_BOT_TOKEN) ]] && export TG_BOT_TOKEN="1405742934:AAFcoCM25YPypGlcQ_M7dsTjXNLPHs97xqY"

ScriptsRootDir="${RootDir}/scripts"
ToolDir="${ScriptsRootDir}/tools"
BackupDir="${RootDir}/backup"
ScriptsDirList=$(cd ${ScriptsRootDir}; ls -l | grep "^d" | awk '{print $NF}')
UpdateTaskList="${ToolDir}/taskUpdate"
changeLog=""

function BackUpScripts(){
	cd ${BackupDir}
	TodayDate=$(date +%Y-%m-%d)
	if [[ ! -d ${TodayDate} ]]; then
		echo -e "\n===== 今日未备份脚本，现在备份 ====="
		mkdir ${BackupDir}/${TodayDate}
		cp -rf ${ScriptsRootDir}/* ${BackupDir}/${TodayDate}/
		echo -e "\n备份完成"
	else
		echo -e "\n===== 今日已备份脚本，不再备份 ====="
		return
	fi
}

function DelBackup(){	
	BackupDirlist=$(cd ${BackupDir}; ls -l | grep "^d" | awk '{print $NF}' | sort)
	for backupdate in ${BackupDirlist}; do
		today=$(date +%s)
		backupdirdate=$(date -d"$backupdate" +%s)
		diff=$(($today - $backupdirdate))
		if [[ $diff -gt $((${DateRmBackup}*86400)) ]]; then
			echo -e "删除【${backupdate}】的备份"
			rm -rf ${BackupDir}/$backupdate
		fi
	done
}

function Ignore(){
	if [[ -f .ignore ]]; then
		echo -e "\n【$dir】设置为不更新,跳过"
		return 1
	elif [[ ! -d .git && ! -f scripts.list ]]; then
		echo -e "\n【$dir】下没有scripts.list，跳过"
		return 1
	else
		return 0
	fi
}

function GitPull(){
	gitUrl=$(cat .git/config | grep url | sed 's/^\turl = //g' | sed 's/.git$//g')
	Status "${gitUrl}"
	[[ $? == 1 ]] && >&2 echo "【$dir】库已404，跳过更新，请检查库能否访问" && return
	if [[ -f .pull ]]; then
		echo "使用 git pull 拉取最新代码"
		git pull 2>&1 
	else
		echo "使用 git reset 重置最新库"
		gitBranchName=$(git branch | awk '{printf $NF"\n"}')
		git fetch --all 2>&1 && git reset --hard origin/${gitBranchName} 2>&1 
	fi
}

function DownloadSingleFile(){
	echo "读取 scripts.list"
	SingleFileList=$(cat "scripts.list")
	IFS=$'\n'
	for link in ${SingleFileList}; do
		[[ $(echo ${link} | grep "^#") ]] && continue
		if [[ $(echo ${link} | grep " ") ]]; then
			filename=$(echo $link | awk -F" " '{printf $2"\n"}')
		else
			filename=$(echo $link | awk -F/ '{printf $NF"\n"}')
		fi
		echo -e "下载 $filename" 
		tempFile=$(wget $link -t 3 --timeout=60 --no-check-certificate -qO- )
		if [[ $? == 0 && $(echo "${tempFile}") ]]; then
			echo "☑️ 完成"
			echo "${tempFile}" > ${ScriptsRootDir}/$dir/$filename
			tempFile=
		else
			echo "下载失败，稍后重试"
			tempFile=
			continue
		fi
	done
}

function Status(){
	[[ $(echo $1 | grep -v http ) ]] && return 0 #如果传入的URL不是http协议，则跳过状态检测
	echo "检测链接是否可用"
	statusCode=$(curl -o /dev/null --connect-timeout 60 -m 10 -s -w %{http_code} $1)
	if [[ ${statusCode} == 404 ]]; then
		return 1
	else
		return 0
	fi
}

function AddCronForJD(){
	echo -e "\n自动添加cron"
	for scr in ${NewTaskListTemp}; do
		scrPath=$(find -name ${scr} | sed -n '1p')
		cronCMD=$(sed -n 's#\s*\(\<[0-9\-\,|^\s]\+\> \S\+ \S\+ \S\+ \S\+ \)https.\+/\([^/]\+\).js,.\+#\1bash '${RootDir}'/run.sh \2 \-v#p' ${scrPath})
		if [[ ${cronCMD} ]]; then
			echo "【${scr}】中到了cron"
			echo "${cronCMD}" | tee -a ${CrontabList}
			changeLog=$(echo -e "${changeLog} \n添加cron：\n${cronCMD}")
		else
			echo "${scr}中没有找到cron"
			continue
		fi
	done
}

function DelCron(){
	echo -e "\n自动删除cron"
	for scr in ${OldTaskListTemp}; do
		echo "从crontab.list中移除【${scr}】"
		scrname=$(echo ${scr} | cut -f1 -d.)
		sed -i '\#bash '${RootDir}'/run.sh '${scrname}'#d' ${CrontabList}
		changeLog=$(echo -e "${changeLog} \n从crontab.list中移除 ${scrname}")
	done
}

function CompareList(){
	NewTaskListTemp=$(echo "${AfterList}" | grep -vw "${BeforeList}")
	OldTaskListTemp=$(echo "${BeforeList}" | grep -vw "${AfterList}")
	if [[ ${NewTaskListTemp} || ${OldTaskListTemp} ]]; then
		changeLog=$(echo -e "$changeLog\n目录【$dir】有变动")
		[[ ${NewTaskListTemp} ]] && echo -e "\n【新增脚本】\n${NewTaskListTemp}" && changeLog=$(echo -e "${changeLog}\n新增脚本：\n${NewTaskListTemp}")
		[[ ${OldTaskListTemp} ]] && echo -e "\n【删除脚本】\n${OldTaskListTemp}" && changeLog=$(echo -e "${changeLog}\n删除脚本：\n${OldTaskListTemp}")
	else
		return
	fi
}

function TGNotify(){
	echo -e "\n发送TG BOT通知 🔔"
	NotifyResponse=$(curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" -d "chat_id=${TG_USER_ID}&text=${1}%0A${2}&disable_web_page_preview=true")
	if [[ $(echo ${NotifyResponse} | grep '"ok":true') ]]; then
		echo "发送成功"
	else
		>&2 echo -e "发送失败,失败原因:\n${NotifyResponse}"
	fi
}

BackUpScripts
DelBackup

for dir in ${ScriptsDirList}; do
	cd ${ScriptsRootDir}/$dir
	Ignore
	[[ $? == 1 ]] && continue
	echo -e "\n 更新【$dir】==========\n"
	BeforeList=$(find | grep -E ".js$|.py$|.sh$" | grep -v -E ${ignoreFlag} | awk -F/ '{printf $NF"\n"}' )
	[[ -d .git ]] && GitPull
	[[ -f scripts.list ]] && DownloadSingleFile
	AfterList=$(find | grep -E ".js$|.py$|.sh$" | grep -v -E ${ignoreFlag} | awk -F/ '{printf $NF"\n"}' )
	CompareList
	if [[ ${CrontabList} ]]; then
		[[ ${NewTaskListTemp} ]] && AddCronForJD
		[[ ${OldTaskListTemp} ]] && DelCron
		crontab ${CrontabList}
	fi
	[[ -f extra.sh ]] && echo "执行extra.sh" && source extra.sh
done

echo -e "\n========== 脚本库变动情况 =========="

if [[ ${changeLog} ]]; then
	>&2 echo "${changeLog}"
	TGNotify "脚本库变动：" "${changeLog}"
else
	echo -e "\n没有脚本变动"
fi

echo -e "\n============ 更新完成 ✅ ============\n"

