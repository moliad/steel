rebol [
	title: "Revelator - Advanced search tool"
	version: 0.0.1
]



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

;probe "--"


steel-root-path: clean-path %../../

;----
; start the slim library manager, if it's not setup in your user.r file
;
; the following loading setup allows us to get slim and various packages in a variety of places easily 
; and with no discreet setup.
;
; they can be:
;   - Installed within the steel project 
;   - Installed at the same level as steel itself
;   - Installed anywhere else, in this case just create a file called slim-path-setup.r within 
;     the root of the steel project and fill it with a single Rebol formatted path which points to 
;     the location of your slim.r script.
;
; if you have GIT installed, you can use the get-git-slim-libs.r script to retrieve the latest versions
; of the various slim library packages used by steel, in one go.
;
; if you go to github.com, you can get slim and all libs without GIT using a manual download link 
; for each slim package which gives you a .zip of all the files its repository contains. 
;----
unless value? 'slim [
	do any [
		all [ exists? steel-root-path/slim-path-setup.r         do  	steel-root-path/slim-path-setup.r ]
		all [ exists? steel-root-path/../slim-libs/slim/slim.r          steel-root-path/../slim-libs/slim/slim.r ] 
		all [ exists? steel-root-path/slim-libs/slim/slim.r             steel-root-path/slim-libs/slim/slim.r    ] 
		all [ exists? slim-libs/slim/slim.r             				slim-libs/slim/slim.r    ] 
	]
]
;slim/von

; this is a special overide which must be define BEFORE loading sillica.
; it must be global
glass-font-overide: make face/font [name: "Segoe UI" size: 14 style: none bold?: false]


sl: slim/open/expose 'sillica none [base-font]

gl: slim/open/expose 'glass none [screen-size request-string request-inform discard]
slim/open/expose 'icons none [load-icons]
event-lib: slim/open 'event none


bulk-lib:   slim/open/expose 'bulk         none [ make-bulk   clear-bulk  bulk-rows ]
liquid-lib: slim/open/expose 'liquid       none [ fill   liquify   content  dirty  !plug   link   unlink   processor  detach  attach  insubordinate]


cfg-lib: slim/open/expose 'configurator none [ configure ]

slim/open/expose 'utils-files none [ directory-of  filename-of ]

; setup glass icons
load-icons/size 32
load-icons/size/as 16 'toolbar


slim/vexpose


;---
; setup individual library module verbosity while debugging
;---
;ed/von
;ged/von
;evt/von
;win/von
;sl/von

;von



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUG-MODELS
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     !notified-container:
;
; a special container type which sends message when some linked data is
; changed, but still only manages the data with which you fill it.
;--------------------------
!notified-container: processor 'NOTIFIED-CONTAINER [
	plug/liquid: pick data 1
]

!notified-container/resolve-links?: 'LINK-AFTER



;--------------------------
;-     !setups-to-listview:
;
; takes a list of search setups 
;--------------------------
!setups-to-listview: processor 'SETUPS-TO-LISTVIEW [
	vin "setups-to-listview/process()"
	;---
	; reuse or create a block.
	outblk: any [
		all [block? plug/liquid  plug/liquid]
		plug/liquid: make-bulk 3
	]
	
	clear-bulk outblk
	
	;setups: data ;pick data 1
	setups: pick data 1
	
	vprobe type? setups
	
	if block? setups [
		vprint length? setups
		vprobe "there is a setup list"
		foreach setup setups [
			vprint "one setup to add"
			vprint type? setup
			
			label: get in setup 'name
			if label [
				label: content label
				unless string? label [
					label: to-string label
				]
			]
			v?? label
			
			append outblk any [
				label
				" --- unknown setup ---"
			]
			append/only outblk [] ; the same block in each list item, they aren't used.
			append/only outblk setup
		]
	]
	vout
]


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- CLASSES
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;-     !search-setup[]
;
; base setup reference class.
;--------------------------
!search-setup: context [

	;--------------------------
	;-         self-plug:
	;
	; this is a plug which is filled with the object's "self".
	;
	; thus object == content object/self-plug
	;--------------------------
	self-plug: none  


	;--------------------------
	;-         name:
	;
	; name (label) of the search setup.
	;--------------------------
	name: "unnamed"
	
	
	;--------------------------
	;-         dirs:
	;
	; one or more directories to search
	;--------------------------
	dirs: []
	
	
	;--------------------------
	;-         files:
	;
	; spec is a list of files, once loaded is a bulk plug of those files, for use in a lister
	;
	; which file extensions to ignore.
	;--------------------------
	files: []
	
	
	;--------------------------
	;-         exclude-dirs:
	;
	; spec is a list of files, once loaded is a bulk plug of those files, for use in a lister
	;
	; folders to ignore:
	;    -absolute paths match only that specific path
	;    -relative paths, match that path in any subpath
	;--------------------------
	exclude-dirs: []
	
	
	;--------------------------
	;-         exclude-files:
	;
	; spec is a list of files, once loaded is a bulk plug of those files, for use in a lister
	;
	;  exact file names to match
	;--------------------------
	exclude-files: []

]



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- GLOBALS
;
;-----------------------------------------------------------------------------------------------------------
globals: context [
	;--------------------------
	;-     colors:
	;
	; various colors used by the GUI
	;--------------------------
	pane-title-color: white * .5 ;80.130.230
	pane-title-text-color: white
	pane-bg-color: white * .75 ; white
	
	;--------------------------
	;-     config:
	;
	; this is the main configuration storage
	;
	; use load-data to completly update the in-memory data from the saved config.
	;--------------------------
	config: configure compose/only [
		search-setups: [] "List of previously configured search setups."
		
		last-browsed-dir: (what-dir) "The last path we browsed within a file requestor."
		
		last-search: "" "The last thing we searched."
		
		last-ignored: "" "Ignore list used in last session."
		
		last-search-setup: #[none] "what is the name of the last search setup used."
		
		editor-path: "C:\Program Files\IDM Computer Solutions\UltraEdit\uedit64.exe" "Path to the application used when opening files for edit. Is in system (OS) format."
	]
	;config
	
	
	;--------------------------
	;-     last-browsed-dir:
	;
	; whenever we browse a file, we store the path returned, so we can use it on the next browse.
	;
	; we save out the path in the config, so it is restored when we start over.
	;--------------------------
	;last-browsed-dir: none
	
	
	;--------------------------
	;-         show-paths?:
	;
	; do we show paths in console when scanning files...
	;--------------------------
	show-paths?: false
	
	
	;--------------------------
	;-         search-result-list:
	;
	; stores
	;--------------------------
	search-result-list: none
	
	
	;config/from-disk/using  %app.cfg ; will set cfg/store-path if nothing has been saved yet.

	
	;-                                                                                                         .
	;-----------------------------------------------------------------------------------------------------------
	;
	;-    GLOBAL PLUGS
	;
	;-----------------------------------------------------------------------------------------------------------
	
	;--------------------------
	;-         setups-collection:
	;
	; the current collection of setups. 
	;
	; each setup we want to put in the list, is simply linked to this plug 
	; via its self-plug member.  
	; 
	; any change to this list or one of its search-setups will update all subsystems .
	;--------------------------
	setups-collection: liquify processor '!setups [
		plug/liquid: copy data
	]
	
	
	
	;--------------------------
	;-         setups-list:
	;
	; contains the listview compatible list of search-setups
	;
	; the self-plug receives messages from name changes it receives, updating the list.
	;--------------------------
	setups-list: liquify/link !setups-to-listview setups-collection



	;--------------------------
	;-     result-list-plug:
	;
	;--------------------------
	result-list-plug: none
	

	
	
	;--------------------------
	;-         results-title:
	;
	; stores the title of the results pane (includes current number of results)
	;--------------------------
	results-title: liquify processor '!count-results [
		blk: pick data 1
		
		plug/liquid: rejoin [
			"Search results ("
			mold any [
				if block? blk [
					bulk-rows blk
				]
				0
			]
			")"
		]
	]
	
	
	

]





