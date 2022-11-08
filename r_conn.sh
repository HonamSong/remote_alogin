#!/bin/bash 

_version_=" 0.0.4"

# 스크립트 실행 경로
SCRIPT_PATH=$(cd $(echo $0 | xargs dirname) ; pwd ; cd - > /dev/null )
# 스크립트 실행 파일 이름
SCRIPT_NAME=$(echo $0 | xargs basename | sed "s/.sh//g")

SCRIPT_PID="$$"
TEMP_FILE="${SCRIPT_PATH}/serverlist.tmp"
EXPECT_TEMP_FILE="${SCRIPT_PATH}/expect_temp"

### [REMOTE COMMAND] ###
#REMOTE_SSH_CMD="/usr/bin/ssh -oStrictHostKeyChecking=no"
REMOTE_SSH_CMD="/usr/bin/ssh -oTCPKeepAlive=no -oServerAliveInterval=120 -oStrictHostKeyChecking=no"
REMOTE_SCP_CMD="/usr/bin/scp -oStrictHostKeyChecking=no"
REMOTE_SFTP_CMD="/usr/bin/sftp -oStrictHostKeyChecking=no"

null_string=$(printf "    ")
export is_show_log="false"
export sep_len=${sep_len:-0}
export is_show_send_cmd='false'
##################################################################################################3
## add  .bashrc
# ex =>  echo "alias r_conn='sh /app/test/r_conn.sh'" >> ~/.bashrc ; source  ~/.bashrc

#####  USER - Modify >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#서버 리스트 파일 
SVR_LIST="${SCRIPT_PATH}/conn_info"
MENU_TITLE="TB_SEVER_CONNECTOR"
##### <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
##################################################################################################3


_version(){
	printf "%s Version : %s\n" "${SCRIPT_NAME}" "${_version_}"
}

_banner() {
banner="
   ____  _   _ _____ _     ____   ____
  / / / | | | | ____| |   |  _ \\  \\ \\ \\
 / / /  | |_| |  _| | |   | |_) |  \\ \\ \\
 \\ \\ \\  |  _  | |___| |___|  __/   / / /
  \\_\\_\\ |_| |_|_____|_____|_|     /_/_/
"
printf "\t%s" "${banner}"
}

show_print(){
	if [ "${is_show_log}" == "true" ] ; then 
		printf " ++ %s\n" "$1"
	fi
}


delete_file() {
	if [ -f "${1}" ]; then 
		show_print "${SCRIPT_NAME}.${LINENO} | CMD) rm -rf ${1}"
		rm -rf ${1}
	fi
}

int_handler() {
	printf "\nKeyboard Interrupted. ( Ctrl + c) \n"
	delete_file "${TEMP_FILE}"
	delete_file "${EXPECT_TEMP_FILE}"
	#if [ -f "${TEMP_FILE}" ]; then 
	#	rm -rf ${TEMP_FILE}
	#fi

	# Kill the parent process of the script.
	kill -9 ${SCRIPT_PID}
	exit 1
}

print_liner() {
	line_str=${1:-"^"}
	loop_cnt=${2:-100}

	start_num=1
	while [ ${start_num} -le ${loop_cnt} ] ; do
		printf "%s" "${line_str}"
		if [ ${start_num} -eq ${loop_cnt} ]; then 
			printf "\n"
		fi
		start_num=$(( ${start_num} + 1 ))
	done
}

_help() {
	_banner;
	printf "\n  + Version : ${_version_}\n"
	printf "\n\n"
	printf "usage) $0 [options]\n\n"
	print_liner "=" "50"

	printf "\n"
	printf "  [ Option ]\n\n"
	
	printf "    %-15s\t%s\n" "-h, --help"    "Help"
	printf "    %-15s\t%s\n" "--is_debug"    "Debug mode"
	printf "    %-15s\t%s\n" "--is_showlog"  "print the log"
	printf "    %-15s\t%s\n" "--is_showsend" "print connect command"
}

