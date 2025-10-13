@ECHO OFF
SET Target_File=Compare.txt
SET First_File=NUL
SET Second_File=NUL
SET Timeout_Time=10
IF %Target_File% == NUL SET /P Target_File=Choose Target file: 
IF %First_File% == NUL SET /P First_File=Choose first file: 
IF %Second_File% == NUL SET /P Second_File=Choose second file: 
IF %Timeout_Time% == NUL SET /P Timeout_Time=Choose timeout time in seconds: 
IF NOT EXIST %Target_File% BREAK > %Target_File% 
ECHO Include: %Target_File% to Equalizer APO
Pause
:Repeat
COPY /Y %First_File% %Target_File% > NUL
CLS && ECHO %First_File% 
TIMEOUT %Timeout_Time% > NUL
COPY /Y %Second_File% %Target_File% > NUL
CLS && ECHO %Second_File%
TIMEOUT %Timeout_Time% > NUL
GOTO Repeat