;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- APP SUPPORT FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------



;--------------------------
;-     yap()
;--------------------------
; purpose:  enables verbosity and debug for app dev
;--------------------------
yap: funcl [
][
	von
	vin "yap()"

	vout
]


;--------------------------
;-     shut-up()
;--------------------------
; purpose:  stops all verbosity and debug 
;--------------------------
shut-up: funcl [
][
	vin "shut-up()"
	vout
	voff
]


;--------------------------
;-     toggle-debug()
;--------------------------
; purpose:  toggles dev debug mode.
;--------------------------
toggle-debug: funcl [
][
	vin "toggle-debug()"
	either slim/verbose [
		shut-up
	][
		yap
	]
	vout
	vreset
]



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- SETUP MANAGEMENT
;
;-----------------------------------------------------------------------------------------------------------


;--------------------------
;-     make-setup()
;--------------------------
; purpose:  build a !search-setup with all values as their proper (empty) liquid datatypes
;
; inputs:   none
;
; returns:  a !search-setup instance usable in other search-setup management funcs
;
; notes:    Lists are set as empty bulks
;
;           If spec is given, its list data is only a list of data, not in bulk mode.
;           The label is rebuilt on the fly.
;--------------------------
make-setup: funcl [
	/with spec [block! none!]
][
	vin "make-setup()"

	setup: make !search-setup any [
		spec
		[]
	]
	
	spec: make setup []
	
	setup/name:					liquify/fill !plug spec/name
	
	setup/dirs:  				liquify/fill !plug make-bulk 3
	setup/files:				liquify/fill !plug make-bulk 3
	setup/exclude-dirs:			liquify/fill !plug make-bulk 3
	setup/exclude-files:		liquify/fill !plug make-bulk 3

	setup/self-plug: liquify/fill !notified-container setup
	link setup/self-plug setup/name

	unless empty? spec/dirs [
		blk: content setup/dirs
		foreach item spec/dirs [
			append blk reduce [to-local-file item [] item]
		]
		dirty setup/dirs
	]

	unless empty? spec/files [
		blk: content setup/files
		foreach item spec/files [
			append blk reduce [item [] item]
		]
		dirty setup/files
	]
	
	unless empty? spec/exclude-dirs [
		blk: content setup/exclude-dirs
		foreach item spec/exclude-dirs [
			append blk reduce [to-local-file item [] item]
		]
		dirty setup/exclude-dirs
	]

	unless empty? spec/exclude-files [
		blk: content setup/exclude-files
		foreach item spec/exclude-files [
			append blk reduce [item [] item]
		]
		dirty setup/exclude-files
	]


	vout
	setup
]




;--------------------------
;-     setup-to-spec()
;--------------------------
; purpose:  given a working spec object
;
; inputs:   spec object
;
; returns:  the spec in block form
;--------------------------
setup-to-spec: funcl [
	setup [object!]
][
	vin "setup-to-spec()"
	vprobe content setup/name
	
	spec: copy []
	
	dirs: content setup/dirs
	dirs: extract (at dirs 4) 3
	files: content setup/files
	files: extract (at files 4) 3
	exdirs: content setup/exclude-dirs
	exdirs: extract (at exdirs 4) 3
	exfiles: content setup/exclude-files
	exfiles: extract (at exfiles 4) 3
	append spec compose/only [
		name:  (copy content setup/name )
		dirs: (copy/deep dirs)
		files: (copy/deep files)
		exclude-dirs: (copy/deep exdirs)
		exclude-files: (copy/deep exfiles)
	]
	vout
	spec
]




;--------------------------
;-     add-setup()
;--------------------------
; purpose:  adds a brand new search setup in the search setup list
;
; inputs:   you can give a setup spec to create the setup from.
;--------------------------
add-setup: funcl [
	/with setup [block!]
][
	vin "add-setup()"
	setup: make-setup/with setup ; if setup is not given, it's none, and make-setup ignores it.
	
	link globals/setups-collection setup/self-plug
	vout
]


;--------------------------
;-     clone-setup()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
clone-setup: funcl [
	setup [object!]
][
	vin "clone-setup()"
	add-setup/with setup-to-spec setup
	vout
]



;--------------------------
;-     delete-setup()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
delete-setup: funcl [
][
	vin "delete-setup()"
	insubordinate search-setup-pane/current-search/self-plug
	search-setup-pane/hide-setup
	vout
]


