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

:: =========== Misc options ===========
:: Determines the directory name for the generated output
set genDirName=new
:: Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file
set icon0Path=%scriptPath%/icon0.png
:: y: remove all temporary files, n: don't delete anything
set cleanup=n
:: Determine the passcode value for pkg (extract and generate)
set passcode=00000000000000000000000000000000

:: =========== Extract options ===========
:: Determines whether to show the extract status, show extract status will be slower if the pkg file size is very large, y: show, n: not show
set pkgExtractShowStatus=y

:: =========== Overwrite options ===========
:: Determines whether to still extract when an unpacked PKG archive already exists, y: perform extract and overwrite, n: use existing unpacked file
set overwriteUnpackedArchives=y
:: Determines whether to override gp4 configuration, when gp4 archive already exists, y: generate new gp4 file, n: use existing gp4 file
set overwriteExistGP4=y

:: =========== Generate options ===========
:: Determines whether to automatically generate a new PKG after extract, y: generate new PKG, n: extract only
set pkgCreate=y
:: Determines whether to enable compression for package files, y: compressed, n: not compressed
set pfsCompression=y
:: Determines whether to calculate digest after pkg create, y: digest calculation, n: faster creation
set pkgDigest=y
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

call :CreateBinEditVBS
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

goto :batchEnd

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

if "!overwriteUnpackedArchives!"=="n" if exist "!pathPkgRoot!" (set doExtract=n)
if not exist !pathPkgRoot! (mkdir !pathPkgRoot!)
if "!doExtract!"=="y" (
  set fileCount=0
  echo [Info] extract pkg to !newPkgName!
  if "!pkgExtractShowStatus!"=="y" (
    for /f "tokens=3,5" %%a in ('!orbisPubCmd! img_file_list --passcode !passcode! --oformat long "!fullname!" 2^> nul') do (
      set dirName=%%a
      set dirName=!dirName:/=\!
      set file=%%b
      if not "!file!"=="" (
        set /a fileCount=!fileCount!+1
        rem set files[!fileCount!]=!file!
        set winFile=!file:/=\!
        echo extract!fileCount!: !file!
        !orbisPubCmd! img_extract --passcode !passcode! "!fullname!:!file!" !pathPkgRoot!\!winFile! 1> nul
      ) else if not exist !pathPkgRoot!\!dirName! mkdir !pathPkgRoot!\!dirName!
    )
  rem for /L %%i in (1,1,!fileCount!) do (
  rem   set file=!files[%%i]!
  rem   set winFile=!file:/=\!
  rem   echo extract!fileCount!: !file!
  rem   !orbisPubCmd! img_extract --passcode !passcode! "!fullname!:!file!" !pathPkgRoot!\!winFile! 1> nul
  rem )
  ) else !orbisPubCmd! img_extract --passcode !passcode! "!fullname!" !pathPkgRoot!
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
  ) else if not !name!!ext!==license.dat if not !name!!ext!==license.info if not !name!!ext!==psreserved.dat if not !name!!ext!==origin-deltainfo.dat if not !ext!==.dds if not !name!!ext!==pubtoolinfo.dat ( ::if "!name:playgo-=!"=="!name!" 
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
    echo Handling !newTitleIDTmp!-patch is required the original !newTitleIDTmp!-app pkg...
    echo Preess [Enter] the pkg path of !TITLE!:
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
    if !chunkCount! GTR 1 (
      set /a chunkCount=!chunkCount!-1
      for /L %%C in (1,1,!chunkCount!) do (
        !orbisPubCmd! gp4_chunk_add --id %%C --label remaining_data%%C "!pathGp4!"
      )
    )
  ) else (!orbisPubCmd! gp4_proj_create --volume_type !volumeType! --content_id !contentNewID! --passcode !passcode! --entitlement_key !passcode! "!pathGp4!")
  if %ERRORLEVEL% NEQ 0 (echo gp4 proj create failed... & goto :batchNext)
  
  if "!pfsCompression!"=="y" (set compression=enable) else (set compression=disable)
  for /F %%N in ('dir /b /s /a:-d "!pathImage0!"') do (
    set name=%%~nN
    set ext=%%~xN
    set fullname=%%N
    call set subName=%%fullname:!pathImage0!\=%%
    if "!subName!"=="sce_sys\nptitle.dat" (
      if not "!contentTitleID!"=="!newTitleIDTmp!" (
        echo [Warn] Fix the TitleID [!contentTitleID! to !newTitleIDTmp!] of !subName!
        binEdit.vbs "!fullname!" "!contentTitleID!" "!newTitleIDTmp!"
      )
      !orbisPubCmd! gp4_file_add --force --pfs_compression !compression! !fullname! !subName:\=/! "!pathGp4!"
    ) else if "!subName!"=="sce_sys\playgo-chunk.dat" (
      if not "!contentTitleID!"=="!newTitleIDTmp!" (
        echo [Warn] Fix the TitleID [!contentTitleID! to !newTitleIDTmp!] of !subName!
        binEdit.vbs "!fullname!" "!contentTitleID!" "!newTitleIDTmp!"
      )
    ) else if "!subName!"=="sce_sys\app\playgo-chunk.dat" (
      if not "!contentTitleID!"=="!newTitleIDTmp!" (
        echo [Warn] Fix the TitleID [!contentTitleID! to !newTitleIDTmp!] of !subName!
        binEdit.vbs "!fullname!" "!contentTitleID!" "!newTitleIDTmp!"
      )
    ) else if "!subName:sce_sys\about=!"=="!subName!" if "!subName:sce_sys\playgo-=!"=="!subName!" if not "!subName!"=="sce_discmap.plt" if not "!subName!"=="sce_discmap_patch.plt" if not "!subName!"=="sce_sys\pubtoolinfo.dat" (
      !orbisPubCmd! gp4_file_add --force --pfs_compression !compression! !fullname! !subName:\=/! "!pathGp4!")
  )
  
  if not exist !pathSceSys!\icon0.png (
    if exist !icon0Path! (!orbisPubCmd! gp4_file_add --force !icon0Path! sce_sys/icon0.png "!pathGp4!")
  )
)

