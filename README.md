# ps4-pkg-dlc-region

ps4-pkg-dlc-region is windows batch script can batch change the region and TitleID of the original ps4 dlc Pkg, and it is base on [`orbis-pub-gen`](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/) and [`sfo by Hippie68`](https://www.psxhax.com/threads/ps4-sfo-program-to-automate-build-param-sfo-files-by-hippie68.11507/).


## User Defined

Before the first execution, the user needs to determine several defined values in ps4-pkg-dlc-region.cmd  

- orbisPubPath  
Determines the path of orbis-pub, nullable if it has been set in the path of windows  

- sfoPath  
Determines the path of sfo(hippie68), nullable if it has been set in the path of windows  

- pkgPath  
Determine the path to the original pkg  

- newRegion(length is 2)  
Determine the Region of the generated pkg  
JP: Japanese, EP: European, UP: American, HP: Hong Kong, KP: Korean  

- newTitleID(length is 9)  
Determine the TitleID of the generated pkg  

- genDirName  
Determines the directory name for the generated output  

- icon0Path  
Determine the path of icon0.png when the original pkg has no preview image, the generated pkg will use this file  

- cleanup  
y: remove all temporary files, n: don't delete anything  

- passcode  
Determine the passcode value for pkg  


## Reference

[How to Change PS4 DLC Region for Fake PKG Games Tutorial by Jr550](https://www.psxhax.com/threads/how-to-change-ps4-dlc-region-for-fake-pkg-games-tutorial-by-jr550.6038/)  
[orbis-pub-gen](https://www.psxhax.com/threads/free-ps2-pub-gen-fake-pkg-tools-ps2-fake-pkg-generator-for-ps4.3594/)  
[sfo by Hippie68](https://www.psxhax.com/threads/ps4-sfo-program-to-automate-build-param-sfo-files-by-hippie68.11507/)  
[ps4-dlc-unlocker-maker](https://github.com/K4PS3/ps4-dlc-unlocker-maker)  

