rebol  [
	; -- Core Header attributes --
	title: "Header box - Rebol header and script management."
	file: %header-box.r
	version: 1.0.2
	date: 2013-11-04
	author: "Maxim Olivier-Adlhoch"
	purpose: "Rebol script and header compliance tool."
	web: http://www.revault.org
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
		v1.0.0 - 2013-10-25
			-first release.
			
		v1.0.1 - 2013-10-26
			-Added support for the (optional) slim-path-setup.r file, as part of the steel project
			
		v1.0.2 - 2013-11-04
			-little ui tweak to prevent filepath from squashing script output options.
	}
	;-  \ history

	;-  / documentation
	documentation: {
		Choose a spec file and then load a script.  The tool will make a GUI which replicates the spec
		so that you can easily setup the script's header.
		
		It can automatically create the header so that is forces some values like license and authors.
		
		A few spec files are given as examples.
		
		Spec files can also execute some code to build values based on other header values.  Looking at the
		example spec files should be pretty self-explanatory.


		sLIM SETUP
		=========
		
		Note that you can easily setup slim by adding a file within the root of steel.
		
		slim-path-setup.r will be checked for existence and run whenever it does.  you just need to put
		the path to your slim.r file there.  
		
		This file is part of the steel .gitignore file, so it wont try to commit it back ... 
		i.e. its really local to your installation.
		
		Alternatively, it will try to find slim outside of steel or within steel, if you put it there.
	}
	;-  \ documentation
]

;----
; starts the slim library manager, if it's not setup.. the following loading setup allows slim 
; to be installed either within the steel project or just outside of it, to be shared in multiple
; tools.
; 
unless value? 'slim [
	do any [
		all [ exists? %../slim-path-setup.r do read %../slim-path-setup.r ]
		all [ exists? %../../slim-libs/slim/slim.r  %../../slim-libs/slim/slim.r ] 
		all [ exists? %../slim-libs/slim/slim.r     %../slim-libs/slim/slim.r    ] 
	]
]

slim/vexpose

;von



;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------


;-----------------
; Opening source modules we need
;-----------------
; open GLASS
gl: slim/open/expose 'glass none [ screen-size request-string request-inform request-confirmation discard unframe ]
sillica-lib: slim/open 'sillica none 


;--------------
;-     open gui libraries.
event-lib: slim/open 'event none
gsl-lib: slim/open 'group-scrolled-list none
fld-lib: slim/open 'style-field none
slim/open 'style-droplist none
slim/open/expose 'icons none [load-icons]

icn-lib: slim/open 'style-icon-button none
flb-lib: slim/open 'style-field none


;--------------
;-     open data libraries.
glue-lib: slim/open/expose 'glue none [ !length !to-string !pick !construct !merge !gate ]
epoxy-lib: slim/open/expose 'epoxy none [!to-string-pipe-master]
bulk-lib: slim/open 'bulk none
liquid-lib: slim/open/expose 'liquid none [fill content link attach liquify !plug pipe unlink processor container insubordinate ]
hdr-plugs-lib: slim/open/expose 'hdr-plugs none [ !object !attribute !header !pick-link !computor !pick-ctx]
ink-lib: slim/open/expose 'liquid-ink none [ !split-script ]
slim/open/expose 'utils-strings none [ zfill ]
slim/open/expose 'utils-script none [ source-entab ]
slim/open/expose 'utils-files none [ filename-of ]


;--------------
;-     i/o libs
cfg-lib: slim/open/expose 'configurator none [configure] 


;--------------
;-     manage library verbosity
;--------------
;flb-lib/von
;icn-lib/von
;fld-lib/von
;epoxy-lib/von
;bulk-lib/von
;liquid-lib/von

;hdr-plugs-lib/von
;glue-lib/von
;ink-lib/von
;fld-lib/von
;gl/von
;von



;----
; test automatic object creation
;----
; hdr-plugs-lib/von
; a: liquify/fill !plug "toto"
; b: liquify/fill !plug 11
; a1: liquify/fill !plug "hge"
; b1: liquify/fill !plug 666
; attr: liquify/link !attribute [a b]
; attr1: liquify/link !attribute [a1 b1]
; o: liquify/link !object [attr attr1]
;
; o2: liquify/link !object [ a b a1 b1 ]
;
; probe content o
; probe content o2
;
; ask ".."



;scr-frame-lib: slim/open 'group-scrollframe none

load-icons/size 32
load-icons/size/as 16 'toolbar


dark-gray: (gray * 0.85)

;------------------------------------
;- GLOBALS
;------------------------------------
global: globals: context [
	pane-title-color: white * .5 ;80.130.230
	pane-title-text-color: white
	pane-bg-color: white * .75 ; white
	
	
	
	;--------------------------
	;-    current-attrs:
	;
	; stores the global list of attributes being played with.
	;--------------------------
	current-attrs: []
	
	
	
	;--------------------------
	;-    header-value-ctx:
	;
	; will connect to attrs and their values.
	;--------------------------
	header-value-ctx: liquify !object
	
	
	
	;--------------------------
	;-     current-file:
	;
	; once loaded, we store the current-filename here
	;--------------------------
	current-file: liquify !plug
	
	
	;--------------------------
	;-     current-spec-file:
	;
	; when loaded, stores the path here, so we can easily reset UI.
	;--------------------------
	current-spec-file: liquify !plug
	
]





;------------------------------------
;- PREFS
;------------------------------------
cfg: configure compose/only [
	default-spec: %minimal.hbxspec  "Header box spec to use when application loads, if present"
]

cfg/from-disk/using  %header-box.cfg ; will set cfg/store-path if nothing has been saved yet.

;print "+++++++++++++++++++++++++++"
;probe cfg/get 'default-spec
;print "+++++++++++++++++++++++++++"




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- CLASSES
;
;-----------------------------------------------------------------------------------------------------------

