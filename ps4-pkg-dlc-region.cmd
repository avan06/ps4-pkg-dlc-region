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
:: Empty value, indicating that the Region is unchanged
:: JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean
set newRegion=
:: Determine the TitleID(length is 9) of the generated pkg
:: Empty value, indicating that the TitleID is unchanged
set newTitleID=
:: Determines the directory name for the generated output
set genDirName=new
:: Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file
set icon0Path=%scriptPath%/icon0.png
:: y: remove all temporary files, n: don't delete anything
set cleanup=n
:: Determine the passcode value for pkg
set passcode=00000000000000000000000000000000
:: Determines whether to still extract when an unpacked PKG archive already exists, y: perform extract and overwrite, n: use existing unpacked file
set overwriteUnpackedArchives=y
:: Determines whether to override gp4 configuration, when gp4 archive already exists, y: generate new gp4 file, n: use existing gp4 file
set overwriteExistGP4=y
:: Determines whether to automatically generate a new PKG after extract, y: generate new PKG, n: extract only
set pkgCreate=y
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

set pkgFullPath=%pkgPath%
pushd %pkgFullPath%
set pkgFullPath=%CD%
popd

:: appVer and version, length of left padding
set numLen=4
set /a count = 0
for %%F in (%pkgFullPath%\*.pkg) do (
  set CATEGORY=
  set CONTENT_ID=
  set FORMAT=
  set PUBTOOLINFO=
  set PUBTOOLVER=
  set TITLE=
  set TITLE_ID=
  set APP_VER=
  set VERSION=
  set fullname=%%F
  set /a count += 1
  echo !count!: !fullname!
  call :GeneratePkg
)

:batchEnd

pause


::
:: Generate DLC Package
::
:GeneratePkg
for /f "tokens=*" %%i in ('!sfoCmd! -q CATEGORY "!fullname!" 2^> nul') do (set CATEGORY=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q CONTENT_ID "!fullname!" 2^> nul') do (set CONTENT_ID=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q FORMAT "!fullname!" 2^> nul') do (set FORMAT=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q PUBTOOLINFO "!fullname!" 2^> nul') do (set PUBTOOLINFO=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q PUBTOOLVER "!fullname!" 2^> nul') do (set PUBTOOLVER=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q TITLE "!fullname!" 2^> nul') do (set TITLE=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q TITLE_ID "!fullname!" 2^> nul') do (set TITLE_ID=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q APP_VER "!fullname!" 2^> nul') do (set APP_VER=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q VERSION "!fullname!" 2^> nul') do (set VERSION=%%i)

if "!CONTENT_ID!"=="" (!sfoCmd! !fullname! & goto :batchNext)

if not "!PUBTOOLINFO:digital50=!"=="!PUBTOOLINFO!" (set storageType=digital50
) else if not "!PUBTOOLINFO:digital25=!"=="!PUBTOOLINFO!" (set storageType=digital25
) else if not "!PUBTOOLINFO:bd50_50=!"=="!PUBTOOLINFO!" (set storageType=bd50_50
) else if not "!PUBTOOLINFO:bd50_25=!"=="!PUBTOOLINFO!" (set storageType=bd50_25
) else if not "!PUBTOOLINFO:bd50=!"=="!PUBTOOLINFO!" (set storageType=bd50
) else if not "!PUBTOOLINFO:bd25=!"=="!PUBTOOLINFO!" (set storageType=bd25
) else set storageType=

if "!APP_VER!"=="" (set appVerStr=0000) else (
  set appVerStr=0000!APP_VER:.=!
  set appVerStr=!appVerStr:~-%numLen%!
)

if "!VERSION!"=="" (set versionStr=0000) else (
  set versionStr=0000!VERSION:.=!
  set versionStr=!versionStr:~-%numLen%!
)

set volumeType=pkg_ps4_ac_data
set contentRegion=!CONTENT_ID:~0,2!
set contentNumber=!CONTENT_ID:~2,5!
set contentTitleID=!CONTENT_ID:~7,9!
set contentName=!CONTENT_ID:~16!
set newRegionTmp=!newRegion!
set newTitleIDTmp=!newTitleID!

if "!newRegionTmp!"=="" set newRegionTmp=!contentRegion!
if "!newTitleIDTmp!"=="" set newTitleIDTmp=!contentTitleID!

set contentNewID=!newRegionTmp!!contentNumber!!newTitleIDTmp!!contentName!
set appVersion=A!appVerStr!-V!versionStr!
set newPkgName=!contentNewID!-!appVersion!

set pathPkgRoot=!pkgFullPath!\!newPkgName!
set pathSc0=!pathPkgRoot!\Sc0
set pathImage0=!pathPkgRoot!\Image0
set pathSceSys=!pathImage0!\sce_sys
set pathGp4=!pathPkgRoot!\!contentNewID!.gp4
set doExtract=y

if not exist !pathPkgRoot! (mkdir !pathPkgRoot!)
if "!overwriteUnpackedArchives!"=="n" if exist "!pathGp4!" (set doExtract=n)
if "!doExtract!"=="y" (
  echo [Info] extract pkg to !newPkgName!
  !orbisPubCmd! img_extract --passcode !passcode! "!fullname!" !pathPkgRoot!
)

