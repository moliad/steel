rebol [
	; -- Core Header attributes --
	title: "console function detector"
	file: %console-detector.r
	version: 0.0.1
	date: 2013-11-22
	author: "Maxim Olivier-Adlhoch"
	purpose: {lists all lines and files which have console functions uncommented.}
	web: http://www.revault.org/
	source-encoding: "Windows-1252"

	; -- Licensing details  --
	copyright: "Copyright © 2013 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
	license: {Copyright © 2013 Maxim Olivier-Adlhoch

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.}

	;-  / history
	history: {
		v0.0.1 - 2013-11-22
			-Created file
	}
	;-  \ history

	;-  / documentation
	documentation: {
		This is a very useful script to find lists of all the console interacting
		functions being used in a script.  It is used mainly to find them so they
		can be removed before release, where they get annoying, cause they force
		the console window to open.

		You can edit the list of words at the top of the script if you want to
		find other words.
		
		
		ARGS:
		-----
		
		Just provide a (system file path on the command line.
		
		If you specify a folder path, we run the loop on all the files it contains.
	}
	;-  \ documentation
]




;;-                                                                                                         .
;;-----------------------------------------------------------------------------------------------------------
;;
;;- LIBS
;;
;;-----------------------------------------------------------------------------------------------------------
;;----
;; starts the slim library manager, if it's not setup.. the following loading setup allows slim 
;; to be installed either within the steel project or just outside of it, to be shared in multiple
;; tools.
;; 
;unless value? 'slim [
;	do any [
;		all [ exists? %../slim-path-setup.r do read %../slim-path-setup.r ]
;		all [ exists? %../../slim-libs/slim/slim.r  %../../slim-libs/slim/slim.r ] 
;		all [ exists? %../slim-libs/slim/slim.r     %../slim-libs/slim/slim.r    ] 
;	]
;]
;
;slim/vexpose








;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- GLOBALS
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;- words-to-find:
;
; set this to whatever you wish to detect in the file... 
; note that it will require separators around them ("printer" is not matched by "print").
;--------------------------
words-to-find: [ "print" | "prin" |  "ask" | "probe" ] ; "vprin" | "vprobe" |



=digit=: charset "0123456789"
=alpha=: charset [#"a" - #"z" #"A" - #"Z"]
=digits=: [some =digit=]
=newline=: [ crlf | newline ]

=space=: charset " ^-"
=spaces=: [ SOME =space= ]
=whitespace=: charset " ^-^/"
=whitespaces=: [some =whitespace=] ; optional space (often after newline or between known delimiter)

=colon=: charset ":"
=lbl-char=: union (union =alpha= =digit=) charset "-_"
=lbl=: [=alpha= any =api-lbl-char=]

=separator=: [=whitespaces= | end]
=separators=: [some [=whitespaces= | end]]

=rebol-text=: complement =whitespace= charset ";"
=content=: [some =rebol-text=]

=comment=: [";" [ [to "^/"] | [ to end]]]


;-----------------------------------------------------------------------------------------------------------
;
;- MANAGE ARGS
;
;-----------------------------------------------------------------------------------------------------------
args: system/script/args

unless args [
	if args: try [
		rejoin [
			system/script/path
			system/script/header/file
		]
	][
		args: to-local-file args
	]
]

print "========================="
print "test-engine.r arguments:"
probe args
print "========================="

args: to-rebol-file args

either dir? args [
	files: read args
	forall files [
		change files join args first files
	]
][
	files: reduce [ args ]
]


;--------------------------
;- find-word-list()
;--------------------------
find-word-list: func [
	data  [string!]
	words [block!]
	/into blk [block!]
	/local output .word .look-ahead line here
][
	output: any [output copy []]
	line: 1
	
	catch [
		parse/all data [
			SOME [
			  ; (prin ".")
				here: 
				COPY .comment =comment= ;(?? .comment)
				| COPY .word words .look-ahead: =separators= :.look-ahead (
					append output to-word .word 
					append output line
				)
				| =content= 
				| =spaces= 
				| =newline= (line: line + 1  ) ; (prin "/")
				| END (throw)
				| (print "error?" to-error "should not get here")
			]
		]
	]
	
	
	either empty? output [
		output: none
	][
		new-line/skip output true 2
	]
	
	output
]



 ; this is a comment test
 
output: []

foreach file files [
	print[ "scanning ... " file ]
	unless dir? file [
		if list: find-word-list read file words-to-find [
			append output file
			append/only output list
			new-line/skip output true 2
		]
	]
]

probe output

ask "..."