;--------------------------
;- !attr:
;
; quick setup which stores and computes an attribute
;--------------------------
!attr: context [
	;--------------------------
	;-     computed?:
	;
	; is this attribute computed automatically?
	;--------------------------
	computed?: false

	;--------------------------
	;-     name:
	;
	; a plug with the name of the attribute.
	;--------------------------
	name: none
	
	;--------------------------
	;-     type:
	;
	; the (logical) type of the attribute
	;--------------------------
	type: none
	
	;--------------------------
	;-     datatype:
	;
	; the rebol destination datatype
	;--------------------------
	datatype: string!
	

	;--------------------------
	;-     source:
	;
	; the textual value within the field.  may not be datatype compliant.
	;--------------------------
	source: ""
	
	

	;--------------------------
	;-     value:
	;
	; current value of the attribute, if computed, this is the last computed result.
	;--------------------------
	value: none
	
	
	;--------------------------
	;     build-control:
	;
	; generates the VID block to show in a gui.
	;--------------------------
	;build-control: none
	

	;--------------------------
	;-     update-blk:
	;
	; the block of code which is executed on conversion.
	;--------------------------
	update-blk: [
		VAL: any [
			attempt [
				;----
				; we'll add switches if needed.
				;----
				switch/default type [
					;----------------
					; DATE!
					;
					; we ignore the time zone if any
					;----------------
					date! [
						source: get in context [
							date: attempt [load source]
							unless date? date [to-error "not a date"]
							date/zone: none
						] 'date
					]
				][
					to datatype source
				]
			]
			source 
		]
		vprint datatype
		vprobe source
		vprobe VAL
		vprint "==========================================================="
		VAL
	]

	
	;--------------------------
	;-     locked?:
	;
	; when set, the attribute cannot be changed by the user or when loading a script.
	;--------------------------
	locked?: false
	
	
	;--------------------------
	;-     default:
	;
	; a value used to initialize scripts missing this attribute. 
	; 
	; is never erased, so can be used to "reset" the field.
	;--------------------------
	default: none
	
	
	;--------------------------
	;-     from-script?:
	;
	; this is set when the attribute was loaded from a script, so that it can be removed when reset is pressed
	; or if the 
	;--------------------------
	from-script?: none

	
]



;--------------------------
;- !comp-attr:
;
; a subtype of attributes which relies on an attribute context which build its value on the fly.
;--------------------------
!comp-attr: make !attr [
	computed?: true

	;--------------------------
	;-     update-blk:
	;
	; the block of code which is executed on conversion.
	;--------------------------
	update-blk: copy/deep [
		value: any [
			attempt [ to datatype do source ]
			attempt do source 
			source
		]
	]
]





;-------------------------
;-     header-ctx:
;
;
;--------------------------
header-ctx: none




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------


;--------------------------
;-     auto-attr?()
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
auto-attr?: funcl [
	attr
][
	attr/computed?
]




;--------------------------
;-     update-computed()
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
update-computed: funcl [
	attrs [block!]
][
	vin "update-computed()"
	;-------------
	; update static fields
	foreach attr attrs [
		if all [
			not auto-attr? attr 
			set-word? attr/name
			datatype? attr/datatype
		][
			vprint ["SETTING: " attr/name]
			vprobe attr/value
			header-ctx/(to-word attr/name): attr/value
		]
	]
	
	vprobe header-ctx
	
	
	;-------------
	; update computed fields
	foreach attr attrs [
		if auto-attr? attr [
			bind attr/source header-ctx
			bind attr/update-blk attr
			
			;vprint ">>>>>>>>>>>>>>>>>"
			;vprobe attr/source
			do attr/source
			;vprint "<<<<<<<<<<<<<<<<<"
			
			;vprobe attr/name
			attempt [
				;vprobe attr/update-blk
				;vprobe attr/source
				attr/ctrl/text: do attr/update-blk
			
				show attr/ctrl
			]
		]
	]
	vout
]



;--------------------------
;-     to-rebol-type()
;--------------------------
; purpose:  takes a logical type from the spec dialect and returns its rebol equivalent
;
; inputs:   
;
; returns:  
;
; notes:    returns a datatype! type.
;
; tests:    
;--------------------------
to-rebol-type: funcl [
	from-type [word! datatype! none!]
][
	vin "to-rebol-type()"
	v?? from-type
	rval: switch/default from-type [
		text! [ string! ]
		choice!  [ string! ]
		none [none] ; none is a special case, it means not typed. this converts the word 'none to value #[none]
	][
		to-datatype from-type
	]
	vout
	
	rval
]





;--------------------------
;-     add-slut-test-wrapper()
;--------------------------
; purpose:  wraps the script part of the input within a slut  "test-enter-slim" setup
;
; inputs:   
;
; returns:  
;
; notes:    this will be converted to a function plug.
;
; tests:    
;--------------------------
add-slut-test-wrapper: funcl [
	text [string! none!]
][
	vin "add-slut-test-wrapper()"

	;print "slutting slim lib!"
	new-text: text ; backup in case given text is invalid.
	
	if all [
		string? text 
		;probe "1"
		ptr: find/tail text "slim-name: "
		;probe "2"
		slim-name: first load/next ptr
		;probe "3"
		new-text: copy text
		;probe "4"
		hdr: find new-text "slim/register"
		;probe "5"
	][
		;?? slim-name
		
		insert hdr rejoin [{;--------------------------------------
; unit testing setup
;--------------------------------------
;
; test-enter-slim '} slim-name {
;
;--------------------------------------

}	]

		append new-text 
{

;------------------------------------
; We are done testing this library.
;------------------------------------
;
; test-exit-slim
;
;------------------------------------

}  

	]
	vout
	
	new-text
]




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUGS
;
;-----------------------------------------------------------------------------------------------------------
;--------------------------
;-     --declare new plug classes--
;---

; here we just create simple classes based directly on 
;liquid-lib/von
foreach f [ rejoin  mold  detab  source-entab  add-slut-test-wrapper ][
	plug-name: to-word rejoin ["!" f ]
	ff: get f
	set plug-name processor plug-name :ff ;func
]



;--------------------------
;-     --define plug instances--
;---
;--------------------------
;-     hdr-ctx-plg:
;
; builds an object out of all attributes in the attribute list 
;--------------------------
hdr-ctx-plg: liquify !object


;--------------------------
;-     current-attrs-plg:
;
; contains the list of current attrs for other plugs to inspect
;--------------------------
current-attrs-plg: liquify/fill !plug globals/current-attrs