add_line_num() {
	start_line=1
	end_line=100000
	group_name="$1"	
	is_break="false"

	echo " ** group_name : ${group_name}"

	cat < ${SVR_LIST} | grep -Ei "^<<.*${group_name}.*>>$" > /dev/null
	if [ $? -eq 0 ] ; then 
		while [ ${start_line} -le ${end_line} ]; do
			show_print "${SCRIPT_NAME}.${LINENO} | CMD) sed -n ${start_line}p ${SVR_LIST} | grep -Ei \"${group_name}\" > /dev/null"
			sed -n ${start_line}p ${SVR_LIST} | grep -Ei "${group_name}" > /dev/null
			if [ $? -eq 0 ] ; then 
				start_line=$((${start_line} + 1))
				while true ; do 
					show_print "${SCRIPT_NAME}.${LINENO} | CMD) sed -n ${start_line}p ${SVR_LIST} | grep -E \"^<<|^\[\" > /dev/null "
					sed -n ${start_line}p ${SVR_LIST} | grep -E "^<<|^\[" > /dev/null 
					if [ $? -eq 0 ] ; then 
						add_line=$((${start_line} - 1))
						is_break="true"
						show_print "${SCRIPT_NAME}.${LINENO} | Add line num : ${add_line} , is_break = ${is_break}"
						break;
					else
						start_line=$((${start_line} + 1))
					fi
				done
			else
				show_print "${SCRIPT_NAME}.${LINENO} | start_line : ${start_line}"
				start_line=$((${start_line} + 1))
			fi

			if [ "${is_break}" == "true" ] ; then 
				start_line=$((${start_line} + ${end_line}))
				show_print "${SCRIPT_NAME}.${LINENO} | add_line True , start_line=${start_line}"
			fi
		done
	else
		if [ $(cat < ${SVR_LIST} | grep -Ei "^<< ETC >>$" > /dev/null ; echo $?) -eq 0 ]; then 
			group_add_line=$(($(cat -n < ${SVR_LIST} | grep -Ei "<< ETC >>$" | awk '{print $1}') - 1))
			show_print "${SCRIPT_NAME}.${LINENO} | CMD) sed -i \"${group_add_line} i\\\n<< $(echo ${group_name} | tr [:lower:] [:upper:]) >>\" ${SVR_LIST}"
			sed -i "${group_add_line} i\\\n<< $(echo ${group_name} | tr [:lower:] [:upper:]) >>" ${SVR_LIST}
		else
			show_print "${SCRIPT_NAME}.${LINENO} | CMD) printf << $(echo ${group_name} | tr [:lower:] [:upper:]) >>"
			printf "\n<< $(echo ${group_name} | tr [:lower:] [:upper:]) >>\n\n" >> ${SVR_LIST}
		fi
		add_line=$(cat < ${SVR_LIST}|wc -l)
		show_print "${SCRIPT_NAME}.${LINENO} | var.add_line = ${add_line}"
	fi
}


add_host() {

	while true; do
		if [ -f "${SVR_LIST}" ] ; then 
			#echo " SERVER List File  :  ${SVR_LIST} +++++++++++++++++"
			printf "\n ++ SERVER List File  :  ${SVR_LIST} +++++++++++++++++\n"
			printf "%s\n\n\n" "$(cat ${SVR_LIST})" 
			#echo ""
		fi

		read -e -p " + Input) Group Name ? " add_groupname
		read -e -p " + Input) Hostname ? " add_hostname
		while true; do 
			read -e -p " + ${re_cmd}Input) IP Address ? " add_ip_addr
	
			reg_ip_addr='[1-9]|[1-9][0-9]|[1-2][0-9][0-9]'
			if [ $( echo ${add_ip_addr} | grep -E "(${reg_ip_addr}?)\.(${reg_ip_addr}?)\.(${reg_ip_addr}?)\.(${reg_ip_addr})$"  > /dev/null; echo $?) -eq 0 ] ; then 
				break;
			else
				printf "\tErr) %s\n" "Not IP Address Partern!! .. \"${add_ip_addr}\""
				printf "\n%s\n" " ==>>> Retry input!!"
				re_cmd="RE-"
			fi
			
		done
		read -e -p " + Input) User Login Name ? " add_username
		read -e -p " + Input) User Login Password? " add_passwd
		read -e -p " + Input) Connection Type (ssh or telnet / Default: ssh) ? " add_type
		read -e -p " + Input) Connection Port ? " add_port
		read -e -p " + Input) Connection Gateway (Default:None)? " add_gateway

		if [ -z "${add_groupname}" ] ; then 
			add_groupname="ETC"
		fi

		if [ -z "${add_type}" ] ; then 
			add_type='ssh'
		fi

		if [ -z "${add_port}" ] ; then 
			if [ "$(echo ${add_type}| tr [:upper:] [:lower:])" == "ssh" ] ; then 
				add_port="22"
			elif [ "$(echo ${add_type}| tr [:upper:] [:lower:])" == "telnet" ] ; then
				add_port="23"
			else
				read -e -p " + Connection Port ? " add_port
			fi
		fi

		if [ -z "${add_gateway}" ] ; then 
			add_gateway=""
		fi


		while true; do 
			if [ -z "${add_passwd}" ] ; then 
				read -e -p " + User Login Password? " add_passwd
			else
				break;
			fi
		done

		while true; do 
			if [ -z "${add_passwd}" ] ; then 
				read -e -p " + User Login Password? " add_passwd
			else
				break;
			fi
		done
				

		input_server_info="${add_hostname}\t${add_ip_addr}\t${add_username}\t${add_passwd}\t${add_type}\t${add_port}\t${add_gateway}"
		add_line_num "${add_groupname}"
		printf "${input_server_info}\n"
		sed -i "${add_line} i\\${input_server_info}"  ${SVR_LIST}

		echo ""
		read -e -p "* Would you like to continue adding? (y/n) " ans_continue
		case ${ans_continue} in 
			[Nn] | [Nn][Oo] )
				printf "\n\tReturn to Menu list!!\n"
				break
			;;
			*)
				printf "\n Continue adding....\n"
			;;
		esac
	done
}

