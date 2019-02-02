@echo off
REM Define rclone and config file locations
set rclone=rclone.exe
set config_file=%userprofile%\.config\rclone\rclone.conf
@echo off

REM Show current versions
echo Script version:
echo SendTo-rclone-GDrive v1.1 by Moodkiller
echo.
echo rclone version details:
"%rclone%" --version
echo.
echo Stats:
"%rclone%" about gdrive:/
echo. 

REM Use rclone to display a list of files in the root of Google Drive for eaiser direction defining
:start
echo Listing current FOLDERS on your GDrive (this will take a while if you have a lot):...
"%rclone%" --config "%config_file%" lsd gdrive: --fast-list

REM Auto directory generation
echo.
set /p autodir=Do you want to use the current directory as a folder structure? [y/n]: 
if %autodir% == y goto autodir
if not %autodir% == y goto manualdir

:manualdir
echo.
set /p destination=Type out the full path you want to upload into: 
goto set_destination

:Autodir
REM Store the current working directories folder name in a variable 
for %%I in (.) do (
	set CurrDirName=%%~nxI
)
echo.
echo Define the folder to upload your files into (on GDrive). 
echo This can be in the format of just Folder or Folder/Folder2/etc.
REM echo [93mNote: You DON'T have to enter the current folder name you are uploading from, the script will do that for you.[0m 
echo.
:set_destination
set /p destination=Define folder to upload to from the above (Folder, Folder/Folder/etc)? 
echo.

echo [92mSanity check: your files will be uploading to My Drive/%destination%/%CurrDirName%[0m
echo.
set /p var=Is this correct? [y/n]: 
if %var%== y goto upload
if not %var%== y goto set_destination
echo.

:upload
REM No limit here, just sensible numbers
echo.
set /p transfers=Number of simultaneous transfers (1-15)?: 
echo.

:speedlimit
REM Ideal to set to avoid remote upload limits
set /p bwlimit=Set upload speed limit (e.g. 8M to avoid GDrive daily 750GB limit )?: 
echo.

:options
REM Specify any other rlcone flags. See the docs or type "rclone help flags"
set /p options=Specify any other flags, press enter to skip (e.g --dry-run -vv):
echo.

:rclone
REM Move SELECTED files to be uploaded to a temp directory located in the current working directory. Hack way to make rclone upload selected files at once or to the defined %transfers% amount.
echo [93mNote: Moving files to temp folder for simultaneous transfers.[0m 
echo.

for %%f in (%*) do (
	if not exist temp mkdir temp
	move %%f "%cd%\temp\%%~nxf"
)

REM full list of rclone options can be found in the offical documentatation https://rclone.org/docs/#options
"%rclone%" --config "%config_file%" copy %options% --progress --ignore-existing --transfers %transfers% --bwlimit %bwlimit% --checkers 10 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats-file-name-length 0 --stats 1s "%cd%\temp" "gdrive:%destination%/%CurrDirName%"

REM Move files back from temp folder to thier original location, delete temp folder after
echo Moving files back to their original location and deleting temp foler.

for /r %%i in ("temp\*.*") do move "%%i" "%cd%\%%~nxi"
rmdir temp
echo.
echo [92mCheck this location for your file(s): My Drive/%destination%/%CurrDirName%[0m

REM Link... hopefully
echo GDrive specific link:
"%rclone%" link "gdrive:%destination%/%CurrDirName%"
@pause