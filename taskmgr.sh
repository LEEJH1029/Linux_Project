#!/bin/bash

# IFS: 문자열을 필드로 분리하는 데 사용되는 구분자. 문자열을 공백 문자 대신 개행 문자로 필드를 분리하기 위해 사용
IFS=$'\n'

# 변수 초기화
declare -i NAME_CURSOR=0
declare -i PS_CURSOR=-1
declare -i START_POINT=0
declare -a PROCESS_COMPARE_PID_LIST=()

# 본문 내용을 출력하는 부분
function Show()
{
	declare -i INDEX

	# 출력화면에서 20개를 기준으로 각 상황에 맞는 커서 위치를 지정
	if [ ${#PID_LIST[@]} -le 20 ]; then
		if [ $PS_CURSOR -ge ${#PID_LIST[@]} ]; then
			PS_CURSOR=$((${#PID_LIST[@]} - 1))
		fi
	else
		if [ $START_POINT -gt $((${#PID_LIST[@]} - 20)) ]; then
			START_POINT=$((${#PID_LIST[@]} - 20))
		fi
	fi

	clear

	echo 'Ctrl + O: MEM 순으로 정렬'
	echo 'Ctrl + U: CPU 순으로 정렬'
	echo '프로세스를 선택한 후 Enter키를 입력하면 두 프로세스끼리 비교하는 기능을 사용할 수 있습니다.'
	echo 'k 또는 K를 입력하면 프로세스를 종료할 수 있습니다.'
	echo 'q 또는 Q를 입력하면 프로그램을 종료할 수 있습니다.'
	echo '  '

	echo '-NAME-----------------COMMAND--------------PID-----START-----CPU-----MEMORY--'

	# 리스트에 저장된 값을 출력하는 부분
	for num in $(seq 0 20)
	do
		printf '|'

		if [ $num -eq $NAME_CURSOR ]; then
			printf '\e[100m'
		fi

		printf '%20s\e[0m|' ${NAME_LIST[$num]:0:20}

		if [ $num -eq $PS_CURSOR ]; then
			printf '\e[45m'
		fi

		INDEX=$START_POINT+$num

		printf '%-20s|' ${CMD_LIST[$INDEX]:0:20}
		printf '%7s|' ${PID_LIST[$INDEX]:0:7}
		printf '%9s\e[0m|' ${START_LIST[$INDEX]:0:9}
		printf '%5s %%\e[0m|' ${CPU_LIST[$INDEX]:0:5}
	        printf '%5s %%\e[0m|\n' ${MEM_LIST[$INDEX]:0:5}
	done

	echo '-----------------------------------------------------------------------------'
}

# 초기 화면을 구현한 부분
function InitPage()
{
        clear


        echo ' __                         __         '
        echo '/\ \__                     /\ \        '
        echo '\ \  _\     __       ____  \ \ \/ \    '
        echo ' \ \ \/   / __ \    /  __\  \ \   <    '
        echo '  \ \ \_ /\ \_\ \_ /\__, `\  \ \ \\`\  '
        echo '   \ \__\\ \__/ \_\\/\____/   \ \_\ \_\'
        echo '    \/__/ \/__/\/_/ \/___/     \/_/\/_/'
 
        echo ' '
        echo ' '

                                                  
        echo '  ___ ___       __       ___      __        __        __     _ __  '
        echo ' / __` __`\   / __`\    /  _ \   / __`\    / _ `\    / __`\ /\  __\'
        echo '/\ \/\ \/\ \ /\ \_\.\_ /\ \/\ \ /\ \_\ \_ /\ \_\ \  /\ \__/ \ \ \ '
        echo '\ \_\ \_\ \_\\ \__/.\_\\ \_\ \_\\ \__/ \_\\ \____ \ \ \____\ \ \_\ '
        echo ' \/_/\/_/\/_/ \/__/\/_/ \/_/\/_/ \/__/\/_/ \/____\ \ \/____/  \/_/ '
        echo '                                             /\____/               '
        echo '                                             \_/__/                '

 	echo ' '
        echo '                          리눅스활용실습 '
        echo ' '
        echo ' '
        echo '계속 하려면 엔터 키를 입력해주세요....'
        read -n 1 -s
                         

}

# 백그라운드에서 두 작업의 사용량을 비교해주는 부분
function Compare()
{
	read -p "몇 초동안 작동시킬까요? " sec

	end_time=$((SECONDS + sec))

	# 각 인자로 넘어온 PID를 입력한 시간에 맞게 cpu, mem을 파일에 저장하는 부분
	while [ $SECONDS -lt $end_time ]; do
    		ps -p $1 -o %cpu= >> top_output_1_cpu.txt &
    		ps -p $1 -o %mem= >> top_output_1_mem.txt &
		ps -p $2 -o %cpu= >> top_output_2_cpu.txt &
		ps -p $2 -o %mem= >> top_output_2_mem.txt &
    		sleep 1
	done

	echo "Process 1: $1"

	echo "%CPU"
	awk -v sec="$sec" '{sum_cpu += $1} END { print "평균 CPU 사용량 : " sum_cpu/sec}' ./top_output_1_cpu.txt

	echo "%MEM"
	awk -v sec="$sec" '{sum_mem += $1} END { print "평균 MEM 사용량 : " sum_mem/sec}' ./top_output_1_mem.txt

        echo " "
        echo "Process 2: $2"

 	echo "%CPU"
	awk -v sec="$sec" '{sum_cpu += $1} END { print "평균 CPU 사용량 : " sum_cpu/sec}' ./top_output_2_cpu.txt

	echo "%MEM"
	awk -v sec="$sec" '{sum_mem += $1} END { print "평균 MEM 사용량 : " sum_mem/sec}' ./top_output_2_mem.txt

	# 생성한 파일을 삭제시켜줌으로써 초기화해줌
        rm top_output_1_cpu.txt;
        rm top_output_2_cpu.txt;
        rm top_output_1_mem.txt;
        rm top_output_2_mem.txt

}

# 엔터키를 입력한 PID를 리스트에 저장하는 부분 
function CheckPID()
{
	clear

	echo "현재 선택한 PID는 ${PID_LIST[$START_POINT+$PS_CURSOR]}입니다."
	echo " "
 

	echo '선택한 프로세스들의 목록입니다.'
	echo ' '
	for item in "${PROCESS_COMPARE_PID_LIST[@]}"; do
		process_name=`top -bn 1 -c | awk -v pid=$item '$1 == pid {for(i=12; i<=NF; i++) printf "%s ", $i; print ""}'`
		echo "프로세스 이름: $process_name"
		echo "PID: $item"
		echo '---------------------------------------------------------------------'
	done

	LIST_SIZE=${#PROCESS_COMPARE_PID_LIST[@]}


	if [ $LIST_SIZE -eq 2 ]
		then
			program_pid_1=${PROCESS_COMPARE_PID_LIST[0]}
                        program_pid_2=${PROCESS_COMPARE_PID_LIST[1]}

			local output=$(Compare "$program_pid_1" "$program_pid_2")
			PROCESS_COMPARE_PID_LIST=()
			gnome-terminal -- bash -c "echo '$output'; read -p 'Press enter to close this window'"
	fi

	echo ' '
        echo ' '
        echo '계속하려면 엔터키를 입력해주세요....'
	read -n 1 -s
}

# 프로세스를 강제 종료시킬 때 NAME과 현재 사용자가 일치하지 않으면 에러를 출력하는 부분 
function NoPermission()
{
	clear

	echo ' '
        echo '                               __  __             '
        echo '                              /\ \/\ \            '
        echo '                              \ \ `\\ \     ___   '
        echo '                               \ \ , ` \   / __`\ '
        echo '                                \ \ \`\ \ /\ \_\ \'
        echo '                                 \ \_\ \_\\ \____/'
        echo '                                  \/_/\/_/ \/___/ '
        echo '                                '
        echo ' ____                          '                                                                         
        echo '/\  _`\                               __                     __               '      
        echo '\ \ \_\ \   __    _ __    ___ ___    /\_\     ____    ____  /\_\     ___     ___   ' 
        echo ' \ \  __/ / __`\ /\` __\/  __` __`\  \/\ \   / ,__\  / ,__\ \/\ \   / __`\ /  _ `\  '
        echo '  \ \ \/ /\  __/ \ \ \/ /\ \/\ \/\ \  \ \ \ /\__, `\/\__, `\ \ \ \ /\ \_\ \/\ \/\ \ '
        echo '   \ \_\ \ \____\ \ \_\ \ \_\ \_\ \_\  \ \_\\/\____/\/\____/  \ \_\\ \____/\ \_\ \_\'
        echo '    \/_/  \/____/  \/_/  \/_/\/_/\/_/   \/_/ \/___/  \/___/    \/_/ \/___/  \/_/\/_/'
        echo ' '
                                                        

	echo ' '
	echo '계속하려면 엔터키를 입력해주세요....'
	read -n 1 -s
}



# 실제 프로그램 작동을 위한 부분 

# 초기화면 출력
InitPage


# 작업관리자 화면

# ps에서 cpu순으로 정렬하여 변수에 저장
ps_result="ps aux --sort=-%cpu"
SORT_ASC=''

while [ true ]
do
	# ps_result의 인자를 가져옴
	PS_RESULT=`eval "$ps_result"`

	# PS_RESULT에서 COMMAND 부분을 추출
	GET_CMD=`echo "$PS_RESULT" | head -1 | grep -bo COMMAND | cut -d ':' -f 1`

	# PS_RESULT에서 맨 위에 정보들이 나와있는 행을 지움(sed 명령어 사용)
	PS_RESULT=`sed '1d' <<< "$PS_RESULT"`

	# PS_RESULT에서 NAME 부분을 가져옴
	NAME_LIST=(`echo "$PS_RESULT" | awk '{print $1}' | sort -${SORT_ASC}u`)

	# NAME값과 일치하는 행을 PS_RESULT에서 가져옴
	PROCESS_RESULT=`echo "$PS_RESULT" | grep ^${NAME_LIST[$NAME_CURSOR]} | grep -v 'ps aux'`

	# PROCESS_RESULT에서 PID, CPU, MEM, START, CMD 부분에 맞게 배열에 저장(<<<은 문자열을 표준 입력으로 전달하는 리다이렉션)
	PID_LIST=(`awk '{print $2}' <<< "$PROCESS_RESULT"`)
	CPU_LIST=(`awk '{print $3}' <<< "$PROCESS_RESULT"`)
	MEM_LIST=(`awk '{print $4}' <<< "$PROCESS_RESULT"`)
	START_LIST=(`awk '{print $9}' <<< "$PROCESS_RESULT"`)
	CMD_LIST=(`echo "$PROCESS_RESULT"`)

	# CMD_LIST에 있는 값에서 GET_CMD에 저장된 인덱스 이후의 문자열만 남겨서 다시 CMD_LIST에 저장
	for i in $(seq 0 ${#CMD_LIST[@]})
	do
		CMD_LIST[$i]=${CMD_LIST[$i]:$GET_CMD}
	done

	# 작업관리자 프로그램 실행
	Show



	# 엔터키를 입력하면 선택한 프로세스를 비교를 위한 리스트에 저장
	if read -n 3 -t 3 KEY; then
		if [ -z "$KEY" -a $PS_CURSOR -gt -1 ]; then
			PROCESS_COMPARE_PID_LIST+=("${PID_LIST[$START_POINT+$PS_CURSOR]}")
			CheckPID
		fi
	fi
	


	# 일반키 구현1: 프로그램 종료(Quit)
	if [ "$KEY" = 'q' -o "$KEY" = 'Q' ]; then
		exit

	# 일반키 구현2: 프로세스 종료(Kill)
	elif [ "$KEY" = 'k' -o "$KEY" = 'K' ]; then
                if [ "${NAME_LIST[$NAME_CURSOR]}" = `whoami` ]; then
                                kill -9 ${PID_LIST[$START_POINT+$PS_CURSOR]}
                        else
                                NoPermission
        	fi

       	# 조합키 구현: 정렬 방식을 변경
	elif [[ "$KEY" == $'\x0f' ]]; then
		ps_result="ps aux --sort=-%mem"

	elif [[ "$KEY" == $'\x15' ]]; then
		ps_result="ps aux --sort=-%cpu"	

	# 방향키 구현: 상
	elif [[ "$KEY" = $'\e[A' ]]; then
		if [ $PS_CURSOR -eq -1 ]; then
			if [ $NAME_CURSOR -gt 0 ]; then
				NAME_CURSOR=$NAME_CURSOR-1
				START_POINT=0
			fi
		else
			if [ $PS_CURSOR -gt 0 ]; then
				PS_CURSOR=$PS_CURSOR-1
			else
				if [ $START_POINT -gt 0 ]; then
					START_POINT=$START_POINT-1
				fi
			fi
		fi

	# 방향키 구현: 하
	elif [ "$KEY" = $'\e[B' ]; then
		if [ $PS_CURSOR -eq -1 ]; then
			if [ $NAME_CURSOR -lt $((${#NAME_LIST[@]} - 1)) -a $NAME_CURSOR -lt 19 ]; then
				NAME_CURSOR=$NAME_CURSOR+1
				START_POINT=0
			fi
		else
			if [ $PS_CURSOR -lt $((${#PID_LIST[@]} - 1)) -a $PS_CURSOR -lt 19 ]; then
				PS_CURSOR=$PS_CURSOR+1
			else
				if [ $START_POINT -lt $((${#PID_LIST[@]} - 20)) ]; then
					START_POINT=$START_POINT+1
				fi
			fi
		fi

	# 방향키 구현: 좌
	elif [ "$KEY" = $'\e[D' ]; then
		if [ $PS_CURSOR -ge 0 ]; then
			PS_CURSOR=-1
		fi
	
	# 방향키 구현: 우
	elif [ "$KEY" = $'\e[C' ]; then
		if [ $PS_CURSOR -eq -1 ]; then
			PS_CURSOR=0
		fi
	fi
done