if not exist !pathImage0! (set volumeType=pkg_ps4_ac_nodata)
if not exist !pathSceSys! (mkdir !pathSceSys!)

echo [Info] move Sc0 to Image0\sce_sys\ and edit param.sfo
set chunkCount=0
set scenarioCount=0
for /F %%N in ('dir /b /s "!pathSc0!"') do (
  set name=%%~nN
  set ext=%%~xN
  set fullname=%%N
  set attr=%%~aN
  set dirAttr=!attr:~0,1!
  call set subName=%%fullname:!pathSc0!=%%
  if !pathSceSys!==\app\playgo-chunk.dat (
    move /y "!fullname!" "!pathSceSys!"
  ) else if !name!!ext!==playgo-manifest.xml (
    for /f "tokens=*" %%L in (!fullname!) do (
      set line1=%%L
      set line2=!line1:^<chunk_info chunk_count=!
      if not "!line2!"=="!line1!" (
        for /f "tokens=2,3,4,5 delims=^= " %%a in ("!line1!") do (
          set info1=%%a
          set info2=%%b
          set info3=%%c
          set info4=%%d
          if "!info1!"=="chunk_count" set chunkCount=!info2:"=!
          if "!info3!"=="scenario_count" (
            set scenarioCount=!info4:"=!
            set scenarioCount=!scenarioCount:^>=!
          )
        )
        echo [Info] chunkCount:!chunkCount!, scenarioCount:!scenarioCount!
      )
    )
  ) else if not !name!!ext!==license.dat if not !name!!ext!==license.info if not !name!!ext!==psreserved.dat if not !name!!ext!==origin-deltainfo.dat if not !ext!==.dds ( ::if "!name:playgo-=!"=="!name!" 
    if "!dirAttr!"=="d" (
      if not exist !pathSceSys!!subName! mkdir !pathSceSys!!subName!
    ) else (move /y "!fullname!" "!pathSceSys!!subName!")
  )
)
!sfoCmd! -e CONTENT_ID "!contentNewID!" -e TITLE_ID "!newTitleIDTmp!" !pathSceSys!\param.sfo

if exist "!pathGp4!" if "!overwriteExistGP4!"=="y" del /q "!pathGp4!"
if not exist "!pathGp4!" (
  if !CATEGORY!==gp (
    set volumeType=pkg_ps4_patch
    echo:
    echo Handling !newTitleIDTmp!-patch is required the original !newTitleIDTmp!-app...
    echo Preess [Enter] the APP path of !TITLE!:
    set /p appPath=
    echo:
    if not exist !appPath! (echo !newTitleIDTmp!-app path: !appPath! & echo Does not exist... & goto :batchNext)
  
    !orbisPubCmd! gp4_proj_create --volume_type !volumeType! --content_id !contentNewID! --passcode !passcode! --entitlement_key !passcode! --storage_type !storageType! --app_path "!appPath!" "!pathGp4!"
    if !chunkCount! GTR 1 (
      set /a chunkCount=!chunkCount!-1
      for /L %%C in (1,1,!chunkCount!) do (
        !orbisPubCmd! gp4_chunk_add --id %%C --label remaining_data%%C "!pathGp4!"
      )
    )
  ) else if !CATEGORY!==gd (
    set volumeType=pkg_ps4_app
    !orbisPubCmd! gp4_proj_create --volume_type !volumeType! --content_id !contentNewID! --passcode !passcode! --entitlement_key !passcode! --storage_type !storageType! "!pathGp4!"
  ) else (!orbisPubCmd! gp4_proj_create --volume_type !volumeType! --content_id !contentNewID! --passcode !passcode! --entitlement_key !passcode! "!pathGp4!")
  if %ERRORLEVEL% NEQ 0 (echo gp4 proj create failed... & goto :batchNext)
  
  for /F %%N in ('dir /b /s /a:-d "!pathImage0!"') do (
    set name=%%~nN
    set ext=%%~xN
    set fullname=%%N
    call set subName=%%fullname:!pathImage0!\=%%
    if "!subName:sce_sys\about=!"=="!subName!" if "!subName:sce_sys\playgo-=!"=="!subName!" if not "!subName!"=="sce_discmap.plt" if not "!subName!"=="sce_discmap_patch.plt" (
      !orbisPubCmd! gp4_file_add --force --pfs_compression enable !fullname! !subName:\=/! "!pathGp4!")
  )
  
  if not exist !pathSceSys!\icon0.png (
    if exist !icon0Path! (!orbisPubCmd! gp4_file_add --force !icon0Path! sce_sys/icon0.png "!pathGp4!")
  )
)

if "!pkgCreate!"=="y" (
  echo [Info] Creating !newPkgName!.pkg...
  if not exist !pkgFullPath!\!genDirName! (mkdir !pkgFullPath!\!genDirName!)
  !orbisPubCmd! img_create --no_progress_bar "!pathGp4!" !pkgFullPath!\!genDirName!\!newPkgName!.pkg
)

if "!cleanup!"=="y" rmdir /s/q !pathPkgRoot!

:batchNext
echo:
echo:
goto :eof