del_host() {
        while true; do
                echo ""
                read -e -p "** WARN) Delete Server Name or Num(index) ? " ans_del_server

		 "${ans_del_server}"
		del_server_name=$(get_grep_keyword "${ans_del_server}" "${ans_del_server}")
		select_server=$(cat < ${TEMP_FILE} | grep -i "${del_server_name}" | awk '{print $3}')
		del_hostname=$(echo ${select_server} | awk -F '(' '{print $1}')
		del_ipaddr=$(echo ${select_server} | awk -F '(' '{print $2}' | sed -e "s/)//g")
		show_print "${SCRIPT_NAME}.${LINENO} | del_server_name: ${del_server_name} , select_server: ${select_server}"
		printf " - Delete List Info : $(cat < ${SVR_LIST} | grep -E "^${del_hostname}.*${del_ipaddr}")\n"
		
                read -e -p "Do you want to real delete? (y/n)  ? " ans_delete
		case ${ans_delete} in 
			[Yy] | [Yy][Ee][Ss] )
				show_print "${SCRIPT_NAME}.${LINENO} | CMD) sed -i \"/^${del_hostname}.*${del_ipaddr}/d\" ${SVR_LIST}"
				sed -i "/^${del_hostname}.*${del_ipaddr}/d" ${SVR_LIST}
			;;
			*)
				printf  "Not Delete :  $(cat < ${SVR_LIST} | grep -E "^${del_hostname}.*${del_ipaddr}")\n"
			;;
		esac

		
                echo ""
                read -e -p "* Would you like to Delete Continue? (y/n) " ans_del_continue
                case ${ans_del_continue} in
                        [Nn] | [Nn][Oo] )
                                printf "\n\tReturn to Menu list!!\n"
                                break
                        ;;
                        *)
                                printf "\n Delete Continue ....\n"
                        ;;
                esac
        done

}

wait_continue() {
	while true ; do
		echo ""
		read -e -p " ++ Return to Main ? (y/n) " ans_wait_continue
		case ${ans_wait_continue} in 
			[Yy] | [Yy][Ee][Ss] )
				break
				;;
			*)
				continue
				;;
		esac
	done
}

word_count() {
	max_len=0

	if [ -f "${SVR_LIST}" ] ; then 
		server_list=$(cat < "${SVR_LIST}" |  grep -Ev "^#|^$|<<.*>>" | awk '{print$1 "(" $2 ")"}')
	
		for slist in ${server_list} ; do 
			len=$(echo ${slist} | wc -c)
			if [ ${len} -ge ${max_len} ] ; then 
				max_len=${len}
			fi
		done
	fi

	echo ${max_len}
}

sep_print() {

	local start=1
	local end=$1

	while [ ${start} -le ${end} ] ; do
		if [ ${start} -eq 1 ] ; then 
			printf "\t+"
		elif [ ${start} -eq ${end} ] ;then
			printf '-'
			printf "+\n"
		else
			printf '-'
		fi
		start=$((${start} + 1))
	done
	
}


title_print() {
	local sep_len=$(echo "$(printf "${null_string}%-${1}s${null_string}" "${line_text}")" | wc -c)
	sep_print ${sep_len}
	printf "\t|${null_string}%-${1}s${null_string}|\n" "++ ${MENU_TITLE} ++"
	sep_print ${sep_len}
	title_len=${sep_len}
}

