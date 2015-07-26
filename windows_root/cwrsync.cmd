REM @ECHO OFF
REM *****************************************************************
REM
REM CWRSYNC.CMD - Batch file template to start your rsync command (s).
REM
REM By Tevfik K. (http://itefix.no)
REM *****************************************************************

REM Make environment variable changes local to this batch file
SETLOCAL

REM ** CUSTOMIZE ** Specify where to find rsync and related files (C:\CWRSYNC)
SET CWRSYNCHOME=C:\CWRSYNC
ECHO %CWRSYNCHOME%

REM Set HOME variable to your windows home directory. That makes sure 
REM that ssh command creates known_hosts in a directory you have access.
SET HOME=%HOMEDRIVE%%HOMEPATH%

REM Make cwRsync home as a part of system PATH to find required DLLs
SET CWOLDPATH=%PATH%
SET PATH=%CWRSYNCHOME%\BIN;%PATH%

REM Windows paths may contain a colon (:) as a part of drive designation and 
REM backslashes (example c:\, g:\). However, in rsync syntax, a colon in a 
REM path means searching for a remote host. Solution: use absolute path 'a la unix', 
REM replace backslashes (\) with slashes (/) and put -/cygdrive/- in front of the 
REM drive letter:
REM 
REM Example : C:\WORK\* --> /cygdrive/c/work/*
REM 
REM Example 1 - rsync recursively to a unix server with an openssh server :
REM
REM       rsync -r /cygdrive/c/work/ remotehost:/home/user/work/
REM
REM Example 2 - Local rsync recursively 
REM
REM       rsync -r /cygdrive/c/work/ /cygdrive/d/work/doc/
REM
REM Example 3 - rsync to an rsync server recursively :
REM    (Double colons?? YES!!)
REM
REM       rsync -r /cygdrive/c/doc/ remotehost::module/doc
REM
REM Rsync is a very powerful tool. Please look at documentation for other options. 
REM
REM SETLOCAL EnableDelayedExpansion
REM SET MACADDR=""
REM ** CUSTOMIZE ** Enter your rsync command(s) here

REM ##########################################
REM ## BE SURE TO MAKE SYMLINK TO DEMOS DIR ##
REM ##########################################
REM mklink c:\demos "c:\Users\qwijib0\AppData\LocalLow\id Software\lan\home\baseq3\demos"

SET DEMOS_USER="demos"
SET DEMOS_KEY="demos_rsa"
SET DEMOS_ROOT=""
SET DEMOS_SERVER="demos"

REM Get the MAC address of the machine by looping through IPCONFIG
for /f "tokens=1-2,12" %%i in ('ipconfig /all') do (
 if "%%i %%j"=="Physical Address." ( 
  set MACADDR=%%k
  goto :lol
 )
)
:lol

REM Remove Dashes from address, and convert to lowercase
SET MACADDR=%MACADDR:-=%
CALL :LoCase MACADDR

REM RSYNC the demos to the server using the mac address as a directory

ssh -i %DEMOS_KEY% -o StrictHostKeyChecking=no %DEMOS_USER%@%DEMOS_SERVER% mkdir -p %DEMOS_ROOT%%MACADDR%/
dir
REM rsync -e  "\"/cygdrive/c/cwrsync/ssh.exe\" -i demos_rsa -o StrictHostKeyChecking=no"  /cygdrive/c/demos/* --exclude /cygdrive/c/demos/web.pak --exclude /cygdrive/c/demos/baseq3/* --exclude /cygdrive/c/demos/*.dll --exclude /cygdrive/c/demos/quakelive_stream --exclude /cygdrive/c/demos/awesomium_process --exclude /cygdrive/c/demos/splash.bmp %DEMOS_USER%@%DEMOS_SERVER%:%DEMOS_ROOT%%MACADDR%/
rsync -rve  "\"/cygdrive/c/cwrsync/ssh.exe\" -i demos_rsa -o StrictHostKeyChecking=no" --exclude=web.pak --exclude=*.dll --exclude=*.pk3 --exclude=quakelive_steam.exe --exclude=awesomium_process.exe --exclude=splash.bmp /cygdrive/c/demos/* %DEMOS_USER%@%DEMOS_SERVER%:%DEMOS_ROOT%%MACADDR%/
REM exit

REM This is the bit that makes things lowercase
:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF