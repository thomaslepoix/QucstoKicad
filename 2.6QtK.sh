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
	#LABEL_WLONG	MTEE
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
pcb="/tmp/QtK.kicad_pcb"
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
	qucs -n -i "$1" -o "${net}"
	dat1=$(cat "$1" "${net}" | sed 's/ /:/g' | sed 's/=/:/g' | sed 's/"//g' | sed 's/_//g' )
	exec 1>"${tmp}"

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
	echo -e "#TYPE\tLABEL\tNET1\tNET2\tNET3\tW1\tW2\tW3\tWlong\tM\tR\tX\tY"
	for i in $(echo "${dat1}" | grep '^MTEE' | awk -F: 'OFS=":" {if ($9 > $12) {Wlong=$9} if ($9 == $12) {Wlong=$9} if ($9 < $12) {Wlong=$12} print $2"_TYPE="$1,"'\;'",$2"_LABEL="$2,"'\;'",$2"_NET1="$3,"'\;'",$2"_NET2="$4,"'\;'",$2"_NET3="$5,"'\;'",$2"_W1="$9,"'\;'",$2"_W2="$12,"'\;'",$2"_W3="$15,"'\;'",$2"_WLONG="Wlong,"'\;'"}')
		do
		MS=$(echo "${i}" | awk -F: '{print $3}' | sed -r "s/^(.*)=//g")
		echo "$i:$(echo "${dat1}" | grep '<MTEE' | grep "${MS}" | awk -F: 'OFS=":" {print "'$MS'_M="$10,"'\;'","'$MS'_R="$11*90,"'\;'"}')" | sed 's/:/\t/g'
		BOM="${BOM}${MS} "
		done
#####

#draw shape
function draw {
#MLIN
[ "$(eval echo "\$${current}_TYPE")" = 'MLIN' ] && echo -e "\
  (module MLIN (layer F.Cu) (tedit 0) (tstamp 0)\n\
    (at $(eval echo "\$${current}_X") $(eval echo "\$${current}_Y") $(eval echo "\$${current}_R"))\n\
    (fp_text reference $(eval echo "\$${current}_LABEL") (at 0 0.5) (layer F.SilkS)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (fp_text value micostrip_line (at 0 -0.5) (layer F.Fab)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (pad \"\" smd rect (at 0 0 $(eval echo "\$${current}_R")) (size $(eval echo "\$${current}_L") $(eval echo "\$${current}_W")) (layers F.Cu))\n\
  )\n" >>"${pcb}" 

#MTEE
if [ "$(eval echo "\$${current}_TYPE")" = 'MTEE' ]
then #unset S1 S2
[ "$(eval echo "\$${current}_M")" = '0' ] && S1="" && S2="-"
[ "$(eval echo "\$${current}_M")" = '1' ] && S1="-" && S2=""
eval "${current}_W1_2=$(eval echo "scale=${scale}\; \$${current}_W1 /2" | bc)"
eval "${current}_W2_2=$(eval echo "scale=${scale}\; \$${current}_W2 /2" | bc)"
eval "${current}_W3_2=$(eval echo "scale=${scale}\; \$${current}_W3 /2" | bc)"
eval "${current}_WLONG_2=$(eval echo "scale=${scale}\; \$${current}_WLONG /2" | bc)"
echo -e "\
  (module MTEE (layer F.Cu) (tedit 0) (tstamp 0)\n\
    (at $(eval echo "\$${current}_X") $(eval echo "\$${current}_Y") $(eval echo "\$${current}_R"))\n\
    (fp_text reference $(eval echo "\$${current}_LABEL") (at 0 0.5) (layer F.SilkS)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (fp_text value micostrip_tee (at 0 -0.5) (layer F.Fab)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
	(fp_poly\n\
	  (pts\n\
		(xy 0 0) (xy 0 ${S2}$(eval echo "\$${current}_W1_2")) (xy -$(eval echo "\$${current}_W3_2") ${S2}$(eval echo "\$${current}_W1_2")) (xy -$(eval echo "\$${current}_W3_2") ${S1}$(eval echo "\$${current}_WLONG_2")) (xy $(eval echo "\$${current}_W3_2") ${S1}$(eval echo "\$${current}_WLONG_2")) (xy $(eval echo "\$${current}_W3_2") ${S2}$(eval echo "\$${current}_W2_2")) (xy 0 ${S2}$(eval echo "\$${current}_W2_2"))\n\
	  )\n\
	  (layer F.Cu)\n\
	  (width 0.00001)\n\
	)\n\
  )\n" >>"${pcb}"
