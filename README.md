# Computer Craft Music Maker
A little project for CC:Tweaked.
Pastebin links will be provided when the project is finished

## In disk/ you find the Original version of the player containing organ.lua, player.lua and startup.lua
The following section is for this Version of the Player

There are 3 files that go on a disk.
- organ.lua - This will play .organ files and send the commands to all the players
- player.lua - Every player needs this "installed", it is to receive the commands and output the correct redstone signal
- startup.lua - This will copy the organ.lua or player.lua file to the system depending on user input.

### .organ files
.organ files have a specific format that they are build in.
When you want to enable a note you use the following format: note <NOTE> pipe <pipe> where note is the defined note and pipe is the defined player.
You can also play a note for a short amount of time, good for noteblocks for that you do: note <NOTE> pipe <pipe> single
A delay can be defined with delay <SECONDS>
Comments can be created with // for single line and /* */ for multi line.

### player.conf
The player.conf gets created when you start a player for the first time. It holds the note and the pipe name.

## In Organ_Advanced/ is the newer version of the Player. 
It contains more files that are needed for everything to work.

**!ADVANCED PERIPHERALS IS NEEDED TO SETUP A PLAYER!**

**Current Features:**
- Using Basalt as UI Libary to provide better Usibility
- Only needs 1 ComputerCraft:Tweaked PC to function
- It can Create, Edit, and Delete .org files.

**Features to Come**
- Manage different Pipes with a dedicated Pipe section
- Edit .conf file from the PC
- Testing Pipes
- **MAYBE**: Using CC:T Phones to edit .conf file remotely while setting up the Organ
