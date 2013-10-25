rebol  [
	title: "Hammer"
]


;----
; starts the slim library manager, if it's not setup.. the following loading setup allows slim 
; to be installed either within the steel project or just outside of it, to be shared in multiple
; tools.
; 
unless value? 'slim [
	do any [
		all [ exists? %../../slim-libs/slim/slim.r  %../../slim-libs/slim/slim.r ] 
		all [ exists? %../slim-libs/slim/slim.r     %../slim-libs/slim/slim.r    ] 
	]
]

;----
; preload a few common libraries
liquid: liquid-lib: slim/open/expose 'liquid none [!plug liquify processor fill content attach link pipe unlink dirty]

;----
; GLASS libs
gl: slim/open/expose 'glass none [screen-size request-string request-inform discard]
slim/open/expose 'icons none [load-icons]
sl: slim/open/expose 'sillica none [on-event]
ged: slim/open 'group-scrolled-editor none
ed: slim/open 'style-script-editor none
evt: event-lib: slim/open 'event none
win: slim/open 'window none
epoxy: slim/open/expose 'epoxy none [!scale]


; setup icons.
load-icons/size 32
load-icons/size/as 24 'toolbar


slim/vexpose

; setup default verbosity, mainly for debugging
;ed/von
;ged/von
;evt/von
;win/von
;sl/von

von