script_mgmt_print() {
	local tool_start_num=91
	local sep_len=$(echo "$(printf "${null_string}%-${1}s${null_string}" "${line_text}")" | wc -c)
	sep_print ${title_len}
	printf "\n\n"
	sep_print ${title_len}
	tool_name='
	Show(ServerList)
	Add(ServerList)
	Delete(ServerList)
	'
	for tool_item in ${tool_name}; do 
		#tool_name=$(echo ${tool_item} | sed -e "s/_/ /g")
		tool_name="${tool_item}"
		printf "\t|${null_string}%03d. %-${1}s${null_string}|\n" ${tool_start_num} "${tool_name}"
		tool_start_num=$(( ${tool_start_num} + 1 ))	
	done

	select_show_num=$(cat ${TEMP_FILE} | grep -i show | awk '{print$2}' | sed -e "s/\.//g")
	select_add_num=$(cat ${TEMP_FILE} | grep -i add | awk '{print$2}' | sed -e "s/\.//g")
	select_del_num=$(cat ${TEMP_FILE} | grep -i delete | awk '{print$2}' | sed -e "s/\.//g")
}

script_view_print() {
	local tool_start_num=101
	local sep_len=$(echo "$(printf "${null_string}%-${1}s${null_string}" "${line_text}")" | wc -c)
	tool_name='
	view_connecting_log_on
	view_connecting_log_off
	print_Log_on
	print_Log_off
	Debug_on
	Debug_off
	'
	printf "\t|${null_string}%3s  %-${1}s${null_string}|\n" " " " "
	for view_item in ${tool_name}; do 
		view_name="${view_item}"
		printf "\t|${null_string}%03d. %-${1}s${null_string}|\n" ${tool_start_num} "${view_name}"
		tool_start_num=$(( ${tool_start_num} + 1 ))	
	done

	select_view_conn_on_num=$(cat ${TEMP_FILE} | grep -i view_connecting_log_on | awk '{print$2}' | sed -e "s/\.//g")
	select_view_conn_off_num=$(cat ${TEMP_FILE} | grep -i view_connecting_log_off | awk '{print$2}' | sed -e "s/\.//g")
	select_print_log_on_num=$(cat ${TEMP_FILE} | grep -i print_log_on | awk '{print$2}' | sed -e "s/\.//g")
	select_print_log_off_num=$(cat ${TEMP_FILE} | grep -i print_log_off | awk '{print$2}' | sed -e "s/\.//g")
	select_debug_on_num=$(cat ${TEMP_FILE} | grep -i debug_on | awk '{print$2}' | sed -e "s/\.//g")
	select_debug_off_num=$(cat ${TEMP_FILE} | grep -i debug_off | awk '{print$2}' | sed -e "s/\.//g")
}

exit_print() {
	local sep_len=$(echo "$(printf "${null_string}%-${1}s${null_string}" "${line_text}")" | wc -c)
	#sep_print ${title_len}
	
	printf "\t|${null_string}%3s  %-${1}s${null_string}|\n" " " " "
	printf "\t|${null_string}%03d. %-${1}s${null_string}|\n" 999 "Quit(Exit)"
	sep_print ${title_len}

	select_exit_num=$(cat ${TEMP_FILE} | grep -i "exit" | awk '{print$2}' | sed -e "s/\.//g")
}

init_serverlist() {
	printf " -- Not fount file : \"${SVR_LIST}\"\n"
	printf " -- Add connection serverlist\n"

	if [ $(cat  ${SVR_LIST} | grep -E "^# HOSTNAME.*GATEWAY$"> /dev/null; echo "$?") -ne 0 ] ; then
		printf "# HOSTNAME\tIP_ADDRESS\tUSER_NAME\tPASSWORD\tSSH/TELNET\tPORT\tGATEWAY\n" > ${SVR_LIST}
	fi
	add_host;
}


