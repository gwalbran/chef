#!/bin/bash

declare -i -r LOGFILE_HISTORY_TO_KEEP=7


# runs a talend job
# $1 - script to run
# $2 - config file
# $3 - log directory
# $4 - past log files to keep
run_job() {
    local job_executable=$1; shift
    local config_file=$1; shift
    local log_dir=$1; shift
    local -i files_to_keep=$1; shift

    local log_file="$log_dir/console.log"
    local pid_lock_file="$log_dir/pid.lock"

    # Guard against cron running into already running job
    if [ -f $pid_lock_file ] && [ -d /proc/$(cat $pid_lock_file ) ]; then
        echo "Job already running - will not reschedule" >> "$log_file"
        exit 0
    fi

    # create pid guard
    echo $$ > $pid_lock_file


    # cycle log files in given directory, based on modification time
    local -i i=0
    for file in `ls -1t $log_dir/*console* 2> /dev/null`; do
        if [ $i -ge $files_to_keep ]; then
            rm $file
        fi
        let i=$i+1
    done

    local start_date_secs=`date "+%s"`

    # create new date named logfile and link it for the talend run
    log_file_src="$log_dir/console.`date '+%F-%H-%M-%S' --date @$start_date_secs`.log"
    touch $log_file_src

    # relink logfile
    rm -f $log_file
    ln -s $log_file_src $log_file

    # header for run
    echo "begin;"`date --rfc-3339=seconds --date @$start_date_secs` > $log_file

    # run the talend job
    "$job_executable" --context_param paramFile="$config_file" --context_param logDir="$log_dir" &>> "$log_file"

    local finish_date_secs=`date "+%s"`
    local delta_secs=`expr $finish_date_secs - $start_date_secs`
    local delta_mins=`expr $delta_secs / 60`
    echo "finish;"`date --rfc-3339=seconds --date @$finish_date_secs`" $delta_mins minutes" >> "$log_file"


    # remove the pid guard
    rm $pid_lock_file
}

# prints usage and exit
usage() {
    echo "Usage: $0 -e JOB_EXECUTABLE -c CONFIG_FILE -l LOG_DIR"
    echo "Invokes a talend job."
    echo "
Options:
  -e, --exec                 Executable script.
  -c, --config-file          Configuration file.
  -l, --log-dir              Log directory.
"
    exit 3
}

# main
main() {
    # parse options with getopt
    local tmp_getops=`getopt -o he:c:l: --long help,exec:,config-file:,log-dir: -- "$@"`
    [ $? != 0 ] && usage

    eval set -- "$tmp_getops"
    local job_executable config_file log_dir

    # parse the options
    while true ; do
        case "$1" in
            -h|--help) usage;;
            -e|--exec) job_executable="$2"; shift 2;;
            -c|--config-file) config_file="$2"; shift 2;;
            -l|--log-dir) log_dir="$2"; shift 2;;
            --) shift; break;;
            *) usage;;
        esac
    done

    # verify parameters
    [ x"$job_executable" = x ] && usage
    [ x"$config_file" = x ] && usage
    [ x"$log_dir" = x ] && usage

    run_job $job_executable $config_file $log_dir $LOGFILE_HISTORY_TO_KEEP
}


main "$@"

