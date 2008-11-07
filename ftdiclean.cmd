@echo off
:: Copyright 2008 Malte S. Stretz <http://msquadrat.de/>
::
:: Remove COM-devices for all known FTDI USB-devices.
::
:: Needs devcon:
::   http://support.microsoft.com/kb/311272/en
:: Should be registered as a shutdown script:
::   http://techsupt.winbatch.com/ts/T000001048F90.html

 :: Enable delayed expansion to use variables in the for loop
 verify other 2>nul
 setlocal enableextensions enabledelayedexpansion
 :: We could check for %ERRORLEVEL% here...
 
 :: Use this temp file
 set tempfile=%TEMP%\ftdiclean.txt
 :: And this log file
 set logfile=%TEMP%\ftdiclean.log
 echo %DATE% %TIME% > %logfile%
 hostname >> %logfile%
 
 :: Find all FTDI devices, including ghost devices; this will return strings 
 :: like FTDIBUS\VID_0403+PID_6001+A4001HLUA\0000
 devcon findall "FTDIBUS\*" | findstr ":" > %tempfile%
 
 :: Determine the USB devices for the FTDI ones: We need to convert the FTDI-
 :: specific paths (plus-delimited) to standard device paths (ampersand-
 :: delimited). Plus we need to strip the leading A for some reason. 
 :: Eg. the string FTDIBUS\VID_0403+PID_6001+A4001HLUA\0000 will
 :: become USB\VID_0403&PID_6001\A4001HLU
 for /f "delims=\&+; tokens=2-4" %%a in (%tempfile%) do (
   set vendor=%%a
   set device=%%b
   set serial=%%c
   :: Remove trailing A
   set serial=!serial:~0,-1!
   :: Append to temp file (yes, this works while we iterate over it)
   devcon findall "@USB\!vendor!&!device!\!serial!" | findstr ":" >> %tempfile%
 )

 :: Now, remove all devices listed in the temp file
 for /f "tokens=1" %%d in (%tempfile%) do (
   devcon remove "@%%d" | findstr ":" >> %logfile%
 )
 
 :: Finally, remove the temp file
 del %tempfile%
 