;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- GLOBALS
;
;-----------------------------------------------------------------------------------------------------------
globals: context [
	;--------------------------
	;-     run-line-hotkey:
	;
	; current line is evaluated
	;--------------------------
	run-line-hotkey: [ 'F5  #[false]  #[false]]

	
	;--------------------------
	;-     run-sel-hotkey:
	;
	; selection will be evaluated
	;--------------------------
	run-sel-hotkey: [ 'F5  #[true]  #[false]]
	
	
	;--------------------------
	;-     run-page-hotkey:
	;
	; current script is evaluated
	;--------------------------
	run-page-hotkey: [ 'F9  #[false] #[false]]
	
	
	;--------------------------
	;-     debug:
	;
	; set this to any value to debug it via console.
	;--------------------------
	debug: none
	
	
	;--------------------------
	;-     verbose?:
	;
	; used by monitor to store the verbose state...
	;--------------------------
	verbose?: none


	;--------------------------
	;-     colors:
	;
	; various colors used by the GUI
	;--------------------------
	pane-title-color: white * .5 ;80.130.230
	pane-title-text-color: white
	pane-bg-color: white * .75 ; white
	
	
	;--------------------------
	;-     quick-save-file:
	;
	;
	;--------------------------
	quick-save-file: %hammer-quick-save.r
	
	
	;--------------------------
	;-     startup-macro-file:
	;
	;
	;--------------------------
	startup-macro-file: %macros/hammer-startup.r
	
	
	
	
	;-                                                                                                         .
	;-----------------------------------------------------------------------------------------------------------
	;
	;- PLUGS
	;
	;-----------------------------------------------------------------------------------------------------------
	
	
	
	
	;--------------------------
	;-     font-size:
	;
	; scaled font size
	;--------------------------
	font-size: liquify/fill !plug 11
	
		
	;--------------------------
	;-     line-leading:
	;
	; scaled line height
	;--------------------------
	line-leading: liquify/fill !plug 1
	
	
	;--------------------------
	;-     char-width:
	;
	; scaled character width
	;--------------------------
	char-width: liquify/fill !plug 6



	;--------------------------
	;-     editor-font:
	;
	; the base font used in editor
	;--------------------------
	editor-font: liquify/link processor '!editor-font [
		plug/liquid: any [
			all [
				number? fsize: pick data 1
				number? fwidth: pick data 2
				make face/font [name: font-fixed size: fsize bold?: true style?: 'bold char-width: fwidth]
			]
			
			; backup
			make face/font [name: "Lucida Console" size: 10 bold?: true char-width: 6]
		]
	] reduce [ 
		font-size
		char-width
	]
	
		
]




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- UTILITY FUNCS
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     monitor()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
monitor: funcl [
	/start 
	/stop
][

	vin "monitor()"
	
	libs: content monitored-libs
	
	libs: any [libs ""]
	libs: attempt [load/all libs]
	
	;vprobe libs
	
	if libs [
		either stop [
			;vprint "STOPING MONITOR"
			;----------
			; stop monitoring libs.
			foreach lib libs [
				;vprint lib
				lib: slim/open lib none
				lib/voff
				vprint "STOPPED"
			]
		][
			;-----------
			; start monitoring libs
			foreach lib libs [
				lib: slim/open lib none
				lib/von
			]
		]
	]
	
	vout
]





;--------------------------
;- report()
;--------------------------
; purpose:  the print replacement for use within hammer
;
; inputs:   anything.
;
; returns:  input
;
; notes:    uses the vprint engine internally, so it will collaborate with vprint.  the advantage is that it forces a refresh of the interactive console output.
;           in your final code (not within hammer) you can simply do a report: :vprint (but not within hammer) to make it work.
;
; tests:    
;--------------------------
report: funcl [
][
	vin "report()"
	
	vout
]




;--------------------------
;-     quick-save()
;--------------------------
; purpose:  just does a quick-save of the current script in the quick save file.
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
quick-save: funcl [
][
	vin "quick-save()"
	text: content main-editor/aspects/text
	write globals/quick-save-file  text
	vout
]



;--------------------------
;-     quick-load()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
quick-load: funcl [
][
	vin "quick-load()"
	if exists? globals/quick-save-file [
		text: read globals/quick-save-file
		replace/all text "^-" "    "
		fill main-editor/aspects/text text
	]
	vout
]




;--------------------------
;- append-con-out()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
append-con-out: funcl [
	console-text [string!]
][
	vin "append-con-out()"
	con-out: console-editor/editor-marble
	
	;--
	; dirty hack to allow tabs
	replace/all console-text "^-" "    "
	
	; split lines
	console-text: parse/all console-text "^/"

	append content con-out/material/lines console-text
	
	;---
	; tell liquid that the lines in the output box have changed
	;fill console-editor/vscroller-marble/aspects/value 1.0
	;vprobe content console-editor/vscroller-marble/aspects/value
	;vprobe content console-editor/vscroller-marble/aspects/minimum
	
	dirty con-out/material/lines
	
	max: content console-editor/vscroller-marble/aspects/maximum
	fill console-editor/vscroller-marble/aspects/value max
	
	vout
]




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- EVENT HANDLERS
;
;-----------------------------------------------------------------------------------------------------------


;--------------------------
;;-     eval-code()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
eval-code: funcl [
	text
][
	vin "eval-code()"
	con-out: console-editor/editor-marble
	v?? text
	quick-save
	
	if error? result: try [
		monitor/start
		
		slim/vconsole: clear []
		vreset ; start tabs at 0
		set/any 'res do text
		if value? 'res [
			;---
			; because of vconsole, this ends up in a block instead of the Rebol console
			vprin "== " 
			either object? :res [
				vprobe rejoin ["OBJECT: " words-of res ]
			][
				vprobe :res
			]
			
			none
		]
	][
		dres: disarm result
		append slim/vconsole rejoin ["=========== ERROR ===========^/" mold/all dres "^/=============================^/"]
	]
	
	
	;------
	; here we xfer the content of the vconsole into our output editor
	console-text: to-string slim/vconsole
	slim/vconsole: none
	monitor/stop 
	
	
	append-con-out console-text
	
;	
;	;--
;	; dirty hack to use tabs
;	replace/all console-text "^-" "    "
;	
;	console-text: parse/all console-text "^/"
;	;probe console-text
;	append content con-out/material/lines console-text
;	
;	; stop using the vconsole for now...
;	
;	;---
;	; tell liquid that the lines in the output box have changed
;	;fill console-editor/vscroller-marble/aspects/value 1.0
;	;vprobe content console-editor/vscroller-marble/aspects/value
;	;vprobe content console-editor/vscroller-marble/aspects/minimum
;	
;	max: content console-editor/vscroller-marble/aspects/maximum
;	
;	fill console-editor/vscroller-marble/aspects/value max
;
;	
;	
;	dirty con-out/material/lines

	vout
]





;--------------------------
;-     handle-hotkeys()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
handle-editor-hotkeys: funcl [
	event [object!]
][
	vin "handle-editor-hotkeys()"
	edtr: event/marble
	switch/default event/key [
		F3 [
			print "search?"
			
			if 1 = length? selections:  content main-editor/aspects/selections [
				lines: content main-editor/material/lines
				cursors: content main-editor/aspects/cursors
				text: main-editor/valve/get-selection next lines cursors selections
				print "NEW SELECTION"
			]
			
			if all [
				not text
				not text: content main-editor/aspects/search-string 
			][
				print "REQUEST SEARCH:"
				gl/unfocus event/marble
				text: gl/request-string "string to search for (single line)"
			]
			
			if text [
				;print lines
				print cursors
				print selections 
				
				print ["WE HAVE TEXT:" text]
				fill main-editor/aspects/search-string text
				;print "============>>>"
				evt/queue-event 
				e: evt/clone-event/with event [
					search-string: text 
					key: none 
					action: 'find-string
				]
				
				;help e
			]
		]
		
		#"^F" [
			;if event/control? [
				text: gl/request-string "string to search for (single line)"
				gl/unfocus event/marble
				
				if text [
					fill main-editor/aspects/search-string text
					;print "============>>>"
					evt/queue-event 
					e: evt/clone-event/with event [
						search-string: text 
						key: none 
						action: 'find-string
					]
					
					;help e
				]
			
			;]
		]
		
		;----
		; erase current line
		#"^E" [
			vprint "DELETE LINE(s)"
			
			cursors:    content edtr/aspects/cursors
			selections: content edtr/aspects/selections
			lines: next content edtr/material/lines ; next is because the lines is a bulk (skip header)
			
			;---
			; get list of lines to remove
			line-list: clear []
			foreach cursor cursors [
				append line-list cursor/y
			]
			
			;---
			; we only want to remove any line once
			line-list:  unique line-list
			
		
			i: 0
			clear cursors
			foreach line line-list [
	;			line: pick next lines cursor/y
				remove at lines line - i
				
				; offsets the line indices, since we already removed items in the lines list
				
				append cursors ( (1x0) + (0x1 * (line - i)))
				i: i + 1
			]
			
			; remove duplicate cursors
			blk: unique cursors
			v?? blk
			append clear cursors blk
				
			clear selections
			dirty edtr/aspects/cursors
			dirty edtr/aspects/selections
			dirty edtr/material/lines
			
			v?? cursors
		]
	][
		handle-eval-hotkeys event
	]
	vout
]



