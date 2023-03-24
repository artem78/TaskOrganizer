#!/bin/sh

# Combine program main icon PNGs to ICO file usin IcoFx

mkdir temp -p
"/cygdrive/d/Программы/IcoFX3/icofx3.exe" MakeProgramIco.fxs
mv -f temp/iconprogrampx.ico ../TaskOrganizer.ico
rm -rf temp/
