#!/bin/bash

container_cmd="docker run -v=$(pwd):/kikit -w=/kikit --rm yaqwsx/kikit:v1.3.0-v7"
container_cmd_draw="docker run -v=$(pwd):/kikit -w=/kikit --rm --entrypoint pcbdraw yaqwsx/kikit:v1.3.0-v7"

# Images
echo "Drawing image files"
mkdir -p images
for option in "pcb" "cases/fr4/bottom" "cases/fr4/plate" "cases/fr4/shield"
do
	short_option="$(basename "$option")"
	file="$(find $option -type f -name '*.kicad_pcb')"
	${container_cmd_draw} plot --style oshpark-purple "$file" images/"$short_option".png >> /dev/null
	${container_cmd_draw} plot --style oshpark-purple --side back "$file" images/"$short_option"_back.png >> /dev/null
done

# Gerbers
echo "Generating gerbers"
mkdir -p gerbers
for option in "pcb" "cases/fr4/bottom" "cases/fr4/plate" "cases/fr4/shield"
do
	prefix="case"
	if [[ "$option" == "pcb" ]]; then
		prefix="pcb"
	fi
	mkdir -p gerbers/"$prefix"
	short_option="$(basename "$option")"
	file="$(find $option -type f -name '*.kicad_pcb')"
	${container_cmd} fab jlcpcb --no-assembly "$file" gerbers/"$short_option-JLCPCB" --no-drc
	mv gerbers/"$short_option-JLCPCB"/gerbers.zip gerbers/"$prefix"/"$short_option-JLCPCB"_gerbers.zip
	rm -r gerbers/"$short_option-JLCPCB"
	${container_cmd} fab pcbway --no-assembly "$file" gerbers/"$short_option-PCBWay" --no-drc
	mv gerbers/"$short_option-PCBWay"/gerbers.zip gerbers/"$prefix"/"$short_option-PCBWay"_gerbers.zip
	rm -r gerbers/"$short_option-PCBWay"
done

zip -jr gerbers/case/gerber_case_files gerbers/case/
