# Simple-editor-in-ANS-Forth
SED - an editor written with ANS Forth words in a simple and extendable manner.

A buffer EDBUF is thought of as a 64xN array of bytes. 
There is no address pointer to the buffer, the address is calculated thru the
variables EDROW and EDCOL.

The main action of the words is to manipulate this buffer and
secondary to show a part of the buffer on the screen.

The editor should have no wordwrap and each row could contain a maximum of 63 characters,
which is enough for source files of Forth code.

To be done: 
scrolling using the variable TOPROW
fast cursor movments
load and save files

So far only tested for GForth+Windows. Different possibilities for the implementation of EKEY
will cause problems for use in all ANS Forth systems.