;--------------------------
;-     setups-to-specs()
;--------------------------
; purpose:  takes the current setup list and builds a moldable block version of it
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
setups-to-specs: funcl [
][
	vin "setups-to-specs()"

	specs: copy []
	
	setups: content globals/setups-list
	
	;vdump/ignore setups [ valve subordinates observers mud]
	
	setups: extract (at setups 4) 3
	vprint "========================================="
	
	foreach setup setups [
		vprobe type? setup
		vprobe content setup/name
		
		spec: copy []
		
		;append/only specs content setup/name
		append/only specs setup-to-spec setup
	]

	vdump specs

	vout
	
	specs
]



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- GUI FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------
;--------------------------
;-     add-path-to-listplug()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
add-path-to-listplug: funcl [
	plug [object!]
	path [file!]
][
	vin "add-path-to-listplug()"
	list: content plug
	vprobe list
	append list reduce [ to-local-file clean-path path  []  path ]
	vprobe list
	dirty plug

	vout
]



;--------------------------
;-     add-items-to-listplug()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
add-items-to-listplug: funcl [
	plug [object!] "WE ASSUME the content is a listview data bulk"
	string [string!]
][
	vin "add-items-to-listplug()"
	
	;--
	; separate the string list into multiple parts.
	items: parse/all string ";"
	v?? items
	blk: content plug
	
	foreach item items [
		vprobe item
		unless empty? item [
			append blk reduce [ item [] item ]
		]
	]
	
	dirty plug
	vout
]

;--------------------------
;-     ask-dir()
;--------------------------
; purpose:  request a path (using system browser)
;
; returns:  a file! or none
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
ask-dir: funcl [
	title [string!]
	/file "append file name at the end. cannot multi-select"
][
	vin "ask-dir()"
	vprobe path
	init-path: globals/config/get 'last-browsed-dir
	
	v?? init-path
	
	init-path: either file? init-path  [
		to-file rejoin [ init-path "[choose folder]"]
	][
		%"[choose folder]"
	]
	
	path: all [
		path-req: request-file/path/save/title/file title "pick" init-path 
		file? pick path-req 1
		pick path-req 1
	]
	
	v?? path-req
	if all [
		file 
		path
	][
		append path pick path-req 2
	]
	
	
	if path [
		globals/config/set 'last-browsed-dir path
	]
	
	vout
	path
]