list_print() {
	start_line=1
	server_index=1
	group_index=1

	max_string_len=$(word_count)
	if [ -f "${SVR_LIST}" ] ; then 
		#end_line=$(cat < ${SVR_LIST} | grep -Ev "^#" | wc -l)
		end_line=$(cat -n < ${SVR_LIST} | tail -1 | awk '{print $1}')
		show_print "${SCRIPT_NAME}.${LINENO} | end_line = ${end_line}"

		if [ ${end_line} -ne 0 ] ;then 
			while [ ${start_line} -le ${end_line} ] ; do
				# 주석과 공백 라인 제거
				line_text=$(sed -n ${start_line}p ${SVR_LIST}| grep -Ev "^#|^$") 
				if [ -n "${line_text}" ] ; then 
					if [ $(echo "${line_text}" |grep -E "<<.*>>" > /dev/null ; echo $?) -eq 0 ] ; then 
						group_name_len=$((${max_string_len} + 5))
						sep_len=$(echo "$(printf "${null_string}%-${group_name_len}s${null_string}" "${line_text}")" | wc -c)	
						if [ ${group_index} -eq 1 ] ; then 
							title_print ${group_name_len} >  ${TEMP_FILE}
						fi
						sep_print ${sep_len} >>  ${TEMP_FILE}
						printf "\t|${null_string}%-${group_name_len}s${null_string}|\n" "${line_text}"	>>  ${TEMP_FILE}
						group_index=$((${group_index} + 1))
					else
						server_name=$(echo ${line_text} | awk '{print $1 "(" $2 ")"}')
						printf "\t|${null_string}%03d. %-${max_string_len}s${null_string}|\n" "${server_index}" "${server_name}" >>  ${TEMP_FILE}
						server_index=$((${server_index} + 1))
					fi 
				fi

				start_line=$((${start_line} + 1))
				if [ ${start_line} -gt ${end_line} ] ; then 
					show_print "${SCRIPT_NAME}.${LINENO} | start_line: ${start_line} , end_line : ${end_line}"
					script_mgmt_print ${max_string_len} >>  ${TEMP_FILE}
					script_view_print ${max_string_len} >>  ${TEMP_FILE}
					exit_print ${max_string_len} >>  ${TEMP_FILE}
					start_line=$((${end_line} + 1000))	
				fi
				
			done 
			#done > ${TEMP_FILE}
		else
			init_serverlist;
			list_print;
		fi
	else
		init_serverlist;
		list_print;
	fi
}

get_parser() {
	local ip_addr="$1"
	local host_name="$2"

	if [ -z "${host_name}" ] && [ -n "${ip_addr}" ] ; then 
		get_grep_keyword="${ip_addr}"
	elif [ -n "${host_name}" ] && [ -z "${ip_addr}" ] ; then 
		get_grep_keyword="^${host_name}"
	else
		get_grep_keyword="^${host_name}.*${ip_addr}"
	fi

	show_print "${SCRIPT_NAME}.${LINENO} | get_grep_keyword : ${get_grep_keyword}"

	remote_hostname=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $1}')
	remote_ip_addr=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $2}')
	user_name=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $3}')
	user_passwd=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $4}')
	conn_type=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $5}')
	conn_port=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $6}')
	conn_gateway=$(cat < ${SVR_LIST} | grep -E "${get_grep_keyword}"| awk '{print $7}')

	show_print "${SCRIPT_NAME}.${LINENO} | ${remote_hostname}, ${remote_ip_addr}, ${user_name}, ${user_passwd}, ${conn_type}, ${conn_port}, ${conn_gateway}"
}


expect_command() {
	local conn_ip_addr="$1"
	local user_name="$2"
	local user_passwd="$3"
	local conn_type="$4"
	local conn_port="$5"
	local next_conn=$(echo ${6:-"false"} | tr [:upper:] [:lower:])

	show_print "${SCRIPT_NAME}.${LINENO} | input args : ${*}"
	set Prompt "\[#$%>\]"

	case "${conn_type}" in 
		[Ss][Ss][Hh])
			if [ "${next_conn}" == "false" ] ; then 
				a_text="spawn -noecho ${REMOTE_SSH_CMD} -p${conn_port} ${user_name}@${conn_ip_addr}"
			elif [ "${next_conn}" == "true" ] ; then
				a_text="expect -timeout 1 '\[#$%>\]'\nsend \"${REMOTE_SSH_CMD} -p${conn_port} ${user_name}@${conn_ip_addr}\\r\""
			fi
		;;
		[Tt][Ee][Ll][Nn][Ee][Tt] )
			if [ "${next_conn}" == "false" ] ; then 
				a_text="spawn -noecho telnet ${conn_ip_addr}\nexpect -timeout 1 'login:'\nsend \"${user_name}\\r\""
			elif [ "${next_conn}" == "true" ] ; then
				a_text="\nexpect -timeout 1 '\[#$%>\]'\nsend \"telnet ${conn_ip_addr}\\r\"\nexpect -timeout 1 'login:'\nsend \"${user_name}\\r\""
			fi
		;;
		*)
			printf "\tError] Not connect type only ssh or telnet!\n"
			printf "\tError] Now remote connect type is \"${conn_type}\"\n"
			printf "\tscript exit.....\n"
			exit 1
		;;
	esac
	
	show_print "${SCRIPT_NAME}.${LINENO} | a_text :  ${a_text}"
	
}

