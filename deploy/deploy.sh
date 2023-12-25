#!/usr/bin/env bash

profile= #运行环境，由shell参数指定，如： ./deploy start dev
application_name="${build.finalName}"
application_jar="${application_name}.jar"
log_file="logs/${application_name}.log"
# 注意修改其中的address端口号，表示远程debug端口号
# REMOTE_DEBUG="-agentlib:jdwp=transport=dt_socket,address=9082,server=y,suspend=n"
REMOTE_DEBUG=""
JAVA_OPTS="-Xms512m -Xmx1024m -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Duser.timezone=GMT+08"
pid= #进程pid

#检测pid
function getPid() {
    # 获取当前运行的进程pid
    pid=`ps -ef | grep ${application_name} | grep -v grep | awk '{print $2}'`
    if [[ ${pid} ]]; then
        echo "进程运行pid：${pid}"
    else
        echo "进程未运行"
    fi
}

# 创建logs目录
function mkdirLogs() {
    if [ ! -d logs  ]; then
      mkdir logs
    fi
}

#启动程序
function start() {
    mkdirLogs
    echo "当前运行环境：----------- ${profile} ------------------"

    #启动前，先停止之前的进程
    stop

    echo -e "\n开始启动程序>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    java -jar $REMOTE_DEBUG $JAVA_OPTS ${application_jar} --spring.profiles.active=${profile} > ${log_file} &

    #判断启动结果，是否有启动进程
    getPid
    if [[ ${pid} ]]; then
        echo "进程启动成功"
    else
        echo "启动失败"
    fi
}

# 停止程序
stop() {
    getPid
    # 如果进程ID不为空
    if [[ ${pid} ]]; then
        echo -n "正在停止进程: ${pid} "
        # 杀死进程并等待进程退出
        kill -15 ${pid} && wait_for_process_exit "${pid}"
        echo -e "\n进程 ${pid} 停止成功"
    fi
}

# 判断程序是否已经停止
wait_for_process_exit() {
    local pidKilled=$1
    local begin=$(date +%s)
    local end
    while kill -0 $pidKilled > /dev/null 2>&1
    do
        echo -n "."
        sleep 1;
        end=$(date +%s)
        # 添加超时判断，30秒超时后，强制杀死进程
        if [ $((end-begin)) -gt 30  ]; then
            echo -en "\n进程 $pidKilled 停止超过30秒，直接 kill -9 结束进程"
            kill -9 ${pid}
            break;
        fi
    done
}

#启动时带参数，根据参数执行
if [ ${#} -ge 1 ]
then
    case ${1} in
        "start")
            profile=${2}
            start
        ;;
        "restart")
            profile=${2}
            start
        ;;
        "stop")
            stop
        ;;
        *)
            echo "${1}无任何操作"
        ;;
    esac
else
    echo "
    command如下命令，指定操作和环境：
    start test/prod：启动
    stop：停止进程
    restart test/prod：重启

    示例命令如：./deploy start test/prod
    "
fi