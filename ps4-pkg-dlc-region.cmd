@echo off
chcp 65001

setlocal enableDelayedExpansion

:: Read batch script path
set scriptPath=%~dp0%

:: =========== User Defined Block Start ===========
:: Determines the path of orbis-pub, nullable if it has been set in the path of windows
set orbisPubPath=
:: Determines the path of sfo(hippie68), nullable if it has been set in the path of windows
set sfoPath=
:: Determine the path to the original pkg
set pkgPath=.\dlc
:: Determine the Region(length is 2) of the generated pkg
:: JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean
set newRegion=JP
:: Determine the TitleID(length is 9) of the generated pkg
set newTitleID=CUSA12345
:: Determines the directory name for the generated output
set genDirName=new
:: Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file
set icon0Path=%scriptPath%/icon0.png
:: y: remove all temporary files, n: don't delete anything
set cleanup=y
:: Determine the passcode value for pkg
set passcode=00000000000000000000000000000000
:: =========== User Defined Block End ===========

echo:
echo   ps4 pkg dlc region changes batch script
echo   based on orbis-pub-gen and sfo
echo:
echo    The PKG path    is %pkgPath%
echo    The new Region  is %newRegion%
echo    The new TitleID is %newTitleID%
echo:
echo:

set orbisPubCmd=orbis-pub-cmd
if exist %orbisPubPath% orbisPubCmd=%orbisPubPath%/%orbisPubCmd%
set sfoCmd=sfo
if exist %sfoPath% orbisPubCmd=%sfoPath%/%sfoCmd%

where %orbisPubCmd% >nul
if %ERRORLEVEL% NEQ 0 (echo orbis-pub-cmd not found & goto :batchEnd)
where %sfoCmd% >nul
if %ERRORLEVEL% NEQ 0 (echo sfo not found & goto :batchEnd)

:: attribute and version, length of left padding
set numLen=4
set /a count = 0
for %%F in (%pkgPath%\*.pkg) do (
  set fullname=%%F
  set /a count += 1
  echo !count!: !fullname!

  for /f %%i in ('!sfoCmd! -q ATTRIBUTE !fullname! 2^> nul') do (set ATTRIBUTE=%%i)
  for /f %%i in ('!sfoCmd! -q CATEGORY !fullname! 2^> nul') do (set CATEGORY=%%i)
  for /f %%i in ('!sfoCmd! -q CONTENT_ID !fullname! 2^> nul') do (set CONTENT_ID=%%i)
  for /f %%i in ('!sfoCmd! -q FORMAT !fullname! 2^> nul') do (set FORMAT=%%i)
  for /f %%i in ('!sfoCmd! -q PUBTOOLINFO !fullname! 2^> nul') do (set PUBTOOLINFO=%%i)
  for /f %%i in ('!sfoCmd! -q PUBTOOLVER !fullname! 2^> nul') do (set PUBTOOLVER=%%i)
  for /f %%i in ('!sfoCmd! -q TITLE !fullname! 2^> nul') do (set TITLE=%%i)
  for /f %%i in ('!sfoCmd! -q TITLE_ID !fullname! 2^> nul') do (set TITLE_ID=%%i)
  for /f %%i in ('!sfoCmd! -q VERSION !fullname! 2^> nul') do (set VERSION=%%i)

  set /A attributeDec=!ATTRIBUTE!
  set attributeDec=0000!attributeDec!
  set attributeDec=!attributeDec:~-%numLen%!
  set versionStr=0000!VERSION:.=!
  set versionStr=!versionStr:~-%numLen%!

  set contentRegion=!CONTENT_ID:~0,2!
  set contentNumber=!CONTENT_ID:~2,5!
  set contentTitleID=!CONTENT_ID:~7,9!
  set contentName=!CONTENT_ID:~16!
  set contentNewID=!newRegion!!contentNumber!!newTitleID!!contentName!
  set attrVersion=A!attributeDec!-V!versionStr!
  set newPkgName=!contentNewID!-!attrVersion!
  set gp4Path=!pkgPath!\!newPkgName!\!contentNewID!.gp4

  echo [Info] extract pkg to !newPkgName!
  if not exist !pkgPath!\!newPkgName! (mkdir !pkgPath!\!newPkgName!)
  !orbisPubCmd! img_extract --passcode !passcode! !fullname! !pkgPath!\!newPkgName!
  
  echo [Info] move sfo ^& *.png to Image0\sce_sys\ and edit param.sfo
  move /y "!pkgPath!\!newPkgName!\Sc0\param.sfo" "!pkgPath!\!newPkgName!\Image0\sce_sys"
  !sfoCmd! -e CONTENT_ID "!contentNewID!" -e TITLE_ID "!newTitleID!" !pkgPath!\!newPkgName!\Image0\sce_sys\param.sfo

  for %%N in (!pkgPath!\!newPkgName!\Sc0\*.png) do (
    set fullname=%%N
    move /y "!fullname!" "!pkgPath!\!newPkgName!\Image0\sce_sys"
  )

  if exist "!gp4Path!" del /q "!gp4Path!"
  !orbisPubCmd! gp4_proj_create --volume_type pkg_ps4_ac_data --content_id !contentNewID!  --passcode !passcode! --entitlement_key !passcode! !gp4Path!

  if exist !pkgPath!\!newPkgName!\Image0\sce_sys\ (
    for %%N in (!pkgPath!\!newPkgName!\Image0\sce_sys\*) do (
      set name=%%~nN
      set ext=%%~xN
      set fullname=%%N
      !orbisPubCmd! gp4_file_add --force !fullname! sce_sys/!name!!ext! !gp4Path!
    )
  )

  if exist !pkgPath!\!newPkgName!\Image0\ (
    for %%N in (!pkgPath!\!newPkgName!\Image0\*) do (
      set name=%%~nN
      set ext=%%~xN
      set fullname=%%N
      !orbisPubCmd! gp4_file_add --force !fullname! !name!!ext! !gp4Path!
    )
  )

  if not exist !pkgPath!\!newPkgName!\Image0\sce_sys\icon0.png (
    if exist !icon0Path! (!orbisPubCmd! gp4_file_add --force !icon0Path! sce_sys/icon0.png !gp4Path!)
  )

  echo [info] Creating !newPkgName!.pkg...
  if not exist !pkgPath!\!genDirName! (mkdir !pkgPath!\!genDirName!)
  !orbisPubCmd! img_create --no_progress_bar !gp4Path! !pkgPath!\!genDirName!\!newPkgName!.pkg

  if "!cleanup!"=="y" rmdir /s/q !pkgPath!\!newPkgName!
  echo:
  echo:
)


:batchEnd

pause