;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- GUI PANES
;
;-----------------------------------------------------------------------------------------------------------
;--------------------------
;-     SEARCH-SETUP-PANE:
;
;  an object which groups the search panes various actions and data
;--------------------------
Search-Setup-Pane: context [

	;---------------------------
	;-         marble reference names
	fld-name: none
	lbl-name: none
	lst-search-dirs: none
	lst-search-files: none
	lst-exclude-dirs: none
	lst-exclude-files: none
	
	
	;--------------------------
	;-         current-search:
	;
	; if a search setup has been shown, put it here, so we can later hide it.
	;--------------------------
	current-search: none
	


	;--------------------------
	;-         add-search-file()
	;--------------------------
	; purpose:  adds a search file to the current search setup
	;--------------------------
	add-search-file: funcl [
	][
		vin "add-search-file()"
		if file: gl/request-string "  File name or spec to include in search   ^/^/  separate by ; to add multiple items." [
			v?? file
			file-plugs: current-search/files
			list: content file-plugs
			;vprobe list
			append list reduce [ file  []  file ]
			;vprobe list
			dirty file-plugs
		]
		vout
	]
	
	
	;--------------------------
	;-         add-exclude-file()
	;--------------------------
	; purpose:  adds a search file to the current search setup
	;--------------------------
	add-exclude-file: funcl [
	][
		vin "add-exclude-file()"
		if file: gl/request-string "  File name or spec to include in search   ^/^/  separate by ; to add multiple items." [
			v?? file
			file-plugs: current-search/exclude-files
			list: content file-plugs
			;vprobe list
			append list reduce [ file  []  file ]
			;vprobe list
			dirty file-plugs
		]
		vout
	]
	
	
	
	
	
	;--------------------------
	;-         show-pane()
	;--------------------------
	; purpose:  display the search pane in the main UI toolpane
	;--------------------------
	show-pane: funcl [
	][
		vin "show-pane()"
		
		gl/surface setup-frame gui
		
		vout
	]
	
	
	;--------------------------
	;-         find-setup()
	;--------------------------
	; purpose:  given a text label, find a setup.
	;
	; returns:  a setup object, or none, when the given setup is not found
	;--------------------------
	find-setup: funcl [
		name [string!]
	][
		vin "find-setup()"
		setups: content globals/setups-list
		stp: none
		
		setups: extract (at setups 4) 3
		
		foreach setup setups [
			if (content setup/name) = name [
				stp: setup
				break
			]
		]
		
		vout
		
		stp
	]
	
	
	
	;--------------------------
	;-         display-setup()
	;--------------------------
	; purpose:  take a search setup and display it in the pane.
	;
	; input:    if the setup is a string, we pick it from the current setups
	;--------------------------
	display-setup: funcl [
		setup [object! string!]
		/extern current-search
	][
		vin "display-setup()"

		;---
		; something external to the search pane wants to show a setup, 
		if string? setup [
			unless setup: find-setup setup [
				;---
				; return with no value
				exit
			]
			
			;---
			; we must also pick it in the listview
			lst-search-setups/list-marble/valve/pick-string  lst-search-setups/list-marble  content setup/name
		]
		vprobe content setup/name
		
		;----
		; first hide any currently shown search setup 
		hide-setup
		
		;show-pane
		
		current-search: setup
		
		;attach/preserve setup/name fld-name/aspects/label
		link/reset  lbl-name/aspects/label setup/name
		
		link/reset lst-search-dirs/aspects/items current-search/dirs
		link/reset lst-search-files/aspects/items current-search/files
		link/reset lst-exclude-dirs/aspects/items current-search/exclude-dirs
		link/reset lst-exclude-files/aspects/items current-search/exclude-files
		
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
;		event-lib/von
;		gl/von
		gl/unfocus 'all
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
;		vprint "---------------------------------------"
		
		vout
	]



	;--------------------------
	;-         rename-setup()
	;--------------------------
	; purpose:  opens a requester to rename the current setup
	;--------------------------
	rename-setup: funcl [
	][
		vin "rename-setup()"

		if name: gl/request-string "New Search Setup Name" [
			; we must change the string of the current search "in-place" cause the list picker
			; expects the same string as
			text: content current-search/name
			append clear text name
			dirty current-search/name
		]
	
		vout
	]

	
	;--------------------------
	;-         hide-setup()
	;--------------------------
	; purpose:  remove/unlink the current-search from the gui
	;--------------------------
	hide-setup: funcl [
		/extern current-search
	][
		vin "hide-setup()"
		either current-search [
			
			v?? data
			;detach/only current-search/name
			unlink lbl-name/aspects/label
			
			data: content current-search/name
			v?? data
			
			unlink lst-search-dirs/aspects/items
			unlink lst-search-files/aspects/items
			unlink lst-exclude-dirs/aspects/items
			unlink lst-exclude-files/aspects/items

			clear-lists

			;gl/discard setup-frame 'all
		
;			vprint "--- testing data integrity ---" 
;			vprobe content current-search/name
;			vprobe content current-search/dirs
;			vprobe content current-search/files
		][
			vprint "NO CURRENT SEARCH"
		]
		
		current-search: none
		
		vout
	]
	
	
	
	
	
	;--------------------------
	;-         clear-lists()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	clear-lists: funcl [
	][
		vin "clear-lists()"
		lst-search-dirs/list-marble/valve/choose-item   lst-search-dirs/list-marble none
		lst-search-files/list-marble/valve/choose-item  lst-search-files/list-marble none
		lst-exclude-dirs/list-marble/valve/choose-item  lst-exclude-dirs/list-marble none
		lst-exclude-files/list-marble/valve/choose-item lst-exclude-files/list-marble none
		vout
	]
	



	;--------------------------
	;-         --  GUI --
	;--------------------------
	gui: gl/layout/within compose/deep [
		row (globals/pane-title-color) 1x1 [
		setup-edit-sframe: scroll-frame 375x-1 [
			setup-frame: column [
		;hcavity tight (globals/pane-title-color) 10x10 [
		
;			title right "Search Setup:"
			;lbl-name: title left "none"
			;column tight [
				row tight 0x20 [
					lbl-name: label "none" left with [fill aspects/font make content aspects/font [size: 19 bold?: true] ] ; (globals/pane-title-text-color) 
					tiny-button 50x-1 "Rename" stiff [
						rename-setup current-search
					]
				]
			;	shadow-hseparator
			;]			
;			tool-icon #gear-dark no-label stiff [
;				vprint "rename"
;			]
		;]
;		row [
;			auto-label  "Name" stiff
;			fld-name: field
;		]

		;------
		; dirs
		column tight  (globals/pane-title-color) (globals/pane-title-color) 2x2 [
			row tight [
				auto-label "Folders to search" (white) left with [fill aspects/font make content aspects/font [size: 19 bold?: true] ] ; (globals/pane-title-text-color) 
				hstretch
				tool-icon #folder no-label stiff [	
					vprint "add path"
					;add-search-path
					all [
						path: ask-dir "choose path to search"
						v?? path
						add-path-to-listplug current-search/dirs path
					]
				]
				tool-icon #delete no-label stiff [
					lst-search-dirs/list-marble/valve/delete-chosen lst-search-dirs/list-marble
				]
			]
			column tight [
				lst-search-dirs: scrolled-list 100x150 no-label stiff-x  on-click  [
					vprint "COCO"
				]
			]
		]


		;------
		; Files
		column tight  (globals/pane-title-color) (globals/pane-title-color) 2x2 [
			row tight [
				auto-label "Files to search" (white) left with [fill aspects/font make content aspects/font [size: 19 bold?: true] ] ; (globals/pane-title-text-color) 
				filler-x
				tool-icon #add no-label stiff [
					vprint "add file"
					if str: gl/request-string "  File name or spec to include in search   ^/^/  separate by ; to add multiple items." [ 
						add-items-to-listplug current-search/files str
					]
				]
				tool-icon #delete no-label stiff [
					lst-search-files/list-marble/valve/delete-chosen lst-search-files/list-marble
				]
			]				
			column tight [
				lst-search-files: scrolled-list 100x150 no-label stiff-x  on-click  [
					vprint "COCO"
				]
			]
		]


		;------
		; Exclude dir
		column tight  (globals/pane-title-color)  (globals/pane-title-color)2x2 [
			row tight   [
				auto-label "Folders to exclude" (white) left with [fill aspects/font make content aspects/font [size: 19 bold?: true] ] ; (globals/pane-title-text-color) 
				filler-x
				tool-icon #folder no-label stiff  [
					vprint "add path"
					all [
						path: ask-dir "choose path to exclude from search"
						;v?? path
						add-path-to-listplug current-search/exclude-dirs path
					]
				]
				tool-icon #add no-label stiff [
					vprint "exclude folder"
					if str: gl/request-string "Path snippet to exclude from search   ^/^/  separate by ; to add multiple items." [ 
						add-items-to-listplug current-search/exclude-dirs str
					]
				]
				tool-icon #delete no-label stiff [
					lst-exclude-dirs/list-marble/valve/delete-chosen lst-exclude-dirs/list-marble
				]
			]

			column tight [
				lst-exclude-dirs: scrolled-list 100x150 no-label stiff-x  on-click  [
					
				]
			]
		]


		;------
		; Exclude Files
		column tight  (globals/pane-title-color) (globals/pane-title-color) 1x1 [
			row tight [
				auto-label "Files to exclude" (white) left with [fill aspects/font make content aspects/font [size: 19 bold?: true] ] ; (globals/pane-title-text-color) 
				filler-x
				tool-icon #folder no-label stiff [
					vprint "add path"
					;add-search-path
					all [
						path: ask-dir/file "Choose file to exclude from search" 
						;v?? path
						add-items-to-listplug current-search/exclude-files to-local-file path
					]
				]
				tool-icon #add no-label stiff [
					vprint "exclude file"
					if str: gl/request-string "  File name or spec to exclude from search   ^/^/  separate by ; to add multiple items." [ 
						add-items-to-listplug current-search/exclude-files str
					]
				]
				tool-icon #delete no-label stiff [
					lst-exclude-files/list-marble/valve/delete-chosen lst-exclude-files/list-marble
				]
			]
			
			column tight [
				lst-exclude-files: scrolled-list 100x150 no-label stiff-x  on-click  [
					vprint "COCO"
				]
			]
		]


			]
		] ]
	] 'column
	


	
]