fi ; }

#init output file
echo -e "\
(kicad_pcb (version 4) (host pcbnew 4.0.4+dfsg1-stable)

  (general
    (links 0)
    (no_connects 0)
    (area 0 0 0 0)
    (thickness 1.6)
    (drawings 0)
    (tracks 0)
    (zones 0)
    (modules 1)
    (nets 1)
  )

  (page A4)
  (layers
    (0 F.Cu signal)
    (31 B.Cu signal)
    (32 B.Adhes user)
    (33 F.Adhes user)
    (34 B.Paste user)
    (35 F.Paste user)
    (36 B.SilkS user)
    (37 F.SilkS user)
    (38 B.Mask user)
    (39 F.Mask user)
    (40 Dwgs.User user)
    (41 Cmts.User user)
    (42 Eco1.User user)
    (43 Eco2.User user)
    (44 Edge.Cuts user)
    (45 Margin user)
    (46 B.CrtYd user)
    (47 F.CrtYd user)
    (48 B.Fab user)
    (49 F.Fab user)
  )

  (setup
    (last_trace_width 0.25)
    (trace_clearance 0.2)
    (zone_clearance 0.508)
    (zone_45_only no)
    (trace_min 0.2)
    (segment_width 0.2)
    (edge_width 0.15)
    (via_size 0.6)
    (via_drill 0.4)
    (via_min_size 0.4)
    (via_min_drill 0.3)
    (uvia_size 0.3)
    (uvia_drill 0.1)
    (uvias_allowed no)
    (uvia_min_size 0.2)
    (uvia_min_drill 0.1)
    (pcb_text_width 0.3)
    (pcb_text_size 1.5 1.5)
    (mod_edge_width 0.15)
    (mod_text_size 1 1)
    (mod_text_width 0.15)
    (pad_size 1 3)
    (pad_drill 0)
    (pad_to_mask_clearance 0.2)
    (aux_axis_origin 0 0)
    (visible_elements FFFFFF7F)
    (pcbplotparams
      (layerselection 0x00030_80000001)
      (usegerberextensions false)
      (excludeedgelayer true)
      (linewidth 0.150000)
      (plotframeref false)
      (viasonmask false)
      (mode 1)
      (useauxorigin false)
      (hpglpennumber 1)
      (hpglpenspeed 20)
      (hpglpendiameter 15)
      (hpglpenoverlay 2)
      (psnegative false)
      (psa4output false)
      (plotreference true)
      (plotvalue true)
      (plotinvisibletext false)
      (padsonsilk false)
      (subtractmaskfromsilk false)
      (outputformat 1)
      (mirror false)
      (drillshape 1)
      (scaleselection 1)
      (outputdirectory \"\"))
  )

  (net 0 \"\")

  (net_class Default \"This is the default net class.\"
    (clearance 0.2)
    (trace_width 0.25)
    (via_dia 0.6)
    (via_drill 0.4)
    (uvia_dia 0.3)
    (uvia_drill 0.1)
  )\n" >"${pcb}"


#NET to VAR
	exec 1>$(tty)
			#	echo "BOM : ${BOM}"
	eval "$(cat ${tmp})"

#init first
	current="$(echo "${BOM}" | awk '{print $1}')"

	eval ${current}_X=0
	eval ${current}_Y=0
			#	echo "current : ${current}"
	draw


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
		elif [ "$(eval echo "\$${current_past}_R")" = '90' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-Y"
				fi
		elif [ "$(eval echo "\$${current_past}_R")" = '180' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_L /2\)" | bc)"
				eval "${current}_dir=-X"
				fi
		elif [ "$(eval echo "\$${current_past}_R")" = '270' ]
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
	if [ "$(eval echo "\$${current_past}_TYPE")" = 'MTEE' ]
		then
		eval "${current}_X=\$${current_past}_X"
		eval "${current}_Y=\$${current_past}_Y"
		if [ "$(eval echo "\$${current_past}_M")" = '0' ] && [ "$(eval echo "\$${current_past}_R")" = '0' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=+Y"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '0' ] && [ "$(eval echo "\$${current_past}_R")" = '90' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=+X"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '0' ] && [ "$(eval echo "\$${current_past}_R")" = '180' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=-Y"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '0' ] && [ "$(eval echo "\$${current_past}_R")" = '270' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=-X"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '1' ] && [ "$(eval echo "\$${current_past}_R")" = '0' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=-Y"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '1' ] && [ "$(eval echo "\$${current_past}_R")" = '90' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=-X"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '1' ] && [ "$(eval echo "\$${current_past}_R")" = '180' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-X"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=+Y"
				fi
		elif [ "$(eval echo "\$${current_past}_M")" = '1' ] && [ "$(eval echo "\$${current_past}_R")" = '270' ]
			then if [ "$(echo ${current_pastlink} | grep -o 'NET1')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=-Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET2')" ]
				then eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current_past}_W3 /2\)" | bc)"
				eval "${current}_dir=+Y"
			elif [ "$(echo ${current_pastlink} | grep -o 'NET3')" ]
				then eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current_past}_WLONG /2\)" | bc)"
				eval "${current}_dir=+X"
				fi
			fi
		fi

#current : MLIN
	if [ "$(eval echo "\$${current}_TYPE")" = 'MLIN' ]
		then
		[ "$(eval echo "\$${current}_dir")" = '+X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current}_L /2\)" | bc)"
		[ "$(eval echo "\$${current}_dir")" = '-X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current}_L /2\)" | bc)"
		[ "$(eval echo "\$${current}_dir")" = '+Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current}_L /2\)" | bc)"
		[ "$(eval echo "\$${current}_dir")" = '-Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current}_L /2\)" | bc)"
		fi

#current : MTEE
	if [ "$(eval echo "\$${current}_TYPE")" = 'MTEE' ]
		then if [ "$(eval echo "\$${current}_linktopast" | grep -o "NET1\|NET2")" ]
			then
			[ "$(eval echo "\$${current}_dir")" = '+X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current}_W3 /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '-X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current}_W3 /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '+Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current}_W3 /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '-Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current}_W3 /2\)" | bc)"
		elif [ "$(eval echo "\$${current}_linktopast" | grep -o 'NET3')" ]
			then
			[ "$(eval echo "\$${current}_dir")" = '+X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X + \(\$${current}_WLONG /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '-X' ] && eval "${current}_X=$(eval echo "scale=${scale}\; \$${current}_X - \(\$${current}_WLONG /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '+Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y + \(\$${current}_WLONG /2\)" | bc)"
			[ "$(eval echo "\$${current}_dir")" = '-Y' ] && eval "${current}_Y=$(eval echo "scale=${scale}\; \$${current}_Y - \(\$${current}_WLONG /2\)" | bc)"
			fi
		fi
	draw
				eval echo "current_past_R : \$${current_past}_R"
				eval echo "current_past_L : \$${current_past}_L"
				eval echo "current_past_X : \$${current_past}_X"
				eval echo "current_past_Y : \$${current_past}_Y"
				eval echo "current_X : \$${current}_X"
				eval echo "current_Y : \$${current}_Y"
				eval echo "current_dir : \$${current}_dir"

#end
	done
	echo ')' >>"${pcb}"
	echo "*** try to write layout   : \"${pcb}\""
	exit 0