if "!pkgCreate!"=="y" (
  echo [Info] Creating !newPkgName!.pkg...
  if "!pkgDigest!"=="y" (set digest=) else (set digest=--skip_digest)
  if not exist !pkgFullPath!\!genDirName! (mkdir !pkgFullPath!\!genDirName!)
  !orbisPubCmd! img_create --no_progress_bar !digest! "!pathGp4!" !pkgFullPath!\!genDirName!\!newPkgName!.pkg
)

if "!cleanup!"=="y" rmdir /s/q !pathPkgRoot!

:batchNext
echo:
echo:
goto :eof


::
:: Create VBS to replace values
:: Usage: cscript binEdit.vbs "inPath" "oldStr" "newStr"
::
:CreateBinEditVBS
echo inPath = Wscript.Arguments(0) > binEdit.vbs
echo oldStr = Wscript.Arguments(1) >> binEdit.vbs
echo newStr = Wscript.Arguments(2) >> binEdit.vbs
echo oldHex = StrToHex(oldStr) >> binEdit.vbs
echo newHex = StrToHex(newStr) >> binEdit.vbs

echo BinaryData = ReadBinary(inPath) >> binEdit.vbs
echo MyData = Replace(BinaryData, oldHex, newHex) >> binEdit.vbs

echo Dim Fso >> binEdit.vbs
echo Set Fso = WScript.CreateObject("Scripting.FileSystemObject") >> binEdit.vbs

echo if Fso.FileExists(inPath ^& ".bak") then >> binEdit.vbs
echo   Fso.DeleteFile(inPath ^& ".bak") >> binEdit.vbs
echo end if >> binEdit.vbs

echo Fso.MoveFile inPath, inPath ^& ".bak"  >> binEdit.vbs

echo WriteBinary inPath, MyData >> binEdit.vbs

echo Wscript.Quit(0) >> binEdit.vbs

echo Function StrToHex(Str) >> binEdit.vbs
echo   Dim strHex >> binEdit.vbs
echo   For i=1 To Len(Str) >> binEdit.vbs
echo     strHex = strHex + Hex(Asc(Mid(Str,i,1))) >> binEdit.vbs
echo   Next >> binEdit.vbs
echo   StrToHex = strHex >> binEdit.vbs
echo End Function >> binEdit.vbs

echo Function ReadBinary(FileName) >> binEdit.vbs
echo  Dim Stream, ObjXML, MyNode >> binEdit.vbs

echo  Set ObjXML = CreateObject("Microsoft.XMLDOM") >> binEdit.vbs
echo  Set MyNode = ObjXML.CreateElement("binary") >> binEdit.vbs
echo  Set Stream = CreateObject("ADODB.Stream") >> binEdit.vbs

echo  MyNode.DataType = "bin.hex" >> binEdit.vbs

echo  Stream.Type = 1 >> binEdit.vbs
echo  Stream.Mode = 3 >> binEdit.vbs
echo  Stream.Open >> binEdit.vbs
echo  Stream.Position = 0 >> binEdit.vbs
echo  Stream.LoadFromFile FileName >> binEdit.vbs

echo  MyNode.NodeTypedValue = Stream.Read() >> binEdit.vbs

echo  Stream.Close >> binEdit.vbs

echo  ReadBinary = MyNode.Text >> binEdit.vbs

echo  Set MyNode = Nothing >> binEdit.vbs
echo  Set Stream = Nothing >> binEdit.vbs
echo  Set ObjXML = Nothing >> binEdit.vbs
echo End Function >> binEdit.vbs

echo Function WriteBinary(FileName, BufferData) >> binEdit.vbs
echo  Dim Stream, ObjXML, MyNode >> binEdit.vbs

echo  Set ObjXML = CreateObject("Microsoft.XMLDOM") >> binEdit.vbs
echo  Set MyNode = ObjXML.CreateElement("binary") >> binEdit.vbs
echo  Set Stream = CreateObject("ADODB.Stream") >> binEdit.vbs

echo  MyNode.DataType = "bin.hex" >> binEdit.vbs
echo  MyNode.Text = BufferData >> binEdit.vbs

echo  Stream.Type = 1 >> binEdit.vbs
echo  Stream.Open >> binEdit.vbs
echo  if Lenb(MyNode.NodeTypedValue) ^> 0 then >> binEdit.vbs
echo    Stream.Write MyNode.NodeTypedValue >> binEdit.vbs
echo  end if >> binEdit.vbs
echo  Stream.SaveToFile FileName, 2 >> binEdit.vbs
echo  Stream.Close >> binEdit.vbs

echo  Set stream = Nothing >> binEdit.vbs
echo  Set MyNode = Nothing >> binEdit.vbs
echo  Set ObjXML = Nothing >> binEdit.vbs
echo End Function >> binEdit.vbs

goto :eof


:batchEnd

pause