;-                                                                                                       .
;--------------------------
;-     SEARCH-PANE:
;
; the actual search pane setup and launch
;--------------------------
Search-Pane: context [
	;--------------------------
	;-         can-cancel?:
	;
	; when this is true, the search button is in cancel mode.
	;--------------------------
	can-cancel?: none
	
	;--------------------------
	;-         cancel?:
	;
	; is true once we hit the cancel button
	;--------------------------
	cancel?: none
	
	;--------------------------
	;-         search-button:
	;--------------------------
	search-button: none
	
	;--------------------------
	;-         refresh-interval:
	;
	; how many files to add before updating the result list.
	;--------------------------
	refresh-interval: 10
	
	;--------------------------
	;-         max-results:
	;
	; the search ends when this number of files is accumulated
	;--------------------------
	max-results: 30
	
    ;--------------------------
    ;-         tgl-any-srch:
    ;
    ; stores the gui's toggle button
    ;--------------------------
    tgl-any-srch: none
    
    ;--------------------------
    ;-         tgl-comments:
    ;
    ; stores the gui's toggle button
    ;--------------------------
    tgl-comments: none
    
    
    
	
	;-------------------
	;-         is-dir?()
	;-----
	is-dir?: funcl [path [string! file!]][
		path: to-string path
		replace/all path "\" "/"
		
		all [
			path: find/last/tail path "/"
			tail? path
		]
	]

	
	;--------------------------
	;-         reset-search-button()
	;--------------------------
	; purpose:  resets the search button text and color
	;--------------------------
	reset-search-button: funcl [
	][
		vin "reset-search-button()"
		
		fill search-button/aspects/label "Search"
		fill search-button/aspects/color 229.229.229
		fill search-button/aspects/label-color black
		
		vout
	]
	
	;--------------------------
	;-         reset-search-list()
	;--------------------------
	; purpose:  empties the search result list
	;--------------------------
	reset-search-list: funcl [
	][
		vin "reset-search-list()"
		clear next globals/search-result-list
		;fill  lst-search-results/list-marble/list
		dirty lst-search-results/list-marble/aspects/list
		vout
	]
	
	
	;--------------------------
	;-         reset-search()
	;--------------------------
	; purpose:  resets all aspects of the search 
	;--------------------------
	reset-search: funcl [
	][
		vin "reset-search()"
		reset-search-button
		reset-search-list
		vout
	]
	
	
	=whitespace=: charset [#"^(A0)" #"^(8D)"   #"^(8F)"   #"^(90)"  "^- "]
	
	;--------------------------
	;-         add-result()
	;--------------------------
	; purpose:  adds a file to the result list
	;en it doesn't pass the filter.
	;
	; notes:    file is not added wh
	; inputs:   file! path
	;--------------------------
	add-result: funcl [
		path [file!]
	][
		vin "add-result()"
		
		if globals/show-paths? [
			?? path
		]
			
		add?: true
		
		;probe words-of tgl-comments/aspects
		
		ignore-comments?:  not content search-pane/tgl-comments/aspects/engaged?
		search-any?:           content search-pane/tgl-any-srch/aspects/engaged?
		
		;?? ignore-comments?
		
		either ignore-comments? [
			;---
			; a commented line...
			ign-cmts-rule: [
				"^/" any =whitespace= ";" [[to "^/" ] | [to end]] (
					current-line: current-line + 1
					;wait 0
				)
			]
		][
			ign-cmts-rule: [end skip]
		]
		
		
		
		ignore-texts: clear []

		;-----------
		; a listing of all text strings to find
		;-----------
		;?? search-any?
		either search-any? [
			search-texts: copy next content edtr-search-text/editor-marble/material/lines
			;?? search-texts
			
			foreach text search-texts [
				if #"~" = pick text 1 [
					append ignore-texts '|
					append ignore-texts copy next text ; skip the ~ character
				]
			]
			remove ignore-texts ; remove the first '| 
			
			remove-each text search-texts [
				any [
					empty? text
					#"~" = first text 
				]
			]
			
		][
			;---
			; check if the file contains search term
			;search-text: content edtr-search-text/aspects/text
			;v?? search-text
			search-texts: reduce [ content edtr-search-text/aspects/text ]
		]
		
		if empty? ignore-texts [
			ignore-texts: [end skip]
		]
		
		if text: attempt [ read path ] [
			;(current-line: 1)
			;line-start: text
			
			;-----------------------------------------------------------
			; no search text 
			;-----------------------------------------------------------
			either empty? content edtr-search-text/aspects/text [
				;-----------------------------------------------------------
				; just add file list.
				;-----------------------------------------------------------
				append globals/search-result-list reduce [   to-local-file path  []   to-local-file path  ]
			][
				;-----------------------------------------------------------
				; search text for ANY line in search box (default).
				;-----------------------------------------------------------
				foreach search-text search-texts [
					; count lines within search-text
					parse/all search-text [(txt-lines: 0) any ["^/" (txt-lines: txt-lines + 1)] | skip]
					
					(current-line: 1)
					line-start: text
			
					;-----------------------------------------------------------
					; search text for ALL lines in search box.
					;-----------------------------------------------------------
					found-line: false
					ignore-line: false
					parse/all text [
						any [
							ignore-texts  (ignore-line: true)
							| [
									search-texts (
									line-txt: any [
										attempt [copy/part line-start find line-start "^/" ]
										copy line-start
									]
									
									replace/all line-start "^-" ""
									
									result-txt: rejoin [  to-local-file path  " (line " current-line ") : " line-txt   ]
									result-path: rejoin [ to-local-file path "/" current-line ]
									found-line: reduce [ result-txt  []  result-path ]
									
								
									current-line: current-line + txt-lines
								)
							]	
							| ign-cmts-rule
							
							| [
								"^/" line-start: (
								if all [
									found-line
									not ignore-line 
								][
									append globals/search-result-list found-line
								]
								found-line: false
								ignore-line: false
								current-line: current-line + 1
								wait 0
							)
							]
							
							| skip
						]
					]
				]
			]
			
			
			;
			; this is valid via the parse-rule generated from current setup 
			
			;---
			; check if the file is excluded from search list
			dirty lst-search-results/list-marble/aspects/list
		]
		
		vout
	]
	
	
	;-----------------
	;-         dir-tree()
	;-----------------
	dir-tree: funcl [
		path [file!]
		ignore-dirs [block!]  "these are matched exactly against the current path"
		ignore-files [block!] "these are searched within the current path"
		only-files [block!]   "only these files are listed is applied on files which aren't ignored."
		/root rootpath [file! none!]
	][
		;vin "dir-tree()"
		rval: copy []
		wait 0
		if Search-Pane/cancel? [
			;vprin "<"
			return rval
		]
		;vprin "."
		;v?? path
		;v?? ignore-dirs
		;v?? ignore-files
		;v?? only-files
		either root [
			unless exists? rootpath [
				log-error rejoin [ "dir-tree()" path " does not exist" ]
			]
		][
			either is-dir? path [
				rootpath: path
				path: %./
			][
				log-error rejoin [ "dir-tree()" path " MUST be a directory." ]
			]
		]
		
		dirpath: clean-path append copy rootpath path
		
		either is-dir? dirpath [
			; list directory content
			if list: attempt [read dirpath][
			
				
				; append that path to the file list
				append rval path
				
				foreach item list [
					if Search-Pane/cancel? [
						;vprin "<"
						return rval
					]
					subpath: join path item
					
					; list content of this new path item (files are returned directly)
					;v?? subpath
					;v?? ignore-dirs
					;vprint "##########################"
					full-path:  clean-path join rootpath subpath
					full-path-lcl: to-local-file full-path
					;v?? full-path
					either any [
						find ignore-dirs full-path
						(wait 0 false)
						foreach p ignore-dirs [ 
							;v?? p 
							;v?? full-path 
							;probe to-local-file full-path
							either file? p [
								if find full-path p [break/return true]
							][
								if find full-path-lcl p [break/return true]
							]
						]
						(wait 0 false)
						foreach p ignore-files [ 
							;v?? p 
							;v?? full-path 
							;probe to-local-file full-path
							either file? p [
								if find full-path p [break/return true]
							][
								if find full-path-lcl p [break/return true]
							]
						]
						(wait 0 false)
						unless any [
							empty? only-files
							(is-dir? subpath)
						][
							not foreach p only-files [
								;v?? p 
								;v?? full-path 
								;probe to-local-file full-path
								if find full-path p [break/return true]
							]
						]
					][
						vprint full-path
						wait 0
						vprint ["IGNORED! : " full-path-lcl ]
					][
						data: dir-tree/root subpath ignore-dirs ignore-files only-files rootpath
					]
				]
			]
		][
			path: clean-path join rootpath path
			;v?? path
			add-result path
		]
		
		;vout
		rval
	]

	
	
	;--------------------------
	;-         search-btn-action()
	;--------------------------
	; purpose:  
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; to do:    
	;
	; tests:    
	;--------------------------
	search-btn-action: funcl [
		event [object!]
	][
		vin "search-btn-action()"

		either Search-Pane/can-cancel? [
			Search-Pane/cancel?: true
			vprin "======== CANCEL ======="
			;Search-Pane/can-cancel?: false
			;Search-Pane/cancel?: false
			reset-search-button
			vreset
		][
			reset-search
			
			Search-Pane/can-cancel?: true
			
			fill event/marble/aspects/label "CANCEL"
			vprobe content event/marble/aspects/color
			fill event/marble/aspects/color red
			fill event/marble/aspects/label-color white
			;paths: extract next ( content Search-Setup-Pane/current-search/dirs/items ) 3
			
			list: content Search-Setup-Pane/current-search/dirs
			folders: extract (at list 4) 3
			v?? list
			v?? folders
			
			ignore-dirs: content Search-Setup-Pane/current-search/exclude-dirs
			ignore-dirs: extract (at ignore-dirs 4) 3
			
			ignore-files: content Search-Setup-Pane/current-search/exclude-files
			ignore-files: extract (at ignore-files 4) 3
			append ignore-files TEMP-IGNORE-PANE/get-list
			
			only-files: content Search-Setup-Pane/current-search/files
			only-files: extract (at only-files 4) 3
			
			
			foreach dir folders [
				v?? dir
				dir-tree dir ignore-dirs ignore-files only-files
			]
			Search-Pane/can-cancel?: false
			Search-Pane/cancel?: false
			reset-search-button
			vprint "Done !!"
		]
	
		vout
	]
	
	;--------------------------
	;-         -- gui --
	;--------------------------
	gui: gl/layout/within/options compose/deep [

		;row 5x5 [
			;column tight (globals/pane-title-color) (globals/pane-title-color) 3x3 [
				row [
					title "Search setups" left  150x25 (globals/pane-title-text-color) 
					hstretch
					tgl-comments: tool-icon stiff #check-mark-disabled #check-mark-enabled "Comments?" off horizontal (globals/pane-title-text-color) 
					tgl-any-srch: tool-icon stiff #check-mark-disabled #check-mark-enabled "Find Any?" on horizontal  (globals/pane-title-text-color) 
				
				]
					
				column [ ;( theme-bg-color ) ( theme-bg-color )  tight [
					;shadow-hseparator

					;column  [
						edtr-search-text: scrolled-editor 100x100 
					;]

					row (globals/pane-title-color) (globals/pane-title-color) corner 1 [
						hstretch
			 
						search-button: button "search" stiff  100x40 [
							search-btn-action event
						]
						hstretch
					] ; end of search button row
				]
			;]
		;]
		
	] 'column compose [tight (globals/pane-title-color) (globals/pane-title-color) 3x3 corner 1]
]



;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- TEMP-IGNORE-PANE
;
;-----------------------------------------------------------------------------------------------------------
temp-ignore-pane: context [
	;--------------------------
	;-         file-list:
	;
	; a plug containing just the files from the temp ignore list.
	;--------------------------
	file-list: liquify/fill !plug none
	
	
	;--------------------------
	;-         sed:
	;
	; scrolled-editor reference
	;--------------------------
	sed: none
	
	
	;--------------------------
	;-         reset-list()
	;--------------------------
	; purpose:  reset the file
	;--------------------------
	reset-list: funcl [][
		vin "reset-list()"
		blk: content file-list
		;probe blk
		clear next blk
		append blk copy ""
		dirty file-list
		c: content sed/editor-marble/aspects/cursors
		clear c
		dirty sed/editor-marble/aspects/cursors
		c: content sed/editor-marble/aspects/selections
		clear c
		dirty sed/editor-marble/aspects/selections
		probe content file-list
		gl/unfocus sed/editor-marble
		vout
	]
	
	;--------------------------
	;-         add-to-list()
	;--------------------------
	; purpose:  add a new file in list
	;
	;  2015-11-04 - now inserts at top.
	;--------------------------
	add-to-list: funcl [
		path
		/full-path
		/only-folder
	][
		vin "add-to-list()"
		blk: content file-list
		case [
			full-path [
				insert next blk path 
			]
			
			only-folder [
				insert next blk directory-of path
			]
			
			'default [
				insert next blk filename-of path
			]
		]
		dirty file-list
		vout
	]
	
	;--------------------------
	;-         get-list()
	;--------------------------
	; purpose:  returns the data in a flat block, block can be modified, it is independent.
	;--------------------------
	get-list: funcl [
	][
		vin "get-list()"
		
		blk: copy next content file-list
		
		remove-each item blk [
			item: trim copy item
			any [
				empty? item
				#";" = first item
			]
		]
		
		vout
		blk
	]
	
	
	;--------------------------
	;-         remove-current-selection()
	;--------------------------
	; purpose:  removes selected files from the list.
	;--------------------------
	remove-current-selection: funcl [
	][
		vin "remove-current-selection()"
		vout
	]
	
	
	;--------------------------
	;-        -- GUI: --
	;
	;
	;--------------------------
	gui: gl/layout/within/options [
		title "Ignore these:"
		column [
			sed: scrolled-editor 200x100
		]
		row	[
			hstretch
 			button "reset list" 100x40 [ reset-list ] stiff
 			hstretch
		]
	] 'column [  ]
	
	attach file-list   sed/editor-marble/material/lines
]