;--------------------------
;-     hdr-computed-ctx-plg:
;
; this computes all the automatic attributes 
;
; it returns a context ready to use in header and display
;--------------------------
hdr-computed-ctx-plg:  liquify/link !computor reduce [ hdr-ctx-plg current-attrs-plg ]


;--------------------------
;-     hdr-text-plg:
;
; stores the header as text
;--------------------------
;hdr-text-plg:  liquify/link !to-string-pipe-master hdr-computed-ctx-plg


;--------------------------
;-     rebol-header:
;
; the final header built from all the data
;--------------------------
rebol-header: liquify/link !header [ hdr-computed-ctx-plg current-attrs-plg ]


;--------------------------
;-     input-script:
;
; when a script is imported, we store it here.
;
; we put a string as default, to make it less prone to error out.
;--------------------------
input-script: liquify/fill !plug  ""


;--------------------------
;-     split-script:
;
; extracts the header block from the script right at the 'R' in REBOL [
;--------------------------
split-script: liquify/link !split-script input-script


;--------------------------
;-     script-header-str:
;
; extracts the second item from the script split
;--------------------------
script-header-str: liquify/link/fill/with !pick split-script 2 [
	resolve-links?: 'LINK-BEFORE
]

script-pre-hdr: liquify/link/fill/with !pick split-script 1 [
	resolve-links?: 'LINK-BEFORE
]

script-body: liquify/link/fill/with !pick split-script 3 [
	resolve-links?: 'LINK-BEFORE
]


;--------------------------
;-     loaded-input-hdr:
;
; results in an object, based on the extracted header
;--------------------------
loaded-input-hdr: liquify/link !construct script-header-str


;--------------------------
;-     merged-script:
;
; the script merged back with its pre-header, header and script code.
;--------------------------
merged-script: liquify/link !rejoin  liquify/link !merge reduce [  script-pre-hdr   rebol-header   script-body  ]



;--------------------------
;-     slutted-slim-lib:
;
; version of the merged-script which has the slut.r slim library wrapper added to the script source.
;--------------------------
slutted-slim-lib: liquify/link !add-slut-test-wrapper merged-script



;--------------------------
;-     slutted-toggle:
;
; switches an inline (optional) version of the merged script with slut control.
;--------------------------
slutted-toggle: liquify/fill !plug false



;--------------------------
;-     tweaked-script:
;
; the version of the merged script with any tweaks applied (or not), ready to be tab controled.
;--------------------------
tweaked-script: liquify/link !gate reduce [slutted-slim-lib slutted-toggle merged-script]




;--------------------------
;-     tab-size:
;
; stores size of tabs for entab-detab process.
;--------------------------
tab-size: liquify/fill !plug 4



;--------------------------
;-     tab-output:
;
; the version of the output using tabbed indents
;--------------------------
tabbed-output: liquify/link !source-entab reduce [tab-size tweaked-script]


;--------------------------
;-     spaced-output:
;
; the version of the output using space indents
;--------------------------
spaced-output: liquify/link !detab tweaked-script


;--------------------------
;-     tab-toggle:
;
; a plug used to toggle the tabing mode in script output.
;--------------------------
tab-toggle: liquify/fill !plug true


;--------------------------
;-     script-output:
;
; version of the script which has cleaned up tabs.
;
; currently, the tabbing is hard-coded to 4 spaces.
;--------------------------
script-output: liquify/link !gate reduce [tabbed-output tab-toggle spaced-output]





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------
	
;--------------------------
;-     load-spec()
;--------------------------
; purpose:  read a spec from disk and show its guts here.
;
; inputs:   file path
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
load-spec: funcl [
	path [file!]
][
	vin "load-spec()"

	v?? path
	either exists? path [
		unless 
		;attempt 
		do [
			data: load path
			if all [
				block? data
				block? attrs: parse-header-spec data 
			][
				global/current-attrs: attrs
				fill current-attrs-plg attrs
				layout-attrs attrs header-ctx
				
				set-msg rejoin ["loaded spec file!: '" to-local-file path "'"]
				fill globals/current-spec-file path
				true
			]
		][
			set-msg/error rejoin ["error loading spec file!: '" to-local-file path "'"]
		]
	][
		set-msg/error rejoin ["Invalid spec file path!: '" to-local-file path "'"]
	]
	vout
]





;--------------------------
;-     load-script()
;--------------------------
; purpose:  read a file from disk and pass it through our script spliter, 
;           then attempts to fill the gui with its attributes.
;
;	        any unused attributes are added to the attr-spec at the end.
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
load-script: funcl [
	path [file!]
][
	vin "load-script()"
	
	if exists? path [
		loaded-attrs: copy []
		
		data: read path 
		fill input-script data
		
		fill globals/current-file path
		
		ctx: content loaded-input-hdr
		
		v?? ctx
		
		vprint "===============>>>"
		foreach attr attrs: global/current-attrs [
			vprint ""
			if all [
				object? attr/name 
				string? attr-name: content attr/name
				word? attempt [ attr-name: to-word attr-name ]
			][
				v?? attr-name
				append loaded-attrs attr-name
				either in ctx attr-name [
					vprobe "is in the script!"
					
					;vprobe type? attr/value
					;---
					; some attributes have no value plug because they are computed.
					if object? attr/value [
						data: get in ctx attr-name
						
						unless string? data [
							data: mold data
						]
						
						either all [
							attr/locked?
							data <> content attr/value
						][
							
							if ( 
								request-confirmation/message "Overide?" rejoin [ 
									"Attribute '" attr-name "' is locked in spec... ^/Do you want to overwrite it with value from script?:^/^/'" 	
									either (length? data) > 100 [join copy/part data 100 " ..." ][data]
									"'"
								]
							 )[
								fill attr/value data
							]
						][
							fill attr/value data  
						]
					]
				][
					vprobe "isn't in the script!"
				]
			]
		]
		vprint "<<<==============="
		
		vprint "These are attributes added within the application:"
		vprobe words-of ctx
		vprobe loaded-attrs
		script-attrs: exclude words-of ctx loaded-attrs
		
		unless empty? script-attrs [
			add-header-control "Script attributes"
		]
		
		vprint "================================================="
		v?? ctx 
		vprint "================================================="
		foreach word script-attrs [
			;v?? word
			data: get in ctx word
			
			unless string? get in ctx word [
				data: mold data
			]
			;v?? data
			
			append attrs attr: make !attr [
				name: liquify/fill !plug to-string word
				type: 'text!
				value: liquify/fill/pipe !plug data
				datatype: string! 
				default:  get in ctx word
				locked?: false
				from-script?: true
			]
		;	vprobe content attr/value
			edtr: add-text-control/with-delete attr
			edtr: edtr/editor-marble
			
			
;			gl/layout/within compose/deep [
;				button "-" [  print ( attr/type )  ] 
;				
;			] attr-row
;				


			mtrl: edtr/material
			spct: edtr/aspects
			
			
			
			;----
			; link our data to the header context accumulator
			link hdr-ctx-plg attr/name 
			link hdr-ctx-plg spct/text
			
			attach attr/value spct/text
			fill attr/value data
			
			;link hdr-ctx-plg attr/value
			
		;	vprobe content attr/value
		]
		
	]
	
	probe-attrs
	;ask ">>"
	vout
]




;--------------------------
;-     save-script()
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
save-script: funcl [
	/as path [file!]
][
	vin "save-script()"
	if path: any [ 
		path 
		content globals/current-file
	][
	
		data: content script-output
		
		;path: join path ".bak" data
		
		vprobe content rebol-header
		v?? path
		
		write path data
		if as [
			fill globals/current-file path
		]
	]
	;ask "..."
	vout
]





;--------------------------
;-     parse-header-spec()
;--------------------------
; purpose:  
;
; inputs:   
;--------------------------
parse-header-spec: funcl [
	spec [block!]
	/extern header-ctx
][
	vin "parse-header-spec()"
	attr-list: copy [  ]
	
	new-ctx: copy []  ; we create a new header-ctx.
	
	parse spec [
		some [
			(
				vprint "^/^/----------------------------------------------------------------------------------------------------"
				; reset the attr at each "line"
				attr-expr: none
				attr-name: none
				attr-type: none
				attr-options: none
				attr-value: none
				attr-default: none
				hdr-comment: none
				attr-lock: false
				tmp: none
				
				options-rule: [
					'DO
					(vprint "Will 'DO expression")
					set attr-expr block!
				
					| 'IS  ; makes the attribute immutable (locked?: true)
					(vprint "attribute 'IS locked")
					set attr-value skip (attr-lock: true   unless attr-type [attr-type: type?/word attr-value]  )
					
					| 'DEFAULT ; allows to set a default without strict type (should become a string), will only be used when loaded script doesn't have a value.
					(vprint "attribute has a 'DEFAULT") 
					set attr-default skip
				]
				
				opt-rule: [
					some options-rule
				]
			)
	
			[
				set attr-name set-word! 
				[
					(
						v?? attr-name
					)
					opt [
						;------
						; don't attempt rule if it doesn't start with a word.
						; otherwise the attr-type will always be cleared since it will not match any of them.
						here: word! :here [
							(vprint 'WORD! vprobe first here)
							;---------------------------------
							; we use a tmp variable, to make sure the automatic default doesn't get overwritten
							; by not specifying the optional value.
							  set attr-type ['string! | 'text!]   ( attr-default: copy "iii" ) opt [set tmp string! (attr-default: tmp) ]
							| set attr-type 'lit-word!  ( attr-default: to-lit-word 'word )  opt [set tmp lit-word! (attr-default: tmp) ]
							| set attr-type 'tuple!     ( attr-default: 0.0.1 )              opt [set tmp tuple! (attr-default: tmp) ]
							| set attr-type 'date!      ( attr-default: now )                opt [set tmp date! (attr-default: tmp) ]
							| set attr-type 'block!     ( attr-default: copy [] )            opt [set tmp block! (attr-default: tmp) ]
							| set attr-type 'issue!     ( attr-default: #issue )             opt [set tmp issue! (attr-default: tmp) ]
							| set attr-type 'decimal!   ( attr-default: 1.0 )                opt [set tmp decimal! (attr-default: tmp) ]
							| set attr-type 'integer!   ( attr-default: 0 )                  opt [set tmp integer! (attr-default: tmp) ]
							| set attr-type 'pair!      ( attr-default: 0x0 )                opt [set tmp pair! (attr-default: tmp) ]
							| set attr-type 'logic!     ( attr-default: false )              opt [set tmp [logic! | 'true | 'false | 'yes | 'no ]  (attr-default: do tmp) ]
							| set attr-type 'char!      ( attr-default: #"a" )               opt [set tmp char! (attr-default: tmp) ]
							| set attr-type 'binary!    ( attr-default: copy #{} )           opt [set tmp binary! (attr-default: tmp) ]
							| set attr-type 'email!     ( attr-default: user@domain.com )    opt [set tmp email! (attr-default: tmp) ]
							| set attr-type 'file!      ( attr-default: copy %file.r )           opt [set tmp file! (attr-default: tmp) ]
							| set attr-type 'path!      ( attr-default: 'path/to/something ) opt [set tmp path! (attr-default: tmp) ]
							| set attr-type 'money!     ( attr-default:    $1.0 )            opt [set tmp money! (attr-default: tmp) ]
							| set attr-type 'decimal!   ( attr-default: 1.0 )                opt [set tmp decimal! (attr-default: tmp) ]
							| set attr-type 'tag!       ( attr-default: copy <tag> )         opt [set tmp tag! (attr-default: tmp) ]
							| set attr-type 'time!      ( attr-default: 1:00 )               opt [set tmp time! (attr-default: tmp) ]
							
							| set attr-type 'url!       ( attr-default: copy http://www.domain.com/ )   opt [set tmp url! (attr-default: tmp) ]
							
							| 'choice!	set attr-options block!  (
								attr-type: 'choice!
								; set a default, in case none is given later..
								attr-default: pick attr-options 1
								v?? attr-options
							)
							
							
							;-------------
							; word is a special case, it cannot specify a default word directly, you MUST use the 'DEFALT keyword.
							;
							; its simply because it can know if the next word is the default or the keyword.
							
							| set attr-type 'word!   ( attr-default: 'keyword )
						]
						(
							vprint "====== found type! ======>>"
							v?? attr-name
							v?? attr-type
							v?? attr-default
							vprint "<<============"
							opt-rule: [
								any options-rule
							]
						)
					]  
					
					; at least one item is required, unless the previous rule matched, in which case it becomes optionsal
					opt-rule 
					
					;---
					; any dangling values set the type and default value.  
					; note that they cannot precede official spec.
					| [
						(vprint "reverting to simple spec def, nothing matching found")
						set attr-default skip (
							attr-type: type?/word attr-default 
						)
					]
				]
				(
					vprint "--->"
					v?? attr-name
					v?? attr-type
					v?? attr-default
					vprint "<---"
					if set-word? attr-name [
						append new-ctx attr-name
					]
					vprobe attr-name
					case [
						attr-expr [
							vprint "Adding an automated attribute"
							append attr-list attr: make !comp-attr [
								name: liquify/fill !plug to-string attr-name
								type: attr-type
								datatype: to-rebol-type attr-type
								
								source: attr-expr
								locked?: attr-lock
								default:  attr-default
							]
							;append gui [computed-fld ]
						]
						
						attr-options [
							vprint "Adding a restricted choice attribute"
							append attr-list attr: make !attr [
								name: liquify/fill !plug to-string attr-name
								type: attr-type
								source: attr-options
								value: liquify/fill/pipe !plug attr-value
								datatype: to-rebol-type attr-type 
								default:  attr-default
								locked?: attr-lock
							]
;							append gui compose/only/deep [ 
;								choice 300x23  with [ texts: (attr-options) text: (attr-options/1)]
;							]
;							probe gui
						]
						
						
;						attr-type = 'text! [
;							append gui compose [ text-box  (any [all [attr-value to-string attr-value]  copy ""]  )   ]
;							;attr-type = string!
;						]
						
						'default [
							vprint "Normal field!"
							v?? attr-type
							v?? attr-value
							append attr-list attr: make !attr [
								name: liquify/fill !plug to-string attr-name
								type: attr-type
								value: liquify/fill/pipe !plug attr-value
								datatype: to-rebol-type attr-type 
								default:  attr-default
								locked?: attr-lock
							]
							
							v?? attr-type
							v?? attr-value
							v?? attr-default
							vprobe content attr/value
							vprint "//////////////"
;							append gui compose [ fld (any [all [attr-value to-string attr-value]  copy ""]  ) ]
						]
							
					]
					
					
				)
			]
			;-------------------
			; documentation
			;-------------------
			| set attr-value tag! (
				vprint "^/^/-------------------------------------------------- DOCS -------------------------------------------------------^/^/"
				vprobe attr-value
				vprobe first attr-value
				either (first attr-value) = #"/" [
					;-----------------
					; block-out!
					;---
					append attr-list make !attr [
						type: 'block-out!
						datatype: string!
						update-blk: none
						value: next to-string attr-value
					]
					vprint "<<< outdent"
				][
					;-----------------
					; block-in!
					;---
					append attr-list make !attr [
						type: 'block-in!
						datatype: string!
						update-blk: none
						value: to-string attr-value
					]
					vprint rejoin [
						">>> indent: " attr-value
					]
				]
				
			)
			| '----- (
				append attr-list make !attr [
					type: 'separator!
					datatype: string!
					update-blk: none
					value: "^-^/"
				]
				vprint "^/^/-------------------------------------------------- SEPARATOR -------------------------------------------------------^/^/"
			)
			| '=== set hdr-comment string! (
			
				append attr-list make !attr [
					type: 'comment!
					datatype: string!
					update-blk: none
					value: vprobe rejoin [
						hdr-comment
					]

				]
			)
		]
	]
	
	vprint "==========================================="
	v?? new-ctx
	vprint "==========================================="
	
	
	
	append new-ctx none
	new-ctx: context new-ctx
	
	
	;------------------------------------------------------
	; if all went well... we reset the header context.
	;
	; we do this at the end, since we may be called within an attempt
	; and we don't want to thrash the header-ctx until we know all is good.
	;------------------------------------------------------
	header-ctx: new-ctx
	
	v?? header-ctx
	
	
	probe-attrs 
	
	
	vout
	new-line/all attr-list true
]








