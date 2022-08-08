# ps4-pkg-dlc-region

ps4-pkg-dlc-region is windows batch script can batch change the region and TitleID of the original ps4 dlc Pkg, and it is base on [`orbis-pub-gen`](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/) and [`sfo by Hippie68`](https://www.psxhax.com/threads/ps4-sfo-program-to-automate-build-param-sfo-files-by-hippie68.11507/).  

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
Determine the path to the original pkg  

- newRegion (length is 2)  
Determine the Region of the generated pkg  
JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean  

- newTitleID (length is 9)  
Determine the TitleID of the generated pkg  

- genDirName  
Determines the directory name for the generated output  

- icon0Path  
Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file  

- cleanup  
y: remove all temporary files, n: don't delete anything  

- passcode  
Determine the passcode value for pkg  

- overwriteUnpackedArchives (New)  
Determines whether to still extract when an unpacked PKG archive already exists,  
y: perform extract and overwrite, n: use existing unpacked file  

- overwriteExistGP4 (New)  
Determines whether to override gp4 configuration, when gp4 archive already exists,  
y: generate new gp4 file, n: use existing gp4 file  

- pkgCreate (New)  
Determines whether to automatically generate a new PKG after extract,  
y: generate new PKG, n: extract only  


## Reference

[How to Change PS4 DLC Region for Fake PKG Games Tutorial by Jr550](https://www.psxhax.com/threads/how-to-change-ps4-dlc-region-for-fake-pkg-games-tutorial-by-jr550.6038/)  
[orbis-pub-gen](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/)  
[sfo by Hippie68](https://www.psxhax.com/threads/ps4-sfo-program-to-automate-build-param-sfo-files-by-hippie68.11507/)  
[ps4-dlc-unlocker-maker](https://www.psxhax.com/threads/ps4-dlc-unlocker-maker-windows-batch-file-to-create-fpkgs-by-k4ps3.11035/)  