;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- UTIL FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------


;--------------------------
;-     safe-quit()
;--------------------------
; purpose:  leaves the app while making sure the configuration was saved.
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
safe-quit: funcl [
][
	vin "safe-quit()"
	
	setups: content globals/setups-list
	
	save-data
	
	quit
	
	vout
]



;--------------------------
;-     save-data()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
save-data: funcl [
][
	vin "save-data()"
	specs: setups-to-specs
	v?? specs
	
	globals/config/set 'search-setups specs
	
	globals/config/set 'last-search content edtr-search-text/aspects/text
	globals/config/set 'last-ignored content temp-ignore-pane/sed/aspects/text
	
	if Search-Setup-Pane/current-search [
		globals/config/set 'last-search-setup content Search-Setup-Pane/current-search/name
	]	
	
	globals/config/to-disk
	
	vout
]


;--------------------------
;-     load-data()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    
;
; to do:    
;
; tests:    
;--------------------------
load-data: funcl [
][
	vin "load-data()"
	globals/config/from-disk 
	
	search-setups: globals/config/get 'search-setups
	
	fill  temp-ignore-pane/sed/aspects/text  globals/config/get 'last-ignored
	fill  edtr-search-text/aspects/text  globals/config/get 'last-search
	
	foreach spec search-setups [
		add-setup/with spec
	]
	
	if stp: globals/config/get 'last-search-setup [
		search-Setup-Pane/display-setup stp
	]
	
	vout
]