;--------------------------
;-     probe-attrs()
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
probe-attrs: funcl [
][
	vin "probe-attrs()"
	foreach attr global/current-attrs [
		vprint "--"
		either object? attr/name [
			vprint content attr/name
		][
			vprint "???"
		]
		either object? attr/value [
			vprint type? content attr/value
		][
			vprint "value is not a plug!"
		]
		vprobe attr/type
		vprobe type? attr/value
		vprint "."
	]
	vout
]





;--------------------------
;-     get-attr-by-name()
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
get-attr-by-name: funcl [
	name [word! string!]
][
	vin "get-attr-by-name()"
	attr: none
	name: to-string name
	foreach item globals/current-attrs [
		if all [
			item/name
			name = content item/name
		][
			value: content item/value
			break
		]
	]
	
	vout
	value
]




;--------------------------
;-     add-history-entry()
;--------------------------
; purpose:  makes playing with the history a bit easier
;
; inputs:   the editor control to manipulate.
;
; returns:  
;
; notes:    modifies the text in the control, opens a requestor and automatically detects/fixes the version and/or date.
;
; tests:    
;--------------------------
add-history-entry: funcl [
	edtr [object!]
][
;	von
	vin "add-history-entry()"
	
	text: content edtr/aspects/text
	
	v?? text
	version: get-attr-by-name 'version
	v?? version
	
	; this is somewhat a bit illegal, but since we are manipulating the text "in-place" and its an edge... there is no real danger.
	append text rejoin [ "^/^-^-v" version " - " now/year "-" zfill now/month 2 "-" zfill now/day 2 "^/^-^-^--"]
	
	
	fill edtr/aspects/text text ; this will make sure all dependencies are updated.
	
	
	vout
]




