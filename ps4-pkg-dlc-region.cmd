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
:: Specify the path for the PKG files to be scanned. Multiple PKG files can be scanned in batches.
set pkgPath=.\dlc

:: =========== PKG name description ===========
:: AA0123-CUSA01234_00-ABCDEFGHIJKLMNOP-A0123-V0123
:: {RegionLen:2}{RegionIDLen:4}-{TitleIDLen:9}_00-{ContentNameLen:16}-A{appVerLen:4}-V{versionLen:4}
:: Param.sfo - PS4 Developer wiki: https://www.psdevwiki.com/ps4/Param.sfo

:: =========== param.sfo options ===========
:: Determine the Region(length is 2) of the generated pkg
:: Empty value, indicating that the Region is unchanged
:: JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean
set newRegion=
:: Determine the RegionID(length is 4 number) of the generated pkg
:: Empty value, indicating that the RegionID is unchanged
set newRegionID=
:: Determine the TitleID(length is 9) of the generated pkg
:: Empty value, indicating that the TitleID is unchanged
set newTitleID=
:: Determine the ContentName of the generated pkg
:: Empty value, indicating that the ContentName is unchanged
:: ContentName is the name at the end of CONTENT_ID, which is typically 16 characters in length.
set newContentName=
:: Please specify the SdkVer for the generated pkg. 
:: Leave it blank if you don't want to change it. 
:: SdkVer is an attribute value in the PUBTOOLINFO of param.sfo file, and it is usually set to 05050000.
set newSdkVer=

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
set overwriteUnpackedArchives=n
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

echo ---------------------------------------------------
echo   ps4 pkg dlc region changes batch script v1.4
echo   based on orbis-pub-gen and sfo
echo ---------------------------------------------------
echo.
echo    The PKG path is %pkgPath%
echo    The new Region is %newRegion%
echo    The new RegionID is %newRegionID%
echo    The new TitleID is %newTitleID%
echo    The new ContentName is %newContentName%
echo    The new SdkVer is %newSdkVer%
echo.
echo ===================================================
echo.

set orbisPubCmd=orbis-pub-cmd
if exist %orbisPubPath% orbisPubCmd=%orbisPubPath%/%orbisPubCmd%
set sfoCmd=sfo
if exist %sfoPath% sfoCmd=%sfoPath%/%sfoCmd%

where %orbisPubCmd% >nul
if %errorlevel% NEQ 0 (echo [Error] orbis-pub-cmd not found & goto :batchEnd)
where %sfoCmd% >nul
if %errorlevel% NEQ 0 (echo [Error] sfo not found & goto :batchEnd)

:: Convert pkgFullPath from a relative path to an absolute path.
set pkgFullPath=%pkgPath%
pushd %pkgFullPath%
set pkgFullPath=%CD%
popd

call :CreateBinEditVBS

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
  set USER_DEFINED_PARAM_1=
  set pathPkgRoot=
  set pathSc0=
  set pathImage0=
  set pathSceSys=
  set pathGp4=
  set fullname=%%F
  set /a count += 1
  echo !count!: !fullname!
  call :SfoQuery
  call :GeneratePkg
)

goto :batchEnd

:SfoQuery

set queryPath=!fullname!

if exist !pathSceSys!\param.sfo set queryPath=!pathSceSys!\param.sfo

for /f "tokens=*" %%i in ('!sfoCmd! -q CATEGORY "!queryPath!" 2^> nul') do (set CATEGORY=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q CONTENT_ID "!queryPath!" 2^> nul') do (set CONTENT_ID=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q FORMAT "!queryPath!" 2^> nul') do (set FORMAT=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q PUBTOOLINFO "!queryPath!" 2^> nul') do (set PUBTOOLINFO=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q PUBTOOLVER "!queryPath!" 2^> nul') do (set PUBTOOLVER=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q TITLE "!queryPath!" 2^> nul') do (set TITLE=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q TITLE_ID "!queryPath!" 2^> nul') do (set TITLE_ID=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q APP_VER "!queryPath!" 2^> nul') do (set APP_VER=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q VERSION "!queryPath!" 2^> nul') do (set VERSION=%%i)
for /f "tokens=*" %%i in ('!sfoCmd! -q USER_DEFINED_PARAM_1 "!queryPath!" 2^> nul') do (set USER_DEFINED_PARAM_1=%%i)

if "!CONTENT_ID!"=="" (!sfoCmd! !queryPath! & echo [Error] Sfo invalid CONTENT_ID. & goto :batchNext)

:: Edit/Replace text within a Variable, Syntax %variable:StrToFind=NewStr%
:: https://ss64.com/nt/syntax-replace.html
if not "!PUBTOOLINFO:digital50=!"=="!PUBTOOLINFO!" (set storageType=digital50
) else if not "!PUBTOOLINFO:digital25=!"=="!PUBTOOLINFO!" (set storageType=digital25
) else if not "!PUBTOOLINFO:bd50_50=!"=="!PUBTOOLINFO!" (set storageType=bd50_50
) else if not "!PUBTOOLINFO:bd50_25=!"=="!PUBTOOLINFO!" (set storageType=bd50_25
) else if not "!PUBTOOLINFO:bd50=!"=="!PUBTOOLINFO!" (set storageType=bd50
) else if not "!PUBTOOLINFO:bd25=!"=="!PUBTOOLINFO!" (set storageType=bd25
) else set storageType=

