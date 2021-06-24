@echo off

copy IN\version.txt kb99\

cscript decompile_ert.js --ini-file decompile.ini 


perl correct_dlg.pl -d Src\kb99
perl CompressMetadata.pl -q -d Src\kb99

git status
gitk

rem Пересоберем ert прямо в репозитории
rem cscript decompile_ert.js --ini-file compile-ert.ini
rem compile.bat

rem pause