;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- GUI
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
][
	vin "show-pane()"
	gl/surface main-frame pane
	vout
]





;--------------------------
;-     add-attr-row()
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
add-attr-row: funcl [
][
	vin "add-attr-row()"
	;-------------------------------
	; build the ROW
	gl/layout/within compose/deep [
		attr-row: row tight  [
		]
	] attr-frame
	vout
	attr-row
]




;--------------------------
;-     set-msg()
;--------------------------
; purpose: set the label in the message box.
;
; inputs:   text
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
set-msg: funcl [
	msg [string!]
	/warning  "sets the bg to yellow"
	/error "sets the bg to red"
][
	vin "set-msg()"
	fill msg-box-lbl/aspects/label msg
	fill msg-box-lbl/aspects/label-color black
	fill msg-box-bg/aspects/color none

	if warning [
		fill msg-box-bg/aspects/color gold
		fill msg-box-lbl/aspects/label-color black
	]
	
	if error [
		fill msg-box-bg/aspects/color red * 0.75
		fill msg-box-lbl/aspects/label-color white
	]
	vout
]




;--------------------------
;-     add-header-control()
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
add-header-control: funcl [
	banner [string!]
	/within attr-row
][
	vin "add-header-control()"
	attr-row: any [attr-row add-attr-row]
	gl/layout/within compose/deep [ column tight [label title left ( banner )  2 ]] attr-row

	vout
]



