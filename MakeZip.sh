#!/bin/bash

# ***  Functions  ***

function StopBuild(){
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!                Fatal error!                !!!"
	echo ""
	echo $1
	echo ""
	echo "!!!          Build failed. Sorry :(            !!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	Pause
	exit 1
}

function Pause(){
	read -n 1 -s -r -p "Press any key to continue..."
}

function Compile(){
	# Run compile project
	echo "Starting compile project..."
	"$LazarusDir/lazbuild.exe" --build-mode="Release" --verbose TasksOrganizer.lpi
	echo "Compiling finished!"
	echo ""
}

function MakeZip(){
	Compile
	
	# Create and clear build directory
	echo "Clear build directory..."
	rm -f -r $BuildDir
	mkdir -p $BuildDir
	mkdir -p $TargetZipDir
	echo "Done!"
	echo ""

	# Executable
	echo "Copy EXE..."
	cp -v --preserve TasksOrganizer.exe $BuildDir
	echo "Done!"
	echo ""

	# DLLs
	echo "Copy DLLs..."
	cp -v --preserve $LazarusDir/sqlite3.dll $BuildDir
	echo "Done!"
	echo ""
	
	# DB updates
	echo "Copy db-updates dir..."
	mkdir -p $BuildDir/db-updates
	cp -v --preserve db-updates/*.sql $BuildDir/db-updates/
	echo "Done!"
	echo ""

	# Pack to ZIP archive
	echo "Pack all files to ZIP archive..."
	ZipPath=$TargetZipDir/Task_Organizer_${ProgramVersion}.zip
	rm -f $ZipPath
	cd $BuildDir
	zip -r $ZipPath *
	#tar -C $BuildDir -cvf $ZipPath $BuildDir/*
	echo "Done!"
	echo ""
}

# ***********************

# ***  Set variables ***
LazarusDir="/cygdrive/f/Programms/lazarus_2.0.12_32bit"

# Output dirs
BuildDir=$(realpath -m "build")
TargetZipDir=$(realpath -m "releases")

# Program version
#ProgramVersion=$(grep -Po '\<StringTable.+ ProductVersion="\K[0-9\.]+' TasksOrganizer.lpi)
ProgramVersion=$(git describe --dirty --long)
#echo "Current program version: $ProgramVersion"
#echo ""

# ***********************


MakeZip

Pause
exit 0