create_expect_command() {

	local user_name="$1"
	local user_passwd="$2"
	local conn_ip_addr="$3"
	local conn_hostname="$4"
	local conn_port="$5"

	delete_file "${EXPECT_TEMP_FILE}"

	get_parser "${conn_ip_addr}" "${conn_hostname}"
	gw_svr_info[0]=$(cat < ${SVR_LIST} | grep -Ev "^#" | grep -E "^${conn_hostname}.*${conn_ip_addr}")
	show_print "${SCRIPT_NAME}.${LINENO} | conn_gateway = ${conn_gateway}"

	if [ ${conn_gateway} ] ; then 
		tmp_conn_ip_addr=${conn_ip_addr}
		tmp_conn_hostname=${conn_hostname}
	
		while_index=1
		while true; do
			get_parser "${tmp_conn_ip_addr}" "${tmp_conn_hostname}"
			show_print "${SCRIPT_NAME}.${LINENO} | whileloop[${while_index}] | IP : ${tmp_conn_ip_addr} , conn_svr : ${tmp_conn_hostname} , conn_type: ${conn_type}, gw_svr : ${conn_gateway} "
			if [ ${conn_gateway} ] && [ $(echo ${conn_gateway}|wc -c) -ge 1 ]; then
				if [ $(echo ${conn_gateway} | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null ; echo $?) -eq 0 ] ; then 
					gw_svr_info[${while_index}]=$(cat < ${SVR_LIST} | grep -Ev "^#" | grep -E "${conn_gateway}")
					show_print "${SCRIPT_NAME}.${LINENO} | CMD) cat < ${SVR_LIST} | grep -Ev \"^#\" | grep -E \"${conn_gateway}\""
					show_print "${SCRIPT_NAME}.${LINENO} |  ==> result : gw_svr_info[${while_index}] : ${gw_svr_info[${while_index}]}"
				else
					gw_svr_info[${while_index}]=$(cat < ${SVR_LIST} | grep -Ev "^#" | grep -E "^${conn_gateway}")
					show_print "${SCRIPT_NAME}.${LINENO} | CMD) cat < ${SVR_LIST} | grep -Ev \"^#\" | grep -E \"^${conn_gateway}\""
					show_print "${SCRIPT_NAME}.${LINENO} |  ==> result : gw_svr_info[${while_index}] : ${gw_svr_info[${while_index}]}"
				fi


				tmp_conn_hostname=$(echo "${gw_svr_info[${while_index}]}" | awk '{print $1}')
				tmp_conn_ip_addr=$(echo "${gw_svr_info[${while_index}]}" | awk '{print $2}')
				show_print "${SCRIPT_NAME}.${LINENO} | tmp_conn_hostname = ${tmp_conn_hostname} , tmp_conn_ip_addr = ${tmp_conn_ip_addr}"

				while_index=$(( ${while_index} + 1))
			else
				break
			fi
			
			sleep 0.5
			#printf "\n\n"
		done
	fi


	show_print "${SCRIPT_NAME}.${LINENO} | array count : ${#gw_svr_info[@]}\n"
	start_cnt=$(( ${#gw_svr_info[@]} - 1))
	total_conn_cnt=${#gw_svr_info[@]}
	remote_conn_cnt=1
	while [ ${start_cnt} -ge 0 ] ; do 
		r_ip_addr=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $2}')
		r_user_name=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $3}')
		r_user_pass=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $4}')
		r_conn_type=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $5}')
		r_conn_port=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $6}')
		r_gw_svr=$(echo ${gw_svr_info[${start_cnt}]} | awk '{print $7}')
		if [ ${r_gw_svr} ] ;then 
			r_next_conn="true"
		else
			r_next_conn="false"
		fi
		
		show_print "${SCRIPT_NAME}.${LINENO} | Seach start_cnt : ${start_cnt} | ${gw_svr_info[${start_cnt}]}"
		expect_command   "${r_ip_addr}"  "${r_user_name}"  "${r_user_pass}"  "${r_conn_type}"  "${r_conn_port}" "${r_next_conn}"
		b_text="expect -timeout 1 'ssword:'"
		c_text="send \"${r_user_pass}\\r\""
		if [ "${is_show_send_cmd}" == "false" ] ; then 
			echo_text="puts \"Remote Server Connecting...(${remote_conn_cnt}/${total_conn_cnt}) \""
		else
			echo_text=""
		fi
		#	echo_text="puts \"..Remote Server Connecting...[ ${remote_conn_cnt}/${total_conn_cnt} ] \""
		{
			echo -e "${a_text}"
			echo -e "${b_text}"
			echo -e "${c_text}"
			echo -e "${echo_text}"
		} >> ${EXPECT_TEMP_FILE}
		start_cnt=$(( ${start_cnt} - 1 ))
		remote_conn_cnt=$(( ${remote_conn_cnt} + 1 ))
	done

	#printf "${gw_svr_info[*]}\n"
	show_print "${SCRIPT_NAME}.${LINENO} | get gateway loop finished"
	#echo $(cat < ${EXPECT_TEMP_FILE})