;--------------------------
;-     add-tuple-control()
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
add-tuple-control: funcl [
	attr [object!]
	attr-row [object!]
][
	vin "add-tuple-control()"
	gl/layout/within compose/deep [
		marble: field
		row tight [  ;hcavity (dark-gray) (dark-gray) tight [
			tool-icon #add stiff no-label [
				t-attr: (attr)
				either tuple? t: attempt [to-tuple content t-attr/value ] [
					t: t + 1.0.0
				][
					t: 1.0.0
				]
				fill t-attr/value t
			]
			tool-icon #add stiff no-label [
				t-attr: (attr)
				either tuple? t: attempt [to-tuple content t-attr/value ] [
					t: t + 0.1.0
				][
					t: 0.1.0
				]
				fill t-attr/value t
			]
			tool-icon #add stiff no-label [
				t-attr: (attr)
				either tuple? t: attempt [to-tuple content t-attr/value ] [
					t: t + 0.0.1
				][
					t: 0.0.1
				]
				fill t-attr/value t
			]
		]
	] attr-row
	
	vout
	marble/aspects/label
]





;--------------------------
;-     add-date-control()
;--------------------------
; purpose:  adds a group which contains a field and "today" button.
;
; inputs:   
;
; returns:  
;
; notes:    the update button checks the current date and only includes
;           new time if it already contained time information.
;
; tests:    
;--------------------------
add-date-control: funcl [
	attr [object!]
	attr-row [object!]
][
	vin "add-date-control()"
	gl/layout/within compose/deep [
		marble: field
		tool-icon #refresh stiff no-label [
			date: now
			dattr: (attr)
			date/zone: none
			date/time: all [
				date? attempt [old-date: load content dattr/value]
				time? old-date/time
				date/time
			]
			
			fill dattr/value date
		]
	] attr-row
	
	vout
	marble/aspects/label
]




;--------------------------
;-     add-text-control()
;--------------------------
; purpose:  
;
; inputs:   
;
; returns:  
;
; notes:    attr requires a name.
;
; tests:    
;--------------------------
add-text-control: funcl [
	attr [object!]
	/within attr-row [object!] 
	/with-delete
	/with-choices lbl src-a src-b
	/with-history-ctrl
][
	vin "add-text-control()"

	attr-row: any [ attr-row add-attr-row ]

	gl/layout/within compose/deep [
		attr-grp: column (gray) (gray) tight [
			title-row: row tight 2x2 [
				SubTitle left  ( white ) with [link/reset aspects/label (attr/name) ]
				hstretch
			]
			sedtr: scrolled-editor 100x300
		]
	] attr-row

	edtr: sedtr/editor-marble
	mtrl: edtr/material
	spct: edtr/aspects
	

	case/all [
	
		with-history-ctrl [
			gl/layout/within compose/deep [
				hcavity  (white * .75) (dark-gray) 2x2 [tiny-button "Add History Entry" 150x12 stiff  [ add-history-entry (edtr) ]  ] ; "Show expression?"
				;pick-chk: tool-icon stiff #check-mark-off #check-mark-on no-label
				;check-mark
			] title-row
		]
	
		
		with-choices [
			gl/layout/within compose/deep [
				auto-label (lbl) left (white) stiff ; "Show expression?"
				pick-chk: tool-icon stiff #check-mark-off #check-mark-on no-label
			] title-row
	
			src: mold attr/source
			src-plg: liquify/fill !plug src
			rst-plg: liquify/link !pick-ctx  reduce [ hdr-computed-ctx-plg    liquify/fill !plug to-word content attr/name ]
			plink:   liquify/link !pick-link reduce [ pick-chk/aspects/engaged? src-plg  rst-plg ]
			
			; we use a special trick where the pipe server is linked and feeds its pipe clients
			link/reset spct/text/pipe? plink
		]
		
		
		attr/computed? [
			fill edtr/aspects/color 200.255.220
			fill edtr/aspects/editable? false
		]	
		
		
		with-delete [
			gl/layout/within compose/deep [
				tool-icon stiff #delete no-label  [
					insubordinate (attr/value) 
					insubordinate (attr/name) 
					insubordinate (spct/text)
					remove find content current-attrs-plg (attr)
					unframe (attr-row)
				]
			] title-row
		]
		
		
		attr/locked? [
			fill edtr/aspects/editable? false
		]
		
		
		; some text controls are automated. so we link their text to the hdr-result.
		attr/value [
			data: content attr/value
			attach attr/value spct/text
			fill attr/value data
		]
	]
	
	vout
	
	sedtr
]







