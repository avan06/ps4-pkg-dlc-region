﻿# ps4-pkg-dlc-region

v1.4  

ps4-pkg-dlc-region is windows batch script can batch change the region and TitleID of the original ps4 Pkg(dlc, patch, app), and it is base on [`orbis-pub-gen`](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/) and [`sfo by Hippie68`](https://www.psxhax.com/threads/ps4-sfo-program-to-automate-build-param-sfo-files-by-hippie68.11507/).  

It will automatically determine that the volume_type of the original pkg is pkg_ps4_ac_data or pkg_ps4_ac_nodata, pkg_ps4_patch,  pkg_ps4_app

- pkg_ps4_ac_data:  
DLC with extra files  

- pkg_ps4_ac_nodata:  
DLC without extra files (unlockable)  

- pkg_ps4_patch:  
PS4 Game Update (during the parsing, you will be prompted to enter the original PS4 Game PKG path)  

- pkg_ps4_app:  
PS4 Game  

Note: The experimental features of pkg_ps4_patch and pkg_ps4_app have not been tested...


## User Defined

Before the first execution, the user needs to determine several defined values in ps4-pkg-dlc-region.cmd  

- orbisPubPath  
Determines the path of orbis-pub, nullable if it has been set in the path of windows  

- sfoPath  
Determines the path of sfo(hippie68), nullable if it has been set in the path of windows  

- pkgPath  
Specify the path for the PKG files to be scanned. Multiple PKG files can be scanned in batches.


### Optional options (param.sfo)

- newRegion (length is 2)  
Determine the Region of the generated pkg  
Empty value, indicating that the Region is unchanged  
JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean  

- newRegionID (length is 4)  
Determine the RegionID(length is 4 number) of the generated pkg  
Empty value, indicating that the RegionID is unchanged  

- newTitleID (length is 9)  
Determine the TitleID of the generated pkg  
Empty value, indicating that the TitleID is unchanged  

- newContentName (length is 16)  
Determine the ContentName of the generated pkg  
Empty value, indicating that the ContentName is unchanged  
ContentName is the name at the end of CONTENT_ID, which is typically 16 characters in length.  

- newSdkVer (length is 8)  
Please specify the SdkVer for the generated pkg.  
Leave it blank if you don't want to change it.  
SdkVer is an attribute value in the PUBTOOLINFO of param.sfo file, and it is usually set to 05050000.  


### Misc options  

- genDirName  
Determines the directory name for the generated output  

- icon0Path  
Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file  

- cleanup  
y: remove all temporary files, n: don't delete anything  

- passcode  
Determine the passcode value for pkg (extract and generate)  


### Extract options  

- pkgExtractShowStatus 
Determines whether to show the extract status, show extract status will be slower if the pkg file size is very large,  
y: show, n: not show


### Overwrite options  

- overwriteUnpackedArchives 
Determines whether to still extract when an unpacked PKG archive already exists,  
y: perform extract and overwrite, n: use existing unpacked file  

- overwriteExistGP4 
Determines whether to override gp4 configuration, when gp4 archive already exists,  
y: generate new gp4 file, n: use existing gp4 file  


### Generate options  

- pkgCreate 
Determines whether to automatically generate a new PKG after extract,  
y: generate new PKG, n: extract only  

- pfsCompression 
Determines whether to enable compression for package files,  
y: compressed, n: not compressed  

- pkgDigest 
Determines whether to calculate digest after pkg create,  
y: digest calculation, n: faster creation  


## Reference

[How to Change PS4 DLC Region for Fake PKG Games Tutorial by Jr550](https://www.psxhax.com/threads/how-to-change-ps4-dlc-region-for-fake-pkg-games-tutorial-by-jr550.6038/)  
[orbis-pub-gen](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/)  
[PS4-Fake-PKG-Tools-3.87 by CyB1K](https://github.com/CyB1K/PS4-Fake-PKG-Tools-3.87)  
[sfo by Hippie68](https://github.com/hippie68/sfo)  
[ps4-dlc-unlocker-maker](https://www.psxhax.com/threads/ps4-dlc-unlocker-maker-windows-batch-file-to-create-fpkgs-by-k4ps3.11035/)  