set Prompt "\[#$%>\]"
expect_command="
$(eval cat ${EXPECT_TEMP_FILE})
interact
"
unset gw_svr_info
unset a_text 
unset b_text
unset c_text
unset echo_text

}

conn_remote() {

create_expect_command $*

if [ "${is_show_send_cmd}" == "true" ] ; then 
expect -c "
${expect_command}
"
else
expect -c "
log_user 0
${expect_command}
"
fi

delete_file "${EXPECT_TEMP_FILE}"
}



get_grep_keyword() {
	local select_index=${2:-"${ans_select}"}
	select_keyword="$1"
	
	if [ $(echo "${select_index}" | grep -E "[a-z]|[A-Z]|\.|\*|\(|\)|\[|\]" > /dev/null ; echo $?) -eq 0 ] ; then 
		grep_keyword="${ans_select}"
	else
		grep_keyword=$(printf "%03d" "${select_index}")
	fi
	
	echo "${grep_keyword}"
}

connector() {
	local remote_ip="$1"
	local remote_hostname="$2"
	#echo "get_parser \"${remote_ip}\" \"${remote_hostname}\""

	get_parser "${remote_ip}" "${remote_hostname}"
	conn_remote "${user_name}" "${user_passwd}" "${remote_ip_addr}" "${remote_hostname}" "${conn_port}"
		
	#if [ $(echo ${conn_type} | tr "[A-Z]" "[a-z]") == "ssh" ] ; then 
	#	conn_remote "${user_name}" "${user_passwd}" "${remote_ip_addr}" "${remote_hostname}" "${conn_port}"
	#elif [ $(echo ${conn_type} | tr "[A-Z]" "[a-z]") == "telnet" ] ; then
	#	conn_telnet "${user_name}" "${user_passwd}" "${remote_ip_addr}" "${remote_hostname}"
	#fi
	#sleep 0.5
}