;--------------------------
;-     layout-attrs()
;--------------------------
; purpose:  generate pane out of attrs and a header context.
;
; inputs:   
;
; returns:  
;
; notes:    
;
; tests:    
;--------------------------
layout-attrs: funcl [
	attrs [block!]
	header-ctx [object!]
][
	vin "layout-attrs()"
	
	;----
	; we must clear the pane!
	; 
	discard attr-frame 'all
	
	;--------
	; to do!!!
	;
	;   we really need to implement the generic frame destroyer!!!
	;  
	;--------
	
	unlink hdr-ctx-plg
	
	foreach attr attrs [
		vin all [attr/name content attr/name]
	
		;--------------------------------
		; FILL THE ROW
		nofield?: false 
		if attr/name [
			;-------------------------------
			; all attributes with names are linked to the hdr-ctx, whatever their type.
			link hdr-ctx-plg attr/name
			vprint "linking attr/name"
		
			unless 'text! = attr/type [

				;-------------------------------
				; build the ROW
				attr-row: add-attr-row
				gl/layout/within compose/deep [
					SubTitle right stiff 125x20  with [link/reset aspects/label (attr/name) ]
				] attr-row
			]
			
		]
		
		
		case [
			;-         -computed?
			attr/computed? [
			
				; setup plugs needed for the switching of 
				src: mold attr/source
				src-plg: liquify/fill !plug src
				rst-plg: liquify/link !pick-ctx  reduce [ hdr-computed-ctx-plg    liquify/fill !plug to-word content attr/name ]
				
				
				either 'text! = attr/type [
					add-text-control/with-choices attr "Show expression?"  src-plg  rst-plg
				][
					slen: length? src
					clear any [find src "^/"   ""]  ; just keep the first line
					
					if slen <> length? src [
						append src "....."
					]
					
					gl/layout/within compose/deep [
						lbl: label left ( src ) (black) 200.255.220 2 
						pick-chk: tool-icon stiff #check-mark-off #check-mark-on no-label
					] attr-row
					plink:   liquify/link !pick-link reduce [ pick-chk/aspects/engaged? src-plg  rst-plg ]
					link/reset lbl/aspects/label plink
				]
				
				;-----
				; just make sure the dynamic context object is properly aligned.  its values will be filled later on.
				;-----
				vprint "linking empty value for computed args"
				link hdr-ctx-plg liquify/fill !plug "none"
			]
			
			attr/type = 'comment!  [
				attr-row: add-attr-row
				add-header-control/within  attr/value  attr-row
			]
			
			attr/type = 'separator!  [
;				nofield?: true
			]

			attr/type = 'block-in! [
				nofield?: true
			]

			attr/type = 'block-out! [
				nofield?: true
			]
			
			
			;-         -text!
			attr/type = 'text! [
				vprint "+++++++++++++++++++++++++++++++++++++"
				
				data: any [
					content attr/value 
					attr/default
				]
				v?? data
				
				either "history" = content attr/name [
					edtr: add-text-control/with-history-ctrl attr
				][
					edtr: add-text-control attr
				]

				edtr: edtr/editor-marble
				
				mtrl: edtr/material
				spct: edtr/aspects
				
				
				;----
				; link our data to the header context accumulator
				link hdr-ctx-plg spct/text

				attach attr/value spct/text
				fill attr/value data
				;probe data
				
				tdata: content attr/value
				
				if 'text! = attr/type [
					v?? tdata
				]
				vprint "+++++++++++++++++++++++++++++++++++++"
				
				if attr/locked? [
					fill edtr/aspects/editable? false
				]
			]
			

			;-         -choice!
			attr/type = 'choice! [
				link hdr-ctx-plg liquify/fill !plug "none"
			]


			;-----------------------
			;-         -default case
			'default [
				vprobe attr/locked?
				either attr/locked? [
					gl/layout/within compose [ 
						marble: label left ( src ) (black) 200.220.255 (blue) 2 
					] attr-row
					data-plug: marble/aspects/label
				][
					switch/default attr/type [
						date! [
							data-plug: add-date-control attr attr-row
						]
						tuple! [
							data-plug: add-tuple-control attr attr-row
						]
					][
						gl/layout/within compose [ marble: field ] attr-row
						data-plug: marble/aspects/label
					]
				]
				
				pipe data-plug
				
				;-------------
				; using /preserve  we attach ourself to the field's pipe, but keep our value
				; by immediately filling the pipe with our current value
				;
				; since the pipe does an automated string conversion, the field will always be happy.
				;-------------
				data: any [
					content attr/value 
					attr/default
				]
				v?? data
				attach attr/value data-plug
				
				;----------------
				; notice that we are not filling the field. but the data ends up there.
				;
				; my interface within the application is not the field, but the attribute itself.
				;----------------
				; adjust data going into the label
				switch type?/word data [
					file! [data: to-string data]
				]
				fill attr/value data
				
				link hdr-ctx-plg data-plug
			]
		]
		
		
		
		;vprobe content hdr-text-plg
		
		
		vout
	
	]
	vout
]








;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PANES
;
;-----------------------------------------------------------------------------------------------------------
use [def-spec-fld] [
	;--------------------------
	;-     setup-pane:
	;
	; stores any user-setup which we want to persist from session to session.
	;--------------------------
	setup-pane: gl/layout/within/tight compose/deep [
		vcavity (white) (dark-gray) [
;		row [
;			hstretch
;			button "back to attributes" 200x22 stiff [
;				show-pane attr-pane
;				vprint "preview"
;			]
;		]
;			
			auto-title left "User Preferences" (white) (black)  padding 10x10
			row tight [
				label right (white) "Default spec file " 200x25 stiff
				def-spec-fld: field ( to-local-file cfg/get 'default-spec ) [
					vin "def file action"
					path: content event/marble/aspects/label
					
					either attempt [
						any [
							all [
								data:  to-file path
								exists? data
								data
							]
							all [
								data: to-rebol-file path
								exists? data
								data
							]
						]
					][
						cfg/set 'default-spec copy data
					][
						; reuse and reset to previous value
						
						; its important to COPY the string otherwise, the field ends up editing the
						; config string directly.
						fill event/marble/aspects/label to-local-file cfg/get 'default-spec
					] 
					
					vout
				]					
				tool-icon #folder no-label stiff "Explorer" [
					if exists? path: request-file/title/only/keep/filter "Choose file to use as default spec" "Choose"  "*.hbxspec" [
						vprint "SETTING DEFAULT FILE PATH"
					]
					event-lib/queue-event event-lib/clone-event/with event [
						marble: def-spec-fld 
						action: 'set-text 
						text: to-local-file path  
					]
					 
				]
	
			]
			elastic
			row [
				;title left "User Preferences" (white) (black)  padding 10x10
			;row [
				hstretch
				button "back to attributes" 250x50 stiff [
					show-pane attr-pane
					vprint "preview"
				]
				hstretch
			;]
			]
		]
	
	] 'column 

]


