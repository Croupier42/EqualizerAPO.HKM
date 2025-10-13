@echo off
SET Compare=Compare.txt
SET /P Time=Choose timeout in seconds: 
SET /P Compare_A=Choose first file: 
SET /P Compare_B=Choose second file: 
IF NOT EXIST %Compare% echo: 2>%Compare% && echo Include %Compare% to Equalizer APO && pause
:repeat
COPY /Y %Compare_A% %Compare%
echo Playing: %Compare_A%
timeout %Time%
COPY /Y %Compare_B% %Compare%
echo Playing: %Compare_B%
timeout %Time%
goto repeat
