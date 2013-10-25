Hammer - Rebol meta editor
====

This tool is an editor like none you've ever used.  Beyond allowing you 
to run highlighed code and the current line on the fly, it allows you full access
to its internals.

The tool is open source but it's also running your code within itself, allowing
you to actually modify the editor itself with a few lines of code!

Add panes, switch them, add buttons, all as you wish, even linking your running code
to itself for testing purposes.

For now its still very much a work in progress, but its already a very useful Editor for replacing
the console in interactive rebol sessions.

Future
====

It will eventually be part of a new Development environment called Anvil, which will be the main
application of the Steel repository.


Hotkeys
====

* F5: to run the current line (all lines with a cursor)

* F5: to run the currently highlighted code (manages multiple selections, in their order of selection!)



Editor peculiarities
====

* Multiple cursors :  Press Ctrl plus click and you will add a cursor to the editor, allowing to edit at more than one position simultaneously.

* vprinting :  If you want to see results in the output frame, you must use vprint, vprobe, vprin, vin, vout and other vprinting functions from the slim library manager.



hammer