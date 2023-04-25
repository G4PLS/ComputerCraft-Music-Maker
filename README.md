# Computer Craft Music Maker
A little project for CC:Tweaked.

There are 3 files that go on a disk.
- organ.lua - This will play .organ files and send the commands to all the players
- player.lua - Every player needs this "installed", it is to receive the commands and output the correct redstone signal
- startup.lua - This will copy the organ.lua or player.lua file to the system depending on user input.

## .organ files
.organ files have a specific format that they are build in.
When you want to enable a note you use the following format: note <NOTE> pipe <pipe> where note is the defined note and pipe is the defined player.
You can also play a note for a short amount of time, good for noteblocks for that you do: note <NOTE> pipe <pipe> single
A delay can be defined with delay <SECONDS>
Comments can be created with // for single line and /* */ for multi line.

## player.conf
The player.conf gets created when you start a player for the first time. It holds the note and the pipe name.