:: appVer and version, length of left padding
set numLen=4
if "!APP_VER!"=="" (set appVerStr=0000) else (
  set appVerStr=0000!APP_VER:.=!
  set appVerStr=!appVerStr:~-%numLen%!
)

if "!VERSION!"=="" (set versionStr=0000) else (
  set versionStr=0000!VERSION:.=!
  set versionStr=!versionStr:~-%numLen%!
)

set contentRegion=!CONTENT_ID:~0,2!
set contentNumber=!CONTENT_ID:~2,4!
set contentTitleID=!CONTENT_ID:~7,9!
set contentTitleINum=!CONTENT_ID:~16,4!
set contentName=!CONTENT_ID:~20!
set newRegionTmp=!newRegion!
set newRegionIDTmp=!newRegionID!
set newTitleIDTmp=!newTitleID!
set newContentNameTmp=!newContentName!
set newSdkVerTmp=!newSdkVer!

if "!newRegionTmp!"=="" set newRegionTmp=!contentRegion!
if "!newRegionIDTmp!"=="" set newRegionIDTmp=!contentNumber!
if "!newTitleIDTmp!"=="" set newTitleIDTmp=!contentTitleID!
if "!newContentNameTmp!"=="" set newContentNameTmp=!contentName!

set contentNewID=!newRegionTmp!!newRegionIDTmp!-!newTitleIDTmp!!contentTitleINum!!newContentNameTmp!
set appVersion=A!appVerStr!-V!versionStr!
set newPkgName=!contentNewID!-!appVersion!
set pathPkgRoot=!pkgFullPath!\!newPkgName!
set pathSc0=!pathPkgRoot!\Sc0
set pathImage0=!pathPkgRoot!\Image0
set pathSceSys=!pathImage0!\sce_sys
set pathGp4=!pathPkgRoot!\!contentNewID!.gp4

goto :eof

::
:: Generate DLC Package
::
:GeneratePkg

if exist !pathSceSys!\param.sfo (call :SfoQuery)

echo ==================== SFO Info ====================
echo   CATEGORY: !CATEGORY!
echo   CONTENT_ID: !CONTENT_ID!
echo   FORMAT: !FORMAT!
echo   PUBTOOLINFO: !PUBTOOLINFO!
echo   PUBTOOLVER: !PUBTOOLVER!
echo   TITLE: !TITLE!
echo   TITLE_ID: !TITLE_ID!
echo   APP_VER: !APP_VER!
echo   VERSION: !VERSION!
echo   USER_DEFINED_PARAM_1: !USER_DEFINED_PARAM_1!
echo   StorageType: !storageType!
echo.
echo   ContentNewID: !contentNewID!
echo   PathImage0: !pathImage0!
echo   PathSceSys: !pathSceSys!
echo   PathGp4: !pathGp4!

set doExtract=y
if "!overwriteUnpackedArchives!"=="n" if exist "!pathPkgRoot!" (set doExtract=n)
if not exist !pathPkgRoot! (mkdir !pathPkgRoot!)
if "!doExtract!"=="y" (
echo ==================== Extract ====================
  set /a fileCount=0
  echo [Info] extract pkg to !newPkgName!
  if "!pkgExtractShowStatus!"=="y" (
    for /f "tokens=3,5" %%a in ('!orbisPubCmd! img_file_list --passcode !passcode! --oformat long "!fullname!" 2^> nul') do (
      set pkgName=%%a
      set dirName=!pkgName:/=\!
      set file=%%b
      if not "!file!"=="" (
        set /a fileCount=!fileCount!+1
        set idx=00000!fileCount!
        rem set files[!fileCount!]=!file!
        set winFile=!file:/=\!
        echo     !idx:~-5!: !file!
        if not exist !pathPkgRoot!\!winFile! (
          for /f "tokens=* " %%a in ('!orbisPubCmd! img_extract --passcode !passcode! "!fullname!:!file!" !pathPkgRoot!\!winFile!') do set result=%%a
          echo !result! | find /i "error" > nul
          if !errorlevel! equ 0 (echo !result!)
        )
      ) else (
        if not exist !pathPkgRoot!\!dirName! (
          mkdir !pathPkgRoot!\!dirName!
          set "depth=0"
          for %%A in ("!pkgName:/=" "!") do set /a depth+=1
          if !depth! GTR 2 (
            echo [DIR] extract: !pkgName!
            for /f "tokens=* " %%a in ('!orbisPubCmd! img_extract --passcode !passcode! "!fullname!:!pkgName!" !pathPkgRoot!\!dirName!') do set result=%%a
            echo !result! | find /i "error" > nul
            if !errorlevel! equ 0 (echo !result!)
          )
        )
      )
    )
  rem for /L %%i in (1,1,!fileCount!) do (
  rem   set file=!files[%%i]!
  rem   set winFile=!file:/=\!
  rem   echo extract!fileCount!: !file!
  rem   !orbisPubCmd! img_extract --passcode !passcode! "!fullname!:!file!" !pathPkgRoot!\!winFile! 1> nul
  rem )
  ) else !orbisPubCmd! img_extract --passcode !passcode! "!fullname!" !pathPkgRoot!
)

