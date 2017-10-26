#!/bin/bash

if [ -z $2 ] || [ $3 ]
	then echo -e "\033[33m  $0 <path/to/input/file.sch> <path/to/output/file.kicad_pcb>\033[0m"
	echo -e "\033[33m  Please do not use variables in your Qucs schematic\033[0m"
	exit 1
	fi

exec 1>"$2"

#init file
echo "\
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
  )"

#convert .sch -> .kicad_pcb

#MLIN
cat "$1" | grep -E "MLIN" | sed 's/"//g' | awk '{print "\
  (module MLIN (layer F.Cu) (tedit 0) (tstamp 0)\n\
    (at 0 0)\n\
    (fp_text reference " $2 " (at 0 0.5) (layer F.SilkS)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (fp_text value micostrip_line (at 0 -0.5) (layer F.Fab)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (pad \"\" smd rect (at 0 0 0) (size " $12 " " $15 ") (layers F.Cu))\n\
    (pad \"\" smd rect (at 0 " $15/2 " 0) (size 0.01 0.01) (layers F.Cu))\n\
    (pad \"\" smd rect (at 0 -" $15/2 " 0) (size 0.01 0.01) (layers F.Cu))\n\
  )\n"}'

#MTEE
cat "$1" | grep -E "MTEE" | sed 's/"//g' | awk '{if ($8 == 0) {W1=$12 ; W2=$15 ; P1=1 ; P2=2} if ($8 == 1) {W1=$15 ; W2=$12 ; P1=2 ; P2=1} if ($12 > $15) {Wlong=$12} if ($15 > $12) {Wlong=$15} {Mir=""} print "\
  (module MTEE (layer F.Cu) (tedit 0) (tstamp 0)\n\
    (at 10 10)\n\
    (fp_text reference " $2 " (at 0 0.5) (layer F.SilkS)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
    (fp_text value micostrip_tee (at 0 -0.5) (layer F.Fab)\n\
      (effects (font (size 0.25 0.25) (thickness 0.05)))\n\
    )\n\
	(pad " P1 " smd rect (at -" $18/2 " 0 0) (size 0.01 0.01) (layers F.Cu))\n\
	(pad " P2 " smd rect (at " $18/2 " 0 0) (size 0.01 0.01) (layers F.Cu))\n\
	(pad 3 smd rect (at 0 " Wlong/2 " 0) (size 0.01 0.01) (layers F.Cu))\n\
	(fp_poly\n\
	  (pts\n\
		(xy 0 0) (xy 0 -" W1/2 ") (xy -" $18/2 " -" W1/2 ") (xy -" $18/2 " " Wlong/2 ") (xy " $18/2 " " Wlong/2 ") (xy " $18/2 " -" W2/2 ") (xy 0 -" W2/2 ")\n\
	  )\n\
	  (layer F.Cu)\n\
	  (width 0.00001)\n\
	)\n\
  )\n"}'

#end
echo ')'
exit 0
