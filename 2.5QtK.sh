#!/bin/bash

#var
	#LABEL_TYPE
	#LABEL_LABEL
	#LABEL_NET1
	#LABEL_NET2
	#LABEL_NET3		MTEE
	#LABEL_W		MLIN
	#LABEL_L		MLIN
	#LABEL_W1		MTEE
	#LABEL_W2		MTEE
	#LABEL_W3		MTEE
	#LABEL_M		MTEE
	#LABEL_R
	#LABEL_X
	#LABEL_Y

	#BOM
	#Tlist
	#current
	#past
	#link1
	#link2
	#link3

	#LABEL_past
	#LABEL_pastlink
	#LABEL_linktopast
		#exemple :
		#	|-----------MS1-------------||-----------MS3------------|
		#	|			   MS1_NET2=net8||MS3_NET1=net8				|
		#	|---------------------------||--------------------------|
		#current=MS3
		#MS3_past=MS1
		#MS3_linktopast=MS3_NET1
		#MS3_pastlink=MS1_NET2

	#LABEL_dir 		{+X;-X;+Y;-Y}
		#exemple :
		#	+------>x	|-------------------||------------------|
		#	|			|	current_past	||		current		|
		#	v			|-------------------||------------------|
		#	y					current_dir=+x : ---------> 



net="/tmp/QtK.net"
tmp="/tmp/QtK.tmp"
yell="\\033[33m"
norm="\\033[0m"
scale=5					#decimal calcul precision

#if [ -z $2 ] || [ $3 ]
#	then echo -e "${yell} $0 <path/to/input/file.sch> <path/to/output/file.kicad_pcb>${norm}"
#	echo -e "${yell}  Please do not use variables in your Qucs schematic${norm}"
#	exit 1
#	fi



#####
#create data table
#create netlist
	qucs -n -i "$1" -o "$net"
	dat1=$(cat "$1" "$net" | sed 's/ /:/g' | sed 's/=/:/g' | sed 's/"//g' | sed 's/_//g' )
	exec 1>"$tmp"

#MLIN
	echo -e "#MLIN"
	echo -e "#TYPE\tLABEL\tNET1\tNET2\tW\tL\tR\tX\tY"
	for i in $(echo "${dat1}" | grep '^MLIN' | awk -F: 'OFS=":" {print $2"_TYPE="$1,"'\;'",$2"_LABEL="$2,"'\;'",$2"_NET1="$3,"'\;'",$2"_NET2="$4,"'\;'",$2"_W="$8,"'\;'",$2"_L="$11,"'\;'"}')
		do 
		MS=$(echo "${i}" | awk -F: '{print $3}' | sed -r "s/^(.*)=//g")
		echo "${i}:$(echo "${dat1}" | grep '<MLIN' | grep "${MS}" | awk -F: '{print "'$MS'_R="$11*90,"'\;'"}')" | sed 's/:/\t/g'
		BOM="${BOM}${MS} " 
		done

#MTEE
	echo -e "\n#MTEE"
	echo -e "#TYPE\tLABEL\tNET1\tNET2\tNET3\tW1\tW2\tW3\tM\tR\tX\tY"
	for i in $(echo "${dat1}" | grep '^MTEE' | awk -F: 'OFS=":" {print $2"_TYPE="$1,"'\;'",$2"_LABEL="$2,"'\;'",$2"_NET1="$3,"'\;'",$2"_NET2="$4,"'\;'",$2"_NET3="$5,"'\;'",$2"_W1="$9,"'\;'",$2"_W2="$12,"'\;'",$2"_W3="$15,"'\;'"}')
		do
		MS=$(echo "${i}" | awk -F: '{print $3}' | sed -r "s/^(.*)=//g")
		echo "$i:$(echo "${dat1}" | grep '<MTEE' | grep "${MS}" | awk -F: 'OFS=":" {print "'$MS'_M="$10,"'\;'","'$MS'_R="$11*90,"'\;'"}')" | sed 's/:/\t/g'
		BOM="${BOM}${MS} "
		done
#####



#NET to VAR
	exec 1>$(tty)
#	echo "BOM : ${BOM}"
	eval "$(cat ${tmp})"

#init first
	current="$(echo "${BOM}" | awk '{print $1}')"

	eval ${current}_X=0
	eval ${current}_Y=0
#	echo "current : ${current}"



#loop
while [ "${BOM}" ]

	do BOM="$(echo "${BOM}" | sed "s/${current} //")"
	past="${current}"