set volumeType=pkg_ps4_ac_data
if not exist !pathImage0! (set volumeType=pkg_ps4_ac_nodata)
if not exist !pathSceSys! (mkdir !pathSceSys!)

echo ==================== Sc0 ====================
echo [Info] move Sc0 to Image0\sce_sys\
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
    move /y "!fullname!" "!pathSceSys!" >nul 2>&1
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
  ) else if not !name!!ext!==license.dat if not !name!!ext!==license.info if not !name!!ext!==psreserved.dat if not !name!!ext!==origin-deltainfo.dat if not !name!!ext!==pubtoolinfo.dat ( ::if "!name:playgo-=!"=="!name!" if not !ext!==.dds
    if "!dirAttr!"=="d" (
      if not exist !pathSceSys!!subName! mkdir !pathSceSys!!subName!
    ) else (move /y "!fullname!" "!pathSceSys!!subName!" >nul 2>&1)
  )
)

if not "!CONTENT_ID!"=="!contentNewID!" (
echo ==================== param.sfo ====================
echo [Info] edit param.sfo
!sfoCmd! -e CONTENT_ID "!contentNewID!" -e TITLE_ID "!newTitleIDTmp!" !pathSceSys!\param.sfo
)
set newPUBTOOLINFO=
if not "!PUBTOOLINFO:sdk_ver=!"=="!PUBTOOLINFO!" if not "!newSdkVerTmp!"=="" (
  for %%a in ("!PUBTOOLINFO:,=" "!") DO (
    set info=%%a
    if not "!newPUBTOOLINFO!"=="" set newPUBTOOLINFO=!newPUBTOOLINFO!,
    if not "!info:sdk_ver=!"=="!info!" (
      :: echo !info:"=!
      set newPUBTOOLINFO=!newPUBTOOLINFO!sdk_ver=!newSdkVerTmp!
    ) else set newPUBTOOLINFO=!newPUBTOOLINFO!!info:"=!
  )
  
  if not "!PUBTOOLINFO!"=="!newPUBTOOLINFO!" (
    echo ==================== PUBTOOLINFO ====================
    echo [into] new PUBTOOLINFO: !newPUBTOOLINFO!
    echo [Info] Edit the sdk_ver in PUBTOOLINFO in param.sfo.
    !sfoCmd! -e PUBTOOLINFO "!newPUBTOOLINFO!" !pathSceSys!\param.sfo
  )
)
if exist "!pathGp4!" if "!overwriteExistGP4!"=="y" del /q "!pathGp4!"
if not exist "!pathGp4!" (
echo ==================== gp4 create ====================
  if !CATEGORY!==gp (
    set volumeType=pkg_ps4_patch
    echo Handling !newTitleIDTmp!-patch is required the original !newTitleIDTmp!-app pkg...
:EnterBaseGamePath
    echo [Drag and drop] the PKG file or [Enter] the path for "!TITLE!":
    set /p appPath=
    if not exist !appPath! (echo !newTitleIDTmp!-app path: !appPath! & echo Does not exist... & echo. & goto :EnterBaseGamePath)
    echo.
    set appPath=!appPath:"=!
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
  echo   volumeType: !volumeType!
  echo.
  if %errorlevel% NEQ 0 (echo [Error] gp4 proj create failed... & goto :batchNext)
  echo [Info] Generating gp4 file now...
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
    ) else if "!subName:sce_sys\about=!"=="!subName!" if "!subName:sce_sys\playgo-=!"=="!subName!" if not "!subName!"=="sce_discmap.plt" if not "!subName!"=="sce_discmap_patch.plt" if not "!subName!"=="sce_sys\pubtoolinfo.dat" if not "!ext!"==".dds" (
      !orbisPubCmd! gp4_file_add --force --pfs_compression !compression! !fullname! !subName:\=/! "!pathGp4!")
  )
  
  if not exist !pathSceSys!\icon0.png (
    if exist !icon0Path! (!orbisPubCmd! gp4_file_add --force !icon0Path! sce_sys/icon0.png "!pathGp4!")
  )
)

if "!pkgCreate!"=="y" (
  echo ==================== PKG Create ====================
  echo [Info] Creating !newPkgName!.pkg...
  if "!pkgDigest!"=="y" (set digest=) else (set digest=--skip_digest)
  if not exist !pkgFullPath!\!genDirName! (mkdir !pkgFullPath!\!genDirName!)
  !orbisPubCmd! img_create --no_progress_bar !digest! "!pathGp4!" !pkgFullPath!\!genDirName!\!newPkgName!.pkg
)

if "!cleanup!"=="y" (
echo ==================== Temp files removed ====================
rmdir /s/q !pathPkgRoot!
)

:batchNext
echo ===================================================
echo.
echo.
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