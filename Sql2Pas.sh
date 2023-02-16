#!/bin/bash

out_file="SQLScripts.inc"

echo "{
    !!! WARNING !!!

    This file generates automatically. Do not edit it.
    All of your changes will be overwritten.
}
" > $out_file;

echo 'const' >> $out_file
max_version=`ls ./db-updates/ -l | grep '.sql' | wc -l`
echo "  SQLScripts: array [1..${max_version}] of string = (" >> $out_file

version=1
for file in ./db-updates/*.sql; do
	echo "File: $file"
	
	if [[ $version != 1 ]]
	then
		echo "" >> $out_file
	fi
	echo "    // $file" >> $out_file
	
	sed "
		s/'/''/g
		$ ! s/.*/    '&' + LineEnding +/
		$ s/.*/    '&'/
	" $file >> $out_file
	
	if [[ $version != $max_version ]]
	then
		echo "    ," >> $out_file
	fi

	((version++))
done

echo '  );' >> $out_file