;--------------------------
;-     handle-eval-hotkeys()
;--------------------------
; purpose:  given an event, will trigger evaluation, if the hotkey matches specs.
;
; inputs:   the event object.  all is in there.
;
; returns:  
;
; notes:    we could have used global hotkeys, but then they would trigger even when the editor isn't focused.
;
; tests:    
;--------------------------
handle-eval-hotkeys: funcl [
	event [object!]
][
	vin "handle-eval-hotkeys()"
	;probe words-of event
	vprobe event/key
	
	edtr: event/marble
	key-stroke: compose [ (event/key)  (event/shift?) (event/control?)]
	selections: content edtr/aspects/selections
	
;		vprobe key-stroke
;		vprobe globals/run-line-hotkey
;		vprobe globals/run-sel-hotkey
;		vprobe globals/run-page-hotkey

	mode: any [
		all [
			parse key-stroke globals/run-line-hotkey
			any [
				all [not empty? selections 'eval-selection]
				'eval-line
			]
		]
		all [
			parse key-stroke globals/run-page-hotkey
			'eval-script
		]
	]

	
	switch mode [
		eval-line [
			vprint "EVALUATE LINE"
			
			cursors: content edtr/aspects/cursors
			lines: next content edtr/material/lines
			text: clear ""
			foreach cursor cursors [
				; next is because the lines is a bulk (skip header)
				line: pick lines cursor/y
				append text line "^/"
				append text "^/"
			]
			cursor: last cursors
			clear cursors
			either cursor/y < length? lines [
				append clear  cursors (0x1 * cursor + 1x1 )
				dirty edtr/aspects/cursors
				dirty edtr/aspects/selections
			][
				append cursors cursor
			]
			v?? cursors
		]
		
		
		eval-selection [
			vprint "EVALUATE SELECTION"
			
			cursors: content edtr/aspects/cursors
			lines: next content edtr/material/lines
			v?? lines
			;ask "@@"
			text: edtr/valve/get-selection/with-newlines lines cursors selections
			
			
			
		]
		
		
		eval-script [
			vprint "EVALUATE SCRIPT"
			text: content event/marble/aspects/text
		]
	]
	
	if string? text [
		eval-code text
	]
	vout
]


;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- LIQUID PLUGS
;
;-----------------------------------------------------------------------------------------------------------

	;--------------------------
	;-     monitored-libs:
	;
	; this plug stores which libraries to monitor, it is attached to the setup.
	;--------------------------
	monitored-libs: liquify/fill !plug "liquid"





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PANES
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     show-pane()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
show-pane: funcl [
	pane [object!] "any already laid-out framed marble"
	/side
][
	vin "show-pane()"
	either side [
		gl/collect/top side-frame pane
	][
		gl/surface main-frame pane
	]
	vout
]



	
;----------------------------------------------------
;-     macro-pane:
;
; record and replay events!!!
;----------------------------------------------------
macro-pane: gl/layout/within compose/deep [
    column tight  (globals/pane-title-color) (globals/pane-title-color) 3x3 [
        column (globals/pane-bg-color) (globals/pane-bg-color)  tight [
            row 1x1 (globals/pane-title-color)(globals/pane-title-color) corner 0 [
                tool-icon #close no-label [gl/discard macro-pane/frame macro-pane]
                title "Macro" left stiff 80x-1 (globals/pane-title-text-color)
            ]
            shadow-hseparator
            column  13x10 [
                row tight [
                    button  "record" (red ) (white * .8) stiff [ event-lib/start-recording/only 'key ]
                    button  "stop" stiff  ( black ) (white * .8)   [ event-lib/stop-recording  ]
                ]
                row tight [
                    button  "play" (green * .5) (white * .8) stiff   [ event-lib/playback-recording ]
                    button  "play fast" ( green * .5  ) (white * .8) stiff   [ event-lib/playback-recording/speed 0 ]
                ]
            ]
        ]
   ]
] 'column  





;----------------------------------------------------
;-     setup-pane:
;
; stores any user-setup which we want to persist from session to session.
;----------------------------------------------------
setup-pane: gl/layout/within/tight compose/deep [
    column tight  (globals/pane-title-color) (globals/pane-title-color) 3x3 [
        column (globals/pane-bg-color) (globals/pane-bg-color)  tight [
            row 1x1 (globals/pane-title-color)(globals/pane-title-color) corner 0 [
                tool-icon #close no-label [gl/discard setup-pane/frame setup-pane]
                title "User Preferences" left stiff 80x-1 (globals/pane-title-text-color)
            ]
            shadow-hseparator
            column  13x10 [
				auto-subtitle "Hotkeys"
				row tight [
					label right  "Run LINE"  stiff
					field   (form globals/run-line-hotkey)
				] win
				
				row tight [
					label right "Run Selection"  stiff
					field (form globals/run-sel-hotkey) 
				]
				
				row tight [
					label right  "Run Selection"  stiff
					field (form globals/run-page-hotkey)
				]
				
				
				auto-subtitle  "Live Edit"
				
				row tight [
					label right  "Monitor libraries"  stiff
					field attach-to monitored-libs  ;(content monitored-libs)
				]
		
		        row tight with [spacing-on-collect: 10x0] [
		            label right "Line Spacing" stiff
		            column tight [
		                lscr: scroller stiff 70x20
		            ]
		            dbg-leading-val: label left stiff 30x25
		        ]
			
		        row tight with [spacing-on-collect: 10x0] [
		            label right "Font size" stiff
		            column tight [
		                fs-scr: scroller stiff 70x20
		            ]
		            dbg-fs-val: label left stiff 30x25
		        ]
			
		        row tight with [spacing-on-collect: 10x0] [
		            label right "Character Width" stiff
		            column tight [
		               cw-scr: scroller stiff 70x20
		            ]
		            dbg-cw-val: label left stiff 30x25
		        ]
			]	
		]
		;elastic
		
	]

] 'column 





;----------------------------------------------------
;-     main-pane:
;
;
;----------------------------------------------------
main-pane: 	gl/layout/within/options compose/deep [
   ; column  [
		row 0x0 [
	        column (globals/pane-title-color) (globals/pane-title-color)  tight 3x3 [
	            row 1x1 corner 0 [
	                ;tool-icon #close no-label [gl/discard macro-gui/frame macro-gui]
	                title "Edit box" left stiff  (globals/pane-title-text-color)
	                				; quick launch for now
					;column [
					;vstretch stiff 2x10
					hstretch
					column  (white * .6) (white * .4) 1x1 [
						choice stiff [
							"step 1) Basics" %step-1-basics.r [] 
							"step 2) Memory" %step-2-memory.r []
							"step 3) A DSL Anyone?" %step-3-dsl.r []
							"step 4) Networking the Flow" %step-4-liquid-net.r []
							"step 5) Liquid Graph-ics" %step-5-gfx.r []
							"step 6) Painting it all together" %step-6-multipaint.r []
						] 200x23 [
							help event
							probe event/picked-data
							either exists? file: event/picked-data/2 [
								fill main-editor/aspects/text read file
							][
								;epoxy/von
								gl/request-inform/message "Invalid File:" mold file
							]
						]
						marble stiff 0x2
					]
					;vstretch
					;]

	            ]
	            ;shadow-hseparator
				ed-grp: scrolled-editor  [ handle-editor-hotkeys event]
			]
	        column (globals/pane-title-color) (globals/pane-title-color)  tight 3x3 [
	            row 1x1 (globals/pane-title-color)(globals/pane-title-color) corner 0 [
	                ;tool-icon #close no-label [gl/discard macro-gui/frame macro-gui]
	                title "Console output" left stiff  (globals/pane-title-text-color)
	            ]
	          	; shadow-hseparator
				console-editor: scrolled-editor
			]
		]
	;]
] 'column  [ tight ]

; since the editor is persistent, there are no problems in exposing it globally
main-editor: ed-grp/editor-marble
link/reset main-editor/aspects/font globals/editor-font
link/reset main-editor/aspects/leading globals/line-leading

link/reset console-editor/editor-marble/aspects/font globals/editor-font
link/reset console-editor/editor-marble/aspects/leading globals/line-leading

;----------------------------------------------
;
;   Add a contextual mouse press handler to our editor...
;
;----------------------------------------------
on-event main-editor 'CONTEXT-PRESS [

	print "test"

	edtr: event/marble
	selections: content edtr/aspects/selections
	lines: next content edtr/material/lines
	either empty? selections [
	
		cursor: edtr/valve/cursor-from-offset edtr event/offset
		
		v?? cursor
		
		text: clear ""
		; next is because the lines is a bulk (skip header)
		line: pick lines cursor/y
		append text line "^/"
		append text "^/"
	][
		cursors: content edtr/aspects/cursors
		text: edtr/valve/get-selection/with-newlines lines cursors selections
	]
	eval-code text
]








;----------------------------------------------------
;-     debug-pane:
;
; allows us to view and manipulate some aspects of the editor live.
;----------------------------------------------------
debug-pane: gl/layout/within compose/deep [
    column tight  (globals/pane-title-color) (globals/pane-title-color) 3x3 [
        column (globals/pane-bg-color) (globals/pane-bg-color)  tight [
            row 1x1 (globals/pane-title-color)(globals/pane-title-color) corner 0 [
                tool-icon #close no-label [gl/discard debug-pane/frame debug-pane]
                title "Debug" left stiff 80x-1 (globals/pane-title-text-color)
            ]
            
            shadow-hseparator
 
            pad 10x10
            row tight with [spacing-on-collect: 10x0] [
                label right "dimension" stiff
                dbg-dimension: label left  stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "view-width" stiff
                dbg-view-width: label left stiff 
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "font-width" stiff
                dbg-font-width: label left  stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "visible-length" stiff
                dbg-visible-length: label left stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "left offset" stiff
                dbg-left-off: label left stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "top line" stiff
                dbg-top-line: label left stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "lines" stiff
                dbg-lines: label left stiff
            ]
            row tight with [spacing-on-collect: 10x0] [
                label right "visible lines" stiff
                dbg-visible-lines: label left stiff
            ]
        ]
    ]
] 'column



;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- LINK UP THE PANES
;
;-----------------------------------------------------------------------------------------------------------


mtrl: main-editor/material
spct: main-editor/aspects


;--------------------------------
; link-up the font leading scrollbar
;--------------------------------
;link/reset spct/leading lscr/aspects/value
fill lscr/aspects/minimum -2
fill lscr/aspects/maximum 20
fill lscr/aspects/value 0
link/reset dbg-leading-val/aspects/label        lscr/aspects/value


;--------------------------------
; link-up font size
;--------------------------------
link/reset globals/font-size fs-scr/aspects/value
fill fs-scr/aspects/minimum 5
fill fs-scr/aspects/maximum 30
fill fs-scr/aspects/value 11
link/reset dbg-fs-val/aspects/label  fs-scr/aspects/value


;--------------------------------
; link-up font-width
;--------------------------------
link/reset globals/char-width cw-scr/aspects/value
fill cw-scr/aspects/minimum 2
fill cw-scr/aspects/maximum 20
fill cw-scr/aspects/value 7
link/reset dbg-cw-val/aspects/label cw-scr/aspects/value


;--------------------------------
; link-up some debugging...
;--------------------------------
link/reset dbg-dimension/aspects/label          mtrl/dimension
link/reset dbg-view-width/aspects/label         mtrl/view-width
link/reset dbg-font-width/aspects/label         mtrl/font-width
link/reset dbg-visible-length/aspects/label     mtrl/visible-length
link/reset dbg-left-off/aspects/label           spct/left-off
link/reset dbg-lines/aspects/label              mtrl/number-of-lines
link/reset dbg-visible-lines/aspects/label      mtrl/visible-lines
link/reset dbg-top-line/aspects/label           spct/top-off
;link/reset dbg-cursor/aspects/label             mtrl/hover-cursor




mtrl: none
spct: none
lscr: none




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- MAIN GUI
;
;-----------------------------------------------------------------------------------------------------------

main-gui: gl/layout/size compose/deep [
	tool-row tight [
		;-    -toolbox
		row tight 5x5 [
			icon stiff 60x60 #page "New" [
				vprint "New project?"
				fill main-editor/aspects/text copy ""
			]
			
			icon stiff 60x60 #folder  "Open" [
				vprint "Select Spec"
				attempt [
					path: request-file/keep/only/filter "*.r"
					if exists? path [
						text: read path
						replace/all text "^-" "    "
						content 
						fill main-editor/aspects/text text
					]
				]
			]
			
			icon stiff 60x60 #page-save "Save" [
				path: request-file/keep/only/filter/save "*.r"
				write path content main-editor/aspects/text
			]
			
			hstretch

			icon stiff 60x60 #gear "Setup" [
				show-pane/side setup-pane
			]
			
			icon stiff 60x60 #refresh "Macro" [
				show-pane/side macro-pane
			]
			
			icon stiff 60x60 #alert "Debug" [
				show-pane/side debug-pane
			]
			
			icon stiff 60x60 #help  [ request-inform/message "Help" "You Wish!!!" ]
		]
	]
	shadow-hseparator
	row tight [
		;-    -main frame
		main-frame: column [
		
		]
		side-frame: column tight [
		]
	]

] 1000x800

show-pane main-pane


print "================================================================"
vprobe content main-editor/material/lines
vprobe content main-editor/aspects/text
fill main-editor/aspects/text "; welcome to ReCode"
main-editor

print "."


;- DO-EVENTS

quick-load

if all [
	file? globals/startup-macro-file 
	exists? globals/startup-macro-file 
][
	do read globals/startup-macro-file
]

do-events

quick-save