;--------------------------
;-     attr-pane:
;
;  the actual attribute editor pane.  this pane gets filled up dynamically, based on the spec file being used.
;--------------------------
attr-pane: gl/layout/within/tight compose/deep [
	column  [
		auto-title left "Header Attribute Editor" (white) (black)  padding 10x10  5
		row [
			column [
				auto-label left attach (globals/current-spec-file)
				scroll-frame [
					attr-frame: column [
					]
					elastic
				]
			]
			column tight [
				row tight 2x2 [
					file-name-lbl: label "No file" left
					row tight (theme-bg-color) (theme-bg-color) [
						auto-label "Allow Edit" stiff left  ;  (red) (black)
						edit-chk: tool-icon stiff #check-mark-off #check-mark-on no-label
						;label 30x0 "   " stiff
						
						auto-label "Wrap slut.r?" stiff left padding 5x0 ;  (red) (black)  
						tool-icon stiff #check-mark-off #check-mark-on no-label  attach slutted-toggle off
						
						auto-label "Tab mode" stiff left padding 5x0 ;  (red) (black)  
						column tight (gray) [tool-icon stiff #spaces #tabs no-label  attach  tab-toggle on ]
					]
				]
				row tight [
					column tight [
						edtr: script-editor
						hscrl: scroller
					]
					column tight [
						row tight [
							vscrl: scroller
						]
						pad 20x20
					]
				]
			]
		]
	]
] 'column


;-------------------------
;-        -setup attribute pane plugs
; connect the text box to the  !HEADER object
;-------------------------
hdr-pipe: edtr/aspects/text/valve/pipe edtr/aspects/text
link hdr-pipe script-output

hdr-pipe/resolve-links?: 'LINKED-MUD




;--------------------------------
; shortcuts for simpler coding
;--------------------------------
mtrl: edtr/material
spct: edtr/aspects


;--------------------------------
; link-up the text scrollbars
;--------------------------------
link/reset hscrl/aspects/maximum mtrl/longest-line
link/reset hscrl/aspects/visible mtrl/visible-length
attach/to spct/left-off hscrl/aspects/value 'value
fill vscrl/aspects/value 0


link/reset vscrl/aspects/maximum mtrl/number-of-lines
link/reset vscrl/aspects/visible mtrl/visible-lines
attach/to spct/top-off vscrl/aspects/value 'value
fill vscrl/aspects/value 0

;fill edtr/aspects/editable? false
link/reset edtr/aspects/editable? edit-chk/aspects/engaged?

;fill edtr/aspects/text "this is a ^/test of big^/proportions"


;--------------------------------
;-     various stuff
;--------------------------------
link/reset file-name-lbl/aspects/label globals/current-file





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- MAIN GUI
;
;-----------------------------------------------------------------------------------------------------------
gui: gl/layout/size compose/deep [
	tool-row tight 5x5 [
	;-    -toolbox
		icon stiff 60x60 #page "Load..." [
			if file? path: request-file/keep/only/filter "*.r;*.r2;*.r3;*.reb" [
			
				load-script path
				vprint "Loaded rebol script!"
			]
		]
		
		icon stiff 60x60 #folder-open "Save" [
			save-script
		]
		
		icon stiff 60x60 #page-save "Save As..." [
			path: request-file/keep/only/save/title/filter "Save As..." "Save"  "*.r;*.r2;*.r3;*.reb"
			;vprobe path
			;ask "###"
			either file? path   [
				save-script/as path
			][
				set-msg/error rejoin [ "Invalid path: " mold path ]
			]
		]
		
		icon stiff 60x60 #refresh "Reset" [
			load-spec content globals/current-spec-file
		]
		
		
		icon stiff 60x60 #wrench  "Spec" [
			vprint "Select Spec"
			attempt [
				path: request-file/keep/only/filter "*.hbxspec"
				load-spec path
			]
		]
		
;				icon stiff #export "Preview" [
;					vprint "preview"
;				]
		
;				icon stiff 60x60 #wrench  "Attributes" [
;				]
		
		;icon stiff #key 
		hstretch
		icon stiff 60x60 #gear "Setup" [
			show-pane setup-pane
		]
		icon stiff 60x60 #help  [ request-inform/message "Help" "You Wish!!!" ]
	]
	shadow-hseparator
	row tight [
		column tight [
			;column [
				;main-ttl: title  "Headers"
					;-    -main-frame
				main-frame: column [
					;title "Welcome"
					elastic
				]
			;]
		]
	]
	msg-box-bg: column tight corner 0 [
		shadow-hseparator
		row 6x0 corner 0 [
			msg-box-lbl: label left  "Ready to load specs."
		]
	]
] ( screen-size * 0.60 ) 
fill gui/aspects/offset  10x30
gui/hide
gui/display


;view/new layout gui
;update-computed attrs

;von

show-pane attr-pane

load-spec cfg/get 'default-spec

;load-script %test.r
;sillica-lib/debug-mode?: 3


;print ""
;probe system/script/args

if string? system/script/args [
	args: load/all system/script/args
	;print "ARGS!!!!!!"
	;probe args
	;probe type? args/1
	parse args [
		some [
			[
				[ '-spec | '-s ] set path file! (
					;print "loading spec"
					;?? path
					load-spec path
				)
			]
			
			; we expect this to be a system local path
			| [
				set path url! (
					all [
						file? path: attempt [ to-rebol-file to-string path ]
						;print "loading script"
						;?? path
						load-script path
					]
				)
			]
			| [
				set path file! (
					;print "loading script"
					;?? path
					load-script path
				)
			]
		]
	]
]



do-events


cfg/to-disk