;--------------------------
;-     log-error()
;--------------------------
; purpose:  keep error messages for future reference by user.
;
; inputs:   message to log
;
; notes:    - use the error-pane gui to look at list of errors.
;           - we add the time and date of the error.
;
; to do:    
;
; tests:    
;--------------------------
log-error: funcl [
	error-msg
][
	vin "log-error()"
	time: now/time
	error-msg: rejoin [ "Error: " time/hour ":" time/minute ":" time/seconds ]
	;probe error-msg
	vout
]





;--------------------------
;-     edit-file()
;--------------------------
; purpose:  
;
; inputs:   
;
; to do:    
;
; tests:    
;--------------------------
edit-file: funcl [
	path
][
	vin "edit-file()"
	
	v?? path
	
	app-path: globals/config/get 'editor-path
	
	cmd: rejoin [ app-path { /a "} path {"}	]
	
	v?? cmd
	call cmd
	
	
	vout
]










;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- MAIN GUI
;
;-----------------------------------------------------------------------------------------------------------

;----
; just list the various marbles for claritie's sake, has no actual effect, since the main gui is global, 
; it will set these as global on its own.
;----
up-btn: down-btn: none


gl/layout/size compose/deep/only [
	;tool-row tight [
		;-    -toolbox
		icon-toolbox: row tight 5x5 [
;			icon stiff 60x60 #page "New" [
;			]
;			
;			icon stiff 60x60 #folder  "Open" [
;			]
;			
			icon stiff 60x60 #page-save "Save Setup" [
				save-data
			]
			
			;icon stiff 60x60 #refresh "Search" [
			;]
			
			hstretch
			
			icon stiff 60x60 #off #on "Show paths" [
				globals/show-paths?:  event/new-toggle-state
				either event/new-toggle-state [
					print "-----------------------------^/Will list paths here...^/^/ ATTENTION: do not close this window, it will quit app^/-----------------------------^/^/"
					;probe words-of event
					;probe event/new-toggle-state
				][
					print "^/-----------------------------^/Stopped listing paths^/-----------------------------" 
				]
			]

			;icon stiff 60x60 #gear "Setup" [
			;]
			
			icon stiff 60x60 #on #off "Debug" [
				toggle-debug
			]
			
			icon stiff 60x60 #help  [ request-inform/message "Help" "You Wish!!!" ]
		]
	;]
	;shadow-hseparator

	row tight 5x5 [
		;-    -search list
		main-setup-frame:  column tight stiff (globals/pane-title-color) (globals/pane-title-color) 3x3 [
			row [
				title "Search setups" left  150x25 (globals/pane-title-text-color) 
				tool-icon #right-flat #left-flat no-label stiff [
					vprobe content event/marble/aspects/engaged?
					either content event/marble/aspects/engaged? [
						gl/collect setup-edit-frame search-setup-pane/gui
					][
						gl/unframe search-setup-pane/gui
					]
				]
			]
				
			column ( theme-bg-color ) ( theme-bg-color )  tight [
				shadow-hseparator
				row tight [
				;row corner 0 [
					;hstretch (red) (blue)
					
					tool-icon #add no-label stiff [
						add-setup
					]
					tool-icon #clone no-label stiff [
						either setup: Search-Setup-Pane/current-search [
							clone-setup setup
						][
							gl/request-inform "Must select a setup to clone first"
						]
						;add-setup
					]
					tool-icon #delete no-label stiff [
						;print "delte"
						delete-setup Search-Setup-Pane/current-search
					]
					hstretch
					mv-srch-blocker-pane: row tight [
					
						up-btn: tool-icon #up-flat no-label stiff [
							blk: content globals/setups-collection
							
							;chosen: content lst-search-setups/list-marble/aspects/chosen
							chosen: content lst-search-setups/list-marble/material/chosen-items
							chosen: extract/index next chosen 3 3
							
							; bump up each setup in the list gathered previously
							new-blk: make block! length? blk
							foreach stp blk [
								either i: find chosen stp [
									insert back tail new-blk stp
									remove i
								][
									append new-blk stp
								]
								
								;---
								; unlink the setup from its observer 
								insubordinate stp/self-plug
							]
							
							; flush and relink the main list, using the new order
							foreach stp new-blk [
								link globals/setups-collection stp/self-plug
							]
						]
						
						down-btn: tool-icon #down-flat no-label stiff [
							blk: content globals/setups-collection
							
							;chosen: content lst-search-setups/list-marble/aspects/chosen
							chosen: content lst-search-setups/list-marble/material/chosen-items
							chosen: extract/index next chosen 3 3
							
							; bump up each setup in the list gathered previously
							tmp-blk: make block! length? blk
							new-blk: make block! length? blk
							foreach stp blk [
								either find chosen stp [
									append tmp-blk stp
								][
									append new-blk stp
									append new-blk tmp-blk
									clear tmp-blk
								]
								
								;---
								; unlink the setup from its observer 
								insubordinate stp/self-plug
							]
							append new-blk tmp-blk
							
							; flush and relink the main list, using the new order
							foreach stp new-blk [
								link globals/setups-collection stp/self-plug
							]
						]
					]
				]
				;]
				
				row tight [
					column [
						lst-search-setups: scrolled-list 150x150 no-label  on-click [
							vin "lst-search-setups/on-click()"
							vprobe type? Search-Setup-Pane/current-search
							
							if object? setup: pick event/picked-data 3 [
								Search-Setup-Pane/display-setup setup
							]
							
							vprobe type? Search-Setup-Pane/current-search
							fill lbl-footer/aspects/label join "Current setup: " content Search-Setup-Pane/current-search/name
							vout
						]
					]
					setup-edit-frame: column tight []
				]
			]
		]
		;spacer 3
		dragbar 15x15
		;spacer 3