#linkx : relative to current
#MS1	:link=	MS2
#↓				↑
#MS1_NETx	→	MS2_NETy
	if [ "$(cat "${tmp}" | grep -v "${past}_" | grep -P "$(eval echo "\$${past}_NET1")\t")" ]
		then link1="$(echo "${BOM}" | grep -so "$(cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo "\$${past}_NET1")\t" | awk '{print $3}' | sed -r "s/^(.*)=//g") ")"
		fi
	if [ "$(cat "${tmp}" | grep -v "${past}_" | grep -P "$(eval echo "\$${past}_NET2")\t")" ]
		then link2="$(echo "${BOM}" | grep -so "$(cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo "\$${past}_NET2")\t" | awk '{print $3}' | sed -r "s/^(.*)=//g") ")"
		fi
	if [ "$(eval echo "\$${past}_NET3")" ]
		then link3="$(echo "${BOM}" | grep -so "$(cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo "\$${past}_NET3")\t" | awk '{print $3}' | sed -r "s/^(.*)=//g") ")"
		fi

			#	eval echo "NET1 : \$${past}_NET1"
			#	echo "link1 : ${link1}"
			#	echo "catl1 : " ; cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo \$${past}_NET1)\t" | awk '{print $3}' | sed -r "s/^(.*)=//g"
			#	eval echo "NET2 : \$${past}_NET2"
			#	echo "link2 : ${link2}"
			#	echo "catl2 : " ; cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo \$${past}_NET2)\t" | awk '{print $3}' | sed -r "s/^(.*)=//g"
			#	eval echo "NET3 : \$${past}_NET3"
			#	echo "link3 : ${link3}"
			#	echo "catl3 : " ; cat "${tmp}" | grep -sv '#' | grep -sv "${past}_" | grep -sP "$(eval echo \$${past}_NET3)\t" | awk '{print $3}' | sed -r "s/^(.*)=//g"
				echo -e "\n"

#path through schematic
#hook variables:
#MS_past
#MS_pastlink
#MS_linktopast
	if [ ${link1} ] && [ ${link2} ]
		then current="$(echo "${link1}" | sed 's/ //g')"
		Tlist="${link2} ${Tlist}"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_pastlink="${past}_NET1"")"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_pastlink="${past}_NET2"")"
	elif [ ${link2} ] && [ ${link3} ]
		then current="$(echo "${link2}" | sed 's/ //g')"
		Tlist="${link3} ${Tlist}"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_pastlink="${past}_NET2"")"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_pastlink="${past}_NET3"")"
	elif [ ${link1} ] && [ ${link3} ]
		then current="$(echo "${link1}" | sed 's/ //g')"
		Tlist="${link3} ${Tlist}"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_pastlink="${past}_NET1"")"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_pastlink="${past}_NET3"")"
	elif [ ${link1} ]
		then current="$(echo "${link1}" | sed 's/ //g')"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link1}" | sed 's/ //g')_pastlink="${past}_NET1"")"
	elif [ ${link2} ]
		then current="$(echo "${link2}" | sed 's/ //g')"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link2}" | sed 's/ //g')_pastlink="${past}_NET2"")"
	elif [ ${link3} ]
		then current="$(echo "${link3}" | sed 's/ //g')"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_past="${past}"")"
		eval "$(eval echo "$(echo "${link3}" | sed 's/ //g')_pastlink="${past}_NET3"")"
	else
		current="$(echo ${Tlist} | awk '{print $1}')"
		Tlist="$(echo "${Tlist}" | sed "s/${current} //")"
		fi

			#	if [ "${link1}" ] ; then eval echo "link1_past : \$$(echo "${link1}" | sed 's/ //g')_past" ; fi
			#	if [ "${link2}" ] ; then eval echo "link2_past : \$$(echo "${link2}" | sed 's/ //g')_past" ; fi
			#	if [ "${link3}" ] ; then eval echo "link3_past : \$$(echo "${link3}" | sed 's/ //g')_past" ; fi
				echo "current if : ${current}"
			#	echo -e "\n"

	unset link1 link2 link3

#current_linktopast
	unset pastlink
	current_pastlink="$(eval echo "\$${current}_pastlink")"
	eval "$(echo "${current}_linktopast")=$(cat "${tmp}" | grep -v "$(eval echo "\$${current}_past")" | grep -oP "$(eval echo "MS\([0-9]*\)_NET\([0-9]*\)=\$${current_pastlink}")" | sed -r "s/=(.*)$//g")"
				eval echo "pastlink : \$${current}_pastlink"
				eval echo "linktopast : \$${current}_linktopast"
				eval echo "past : \$${current}_past"

			#	echo "BOM : ${BOM}"
			#	echo "current : ${current}"
			#	echo "past : ${past}"



#position
	unset current_past
	current_past="$(eval echo "\$${current}_past")"
			#	echo "current_past : ${current_past}"
			#	eval echo "current_past_type : \$${current_past}_TYPE"

#past : MLIN
	if [ "$(eval echo "\$${current_past}_TYPE")" = 'MLIN' ]
		then
		eval "${current}_X=\$${current_past}_X"
		eval "${current}_Y=\$${current_past}_Y"
		if [ "$(eval echo "\$${current_past}_R")" = '0' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+X"
				fi
		elif [ "$(eval echo "\$${current_past}_R")" = '1' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-Y"
				fi
		elif [ "$(eval echo "\$${current_past}_R")" = '2' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-X"
				fi
		elif [ "$(eval echo "\$${current_past}_R")" = '3' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+Y"
				fi
			fi
		fi

#past : MTEE
#	if [ "$(eval echo "\$${current_past}_TYPE")" = 'MTEE' ]

				eval echo "current_past_R : \$${current_past}_R"
				eval echo "current_past_L : \$${current_past}_L"
				eval echo "current_past_X : \$${current_past}_X"
				eval echo "current_past_Y : \$${current_past}_Y"
				eval echo "current_X : \$${current}_X"
				eval echo "current_Y : \$${current}_Y"
				eval echo "current_dir : \$${current}_dir"

	done
