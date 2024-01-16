:: --------------------------------------
:: Batch to create/deploy the TAPP file
::
:: powershell :  cmd.exe /c build.bat -u -r
::      -u : upload files to host
::      -r : restart host
::      -a : copy TAAP file to artifact folder

@echo off
set curdir=%cd%

:: 7zip parameters
:: u update files to archive
:: -m0=Copy   set compression method
:: -w working directory
:: -tzip create a zip file

:: basic settings
set copyRoot=..\..\Coding
set root=.
set appName=DallasTemp
set host=192.168.178.126

:: copy from master repo
if exist "%copyRoot%" (
copy /y %copyRoot%\Common\Libs.be .
copy /y %copyRoot%\Common\tool.be .
copy /y %copyRoot%\AppDallasTemp\DallasTemp.be .
copy /y %copyRoot%\AppDallasTemp\DallasTempBase.be .
copy /y %copyRoot%\AppDallasTemp\README.md .
copy /y %copyRoot%\AppDallasTemp\images\* .\images
)

:: create git hash
git rev-parse --short HEAD>tmp.txt
set /p gitHash=<tmp.txt

:: create git state
echo OK>tmp.txt
git diff --quiet || echo dirty>tmp.txt
set /p gitState=<tmp.txt

:: create git date
date /t >tmp.txt
set /p gitDate=<tmp.txt
del tmp.txt

: 04.01.2024
set gitDate=%date:~6,4%-%date:~3,2%-%date:~0,2%

:: create git.be
echo var gitInfo='%gitDate% - %gitHash% - %gitState%'>git.be

:: create uncompressed zip file
set tool="C:\Program Files\7-Zip\7z.exe"
set target=%curdir%\%appName%.tapp

set commonFiles=Libs.be tool.be git.be  DallasTempBase.be DallasTemp.be 
set appFiles=autoexec.be configure01.be configure02.beDallasTemp01.be DallasTemp02.be

IF EXIST %target%  del %target%

::  create TAPP file
%tool% a %target% -m0=Copy -tzip %commonFiles% %appFiles%


:: parse the parameters -u, -r and  -a
set doUpload=0
set doRestart=0
set doArtifact=0

echo para1:%1

:loop 
  if "%1"=="" goto :done
  if "%1"=="-u" (
    set doUpload=1
  )
  if "%1"=="-r" (
    set doRestart=1
  )  
  if "%1"=="-a" (
    set doArtifact=1
  ) 
  shift
goto :loop

:done

echo doUpload : %doUpload%   doRestart : %doRestart%  doArtifact : %doArtifact% 
::goto :eof

:: create artifact
if %doArtifact%==1 (
  copy /y %appName%.tapp .\artifact\%appName%_%gitDate%_%gitHash%.tapp
)

:: upload files to host
if %doUpload%==1 (
    call :upload %appName%.tapp
    call :upload %appName%01.be
    call :upload %appName%02.be
) 

:: restart host
if %doRestart%==1 (
    curl "http://%host%/cm?cmnd=restart%%201"
) 

goto :eof

:: ------------- Sub-routines

:upload
 ::echo upload: got %1
 curl -v "http://%host%/ufsd?delete=/%1"  > NUL
 curl -v --form "ufsu=@%1" "http://%host%/ufsu" > NUL
 goto :eof