;		column 1x0 [
;			main-drag-bar: elastic  stiff  10x250 (black) (white * .85) corner 2 ; with [fill aspects/border-color white]
;		]
		tool-frame: row tight [
			
		]
	]
	
	dragbar 12x12
	
	
	;-    -result list
	column [
		column tight  (globals/pane-title-color) (globals/pane-title-color) 1x1 corner 3 [
			row 1x1 (globals/pane-title-color)(globals/pane-title-color)  [
				lbl-result-title: title "Search results" left  150x25 (globals/pane-title-text-color) stiff
			]
			
			column stiff-x  tight  (gold) (black)[
				lst-search-results: scrolled-list 150x100 no-label stiff-x [  ] 
				on-click [
					vin "lst-search-results/on-click()"
				
					path: pick event/picked-data 3
					;v?? path 
					
					;call rejoin [{uedit32 /a "} path {"}]
					edit-file path
					vout
				]
				on-context-click [
					;print "WWW"
					;probe words-of event
					;probe event/picked
					path: pick event/picked-data 3
					
					file-path: copy/part path find/last path "/"
					
					case [
						event/shift? [
							temp-ignore-pane/add-to-list/full-path file-path
						]
						
						event/control? [
							temp-ignore-pane/add-to-list/only-folder file-path
						]
						
						'default [
							temp-ignore-pane/add-to-list file-path
						]
					]
					;blk: content file-list
				]
			]
		]
	]
	shadow-hseparator
	lbl-footer: label left "Current setup:"
	
] 1000x700


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- LINKUP GUI DATA
;
;-----------------------------------------------------------------------------------------------------------
link/reset lst-search-setups/aspects/items globals/setups-list


gl/collect tool-frame Search-Pane/gui
gl/collect tool-frame temp-ignore-Pane/gui

link/reset mv-srch-blocker-pane/aspects/enabled? lst-search-setups/list-marble/material/chosen?


globals/result-list-plug: lst-search-results/list-marble/aspects/list
globals/search-result-list: content globals/result-list-plug

link/reset globals/results-title globals/result-list-plug

link/reset lbl-result-title/aspects/label globals/results-title

load-data



;
;
;main-drag-bar/actions: context [
;	select: funcl [event][
;		event/marble/user-data: content main-setup-frame/aspects/dimension-adjust
;	]
;
;	drop?: drop: drop-bg: swipe: release: funcl [event][
;		if in event 'drag-delta [
;			fill main-setup-frame/aspects/dimension-adjust (event/marble/user-data + event/drag-delta * 1x0)
;		]
;	]
;
;	start-hover: funcl [event] [
;		fill event/marble/aspects/color globals/pane-title-color
;		;fill event/marble/aspects/border-color black
;	]
;	
;	end-hover: funcl [event] [
;		fill event/marble/aspects/color white * .85
;		;fill event/marble/aspects/border-color none
;	]
;]




;print "========3=========="

;liquid-lib/von


do-events



; if we end up here, the app ended by closing the last window, 
; make sure we end the app gracefully.

safe-quit