select_server() {
	if [ -f ${TEMP_FILE} ] ; then 
		rm -rf "${TEMP_FILE}"
	fi

	local is_break="false"

	trap 'int_handler' INT
	unset conn_servers

	input_text="Connect serve num(index) or name"

	while true; do 
		printf "\n\n\n\n"
		
		debug_stat=$(set -o | grep "xtrace" | awk '{print $(NF)}')
		clear
		printf "\n<< $(date) >>\n"
		printf "\t - %-21s : %s\n" "Debug Mode"          "${debug_stat}"
		printf "\t - %-21s : %s\n" "Show Logging"        "${is_show_log}"
		printf "\t - %-21s : %s\n" "View Connecting Log" "${is_show_send_cmd}"
		list_print;
		cat ${TEMP_FILE}
		echo ""

		while true; do 
			read -e -p $"${null_string}Input) ${input_text} ? " ans_select
			case ${ans_select} in 
				 "$(echo ${select_exit_num})" | "$(echo "${select_exit_num#0}")" | [Ee][Xx][Ii][Tt] | [Qq][Uu][Ii][Tt] )
					echo "finished script!"
					exit 0 
				;;
				* ) 
					grep_keyword=$(get_grep_keyword "${ans_select}")
					conn_servers=$(cat < ${TEMP_FILE} | grep -E "${grep_keyword}")
					if [ $? -eq 0 ] ; then 
						break
					else
						printf "\t ==> WARN] Not found Select Name or Num , Input Select is \"${ans_select}\"\n"
					fi
				;;
			esac
		done

		if [ -n "${ans_select}" ]; then 
			case ${ans_select} in 
				"$(echo ${select_show_num})" | "$(echo "${select_show_num#0}")"  | [Ss][Hh][Oo][Ww])
					printf "\n\n"
					print_liner ">" 100
					printf "\n\tShow config server list!\n"
					print_liner "*" 100
					printf "CMD ) cat ${SVR_LIST}\n"
					print_liner "<" 100
					cat < ${SVR_LIST}
					wait_continue;
					;;
				"$(echo ${select_add_num})" | "$(echo "${select_add_num#0}")" | [Aa][Dd][Dd])
					show_print "${SCRIPT_NAME}.${LINENO} | Choice: Add Serverlist"
					add_host;
					sleep 1
					;;
				"$(echo ${select_del_num})" | "$(echo "${select_del_num#0}")" | [Aa][Dd][Dd])
					echo "Delete Serverlist"
					del_host;
					sleep 1
					;;
				"$(echo ${select_view_conn_on_num})" | "$(echo "${select_view_conn_on_num#0}")" | "view_connecting_log_on")
					export is_show_send_cmd="true"
					;;
				"$(echo ${select_view_conn_off_num})" | "$(echo "${select_view_conn_off_num#0}")" | "view_connecting_log_off")
					export is_show_send_cmd="false"
					;;
				"$(echo ${select_print_log_on_num})" | "$(echo "${select_print_log_on_num#0}")" | [Pp][Rr][Ii][Nn][Tt]_[Ll][Oo][Gg]_[Oo][Nn])
					export is_show_log="true"
					;;
				"$(echo ${select_print_log_off_num})" | "$(echo "${select_print_log_off_num#0}")" | [Pp][Rr][Ii][Nn][Tt]_[Ll][Oo][Gg]_[Oo][Ff][Ff])
					export is_show_log="false"
					;;
				"$(echo ${select_debug_on_num})" | "$(echo "${select_debug_on_num#0}")" | [Dd][Ee][Bb][Uu][Gg]_[Oo][Nn])
					echo "Debug mode ON!!!!!"
					sleep 1
					set -x
					;;
				"$(echo ${select_debug_off_num})" | "$(echo "${select_debug_off_num#0}")" | [Dd][Ee][Bb][Uu][Gg]_[Oo][Ff][Ff])
					set +x
					echo "Debug mode OFF!!!"
					sleep 2
					;;
				*)
					if [ "${conn_servers}" ] ;then 
						break
					fi
					#grep_keyword=$(get_grep_keyword "${ans_select}")
					#conn_servers=$(cat < ${TEMP_FILE} | grep -E "${grep_keyword}")
					#if [ $? -eq 0 ] ; then 
					#	if [ $(echo "${conn_servers}" | wc -l) -ge 1 ]; then
					#		printf "\n\n"
					#		is_break="true"
					#		break
					#	fi
					#else
					#	printf "\t -- Not found Select Name or Num : ${ans_select}\n"
					#fi
					;;
			esac
		fi
	done

	while true; do

		if [ $(echo "${conn_servers}" | wc -l) -eq 1 ]; then 
			get_hostinfo=$(echo ${conn_servers} | sed -e "s/\(\ \|\t\|\\(|\\)\)//g")
			conn_hostname=$(echo ${get_hostinfo} | awk -F '[|()]' '{print $1}' | awk -F '[.]' '{print $(NF)}')
			conn_ip=$(echo ${get_hostinfo} | awk -F '[|()]' '{print $2}')
			break
		else
			printf "\n\n\t ++ Re-Select Server ++\n"
			printf "\t ++ Re-Select Server ++\n"
			sep_print ${sep_len}
			printf "${conn_servers}\n" | tee ${TEMP_FILE}
			sep_print ${sep_len}
			echo ""
			read -e -p $"${null_string}Re-Input) Re Select ${input_text} ? " ans_select
			grep_keyword=$(get_grep_keyword "${ans_select}")
			conn_servers=$(cat < ${TEMP_FILE} | grep -E "${grep_keyword}")
		fi

		sleep 0.2
	done

	connector "${conn_ip}" "${conn_hostname}"

	select_server;

}

_arg_parser(){
	args_s_num=1
	args_e_num=$#
	debug_mode="False"
	while [[ ${args_s_num} -le ${args_e_num} ]] ; do
		argu=$(eval echo "\$${args_s_num}")
		case ${argu} in
			"--is_showlog")
				export is_show_log="true"
				#break
			;;
			"--is_showsend")
				export is_show_send_cmd="true"
				#break
			;;
			"--is_debug")
				debug_mode="True"
				#set -x
				#break
			;;
			"--version" | "-V" | "-v" )
				_version
				exit 0 
			;;
			"--help" | "-h" | * )
				_help
				exit 0 
			;;
		esac
		args_s_num=$(( ${args_s_num} + 1 ))
	done

	if [ "${debug_mode}" == "True" ] ; then 
		set -x
	fi	
}


main() {
	_arg_parser $*
	select_server;
}

main $*
