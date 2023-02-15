#!/bin/bash

out_file="SQLScripts.inc"

echo 'const' > $out_file
cnt=`ls ./db-updates/ -l | grep '.sql' | wc -l`
echo "  SQLScripts: array [1..${cnt}] of string = (" >> $out_file

i=1
for file in ./db-updates/*.sql; do
	echo "File: $file"
	
	if [[ $i = $cnt ]]
	then
		s=""
	else
		s=","
	fi
	
	if [[ $i = 1 ]]
	then
		n=""
	else
		n="\n"
	fi
	
	sed "s/'/''/g; $ ! s/.*/    '&' + LineEnding +/; $ s/.*/    '&'$s/; 1i\\$n    \/\/ $file;" $file >> $out_file

	((i++))
done

echo '  );' >> $out_file
