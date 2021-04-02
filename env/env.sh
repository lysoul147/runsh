#!/usr/bin/env bash
  


##################### 配置 ########################

#UpdateScripts.sh相关设置
DateRmBackup=14 #备份需要保留的日期
ignoreFlag="node_module|activity|backup" #脚本扫描时要排除的目录名，使用|分隔

#LogManager.sh相关设置
DateRMLog=7 #日志需要保留的日期

#AutoClean.sh相关设置
Target=run.sh           #默认清理的进程
TimeCleanMin=60         #默认清理超时，单位分钟
SetFilter=""            #手动配置的过滤关键词，多个关键字用|隔开

#randomCron.sh相关设置
CrontabList="/home/lysoul/runjd/crontab.list" #Crontab.list 文件路径请填写在此变量中

##################################################

#填写你需要定义的ENV变量
#写法示例

#export Cookie="xxx"

#如果xxx中包含双引号，则上面的双引号改为单引号