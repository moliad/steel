REBOL [
	; -- basic rebol header --
	file:       %hdr-plugs.r
	version:    0.4.1
	date:       2011-01-20
	purpose:    "Reusable liquid plugs for use in header box."
	author:     "Maxim Olivier-Adlhoch"
	copyright:  "Copyright © 2013 Maxim Olivier-Adlhoch"

	;-- slim parameters --
	slim-name:   'hdr-plugs
	slim-prefix:  none
	slim-version: 0.9.11
]


slim/register [

	liquid: slim/open/expose 'liquid none [ !plug processor  ]

	;--------------------------
	;- !ATTRIBUTE:
	;--------------------------
	!attribute: processor/with '!attribute [
		vin "!attribute/process()"
		plug/liquid: any [plug/liquid copy []]
		
		append head clear head plug/liquid reduce [
			to-set-word pick data 1     pick data 2
		]
;		value: pick data 2
;		
;		either obj: plug/attr-obj [
;			obj/name: pick data 1
;			obj/value: pick data 2
;		][
;			plug/attr-obj: context [
;				name: 
;			]
;			plug/liquid: plug/attr-obj
;		]
		;vprobe plug/attr-obj
		vout
	][
		
		;--------------------------
		;-     out-type:
		;
		; the type this attribute should have.
		;
		; when left to none, no typecasting occurs.
		;
		; note that type casting may be different than default methods of REBOL.
		;--------------------------
		out-type: none
		
		
		;--------------------------
		;-     fallback:
		;
		; when typecasting is unavailable, we revert to this fallback value.
		;
		; whenever the casting works, the fallback is updated.
		;--------------------------
		fallback: none
		
		
		;--------------------------
		;-         attr-obj:
		;
		; built on the fly by process, persists until destroyed.
		;--------------------------
		;attr-obj: none
		
		
	]

	

	;--------------------------
	;- !OBJECT:
	;
	;
	; link up !attribute objects, returns an object.
	;--------------------------
	!object: processor/with '!object [
		vin "!object/process()"
		spec: head clear head plug/spec
		
		
		switch/default type?/word  pick data 1 [
			object! [
				
				; we expect a set of name value pairs.
				;
				; name can be in any format which can be converted directly to a set-word
				foreach attr data [
					append spec to-set-word attr/name
					append spec get in attr 'value
				]
			]
			
			block! [
				; one or more name value pairs
				foreach item data [
					append spec item
				]
			]
		][
			; linked in name value pairs directly.   no convertion is done on value.
			foreach [name value] data [
				append spec reduce [to-set-word :name  :value]
			]
		]

		plug/liquid: make object! spec
		vout		
	][
		; putting this in the plug instance, means it will be copied on every new instance.
		spec: []
	]
	
	
	
	
	;--------------------------
	;- !COMPUTOR()
	;--------------------------
	; purpose:  runs all computations of an attribute list.
	;
	; inputs:   given an attr list and a reference context
	;
	; returns:  the computed context.
	;
	; notes:    you can use the output and a !pick-ctx to check the result.
	;
	; tests:    
	;--------------------------
	!computor: processor '!computer [
		vin "!computor/process()"
		
		either all [
			; setup accessors
			object? ctx:   data/1
			block? attrs: data/2
		][	
			
			
			vprint "CTX:"
			vprobe mold/all ctx
			;vprobe words-of ctx
			
			;vprobe length? attrs
			
			
			;--------------
			; set each attr to its loaded type.
			plug/liquid: new-ctx: make ctx []
			
			
			;vprobe words-of new-ctx
			;vprobe mold/all new-ctx

			vprint ">>>>>>>>>>>>>>>>> VALUE ARGS"
			foreach attr attrs [
				
				case [
					attr/computed? [
						; these are ignored in the first pass
					]
					
;					attr/type = 'text! [
;						attr-name: to-word content attr/name
;						set in new-ctx attr-name to string next content attr/value
;						
;						VAL: content attr/value
;						
;						v?? VAL
;						
;					]
					
					attr/name [
						attr-name: to-word content attr/name
						vin to-string attr-name
						
						attr/source: get in ctx attr-name
						blk: attr/update-blk
						bind blk attr
						value: do blk
						;v?? blk
						;v?? attr-name
						v?? value
						
						set in new-ctx attr-name value
						vout
					]
				]
			]
			
			vprint ">>>>>>>>>>>>>>>>>>>> AUTO ARGS"
			
			;-----------------
			; update auto args.
			foreach attr attrs [
				case [
					attr/computed? [
						attr-name: to-word content attr/name
						vin to-string attr-name
						
						bind attr/update-blk attr
						bind attr/source new-ctx
						
						value: do attr/update-blk
						;v?? value
						set in new-ctx attr-name value
						
						vout
					]
				]
			]
			
			;vprint ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
			foreach attr attrs [
				if attr/name [
					a: content attr/name
					value: get in new-ctx to-word a
					;vprobe value
				
					;vout
				]
			]
			
			;vprint "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
			
			
			plug/liquid: new-ctx
			
			;v?? new-ctx
			
		][
		
			plug/liquid: ctx []
		]
		
		vout
	]
	
	
	
	
	;--------------------------
	;- !HEADER:
	;
	; given a value object or a spec block, AND an attr list we return a nice header ready to use in a source file.
	; 
	;--------------------------
	!header: processor '!header [
		vin "!header/process()"
		either 2 <= length? data [
			; allocate or reuse the same header text (eases GC)
			plug/liquid: hdr: head any [plug/liquid copy ""]
			clear hdr
			insert hdr "["
			
			; setup accessors
			ctx:   data/1
			attrs: data/2
			
			; generate the header based on the attr spec and given values.
			foreach attr attrs [
				;vprint "=============================="
				;vprobe attr/type

				switch/default attr/type [
					comment! [
						append hdr rejoin [
							newline "    ; -- " attr/value " --" newline 
						]
					]
					
					block-in! [
						append hdr rejoin [ newline "^-;-  / " attr/value "^/" ]
					]
					
					block-out! [
						append hdr rejoin [ {^-;-  \ } attr/value "^/" ]
					]
					
					lit-word! [
						word: all [
							 attempt [w: load content attr/value]
							 any [
							 	word? w
							 	lit-word? w
							 ]
							 to-word w
						]
						append hdr rejoin [
							tab content attr/name ": '"w newline
						]
					]
					
					date! [
						;-----
						; note: we ignore time zones in date display.
						;-----
						attr-name: to-word content attr/name
						either date? date: attempt [load content attr/value] [
							time: date/time
							date: rejoin [date/year "-" date/month "-" date/day]
							if time [
								append date rejoin [ "/" time ]
							]
							
							append hdr reduce [
								tab content attr/name ": "
								date
								newline
							]
							
						][
							; when its not a date, just add it as a string.
							append hdr reduce [
								tab content attr/name ": "
								mold get in ctx attr-name
								newline
							]
						]
					]
					
					text! string! [
						attr-name: to-word content attr/name
						
						append hdr rejoin [tab content attr/name ": " ]
						
						data:  get in ctx attr-name
						
						either find data "^/" [
							;vprobe data
							data: rejoin ["{" data "}"]
						][
							data: mold data
						]
						;data: rejoin ["{" get in ctx attr-name "}"]
						;v?? data
						replace/all data "^^/" "^/"
						;replace/all data "^^-" "    "
						replace/all data "^^-" "^-"
						if attr/type = 'text! [
							;append hdr "^/"
						]
						append hdr join data "^/"
					]
				][	
					;---------------------
					; named header attribute
					;---
					if attr/name [
						attr-name: to-word content attr/name
						
						append hdr reduce [
							tab content attr/name ": "
							;probe type? ctx
							mold get in ctx attr-name
							
							newline
						]
					]
				]
				
				;vprobe copy/part plug/liquid 100
			]
			append hdr "]^/"
			if hdr/2 <> #"^/" [insert next hdr "^/"]

		][
			plug/liquid: {REBOL [
    ; undefined header
]}
		]
		
		;vprobe copy/part plug/liquid 100
		;vprobe plug/liquid
		;ask "%%%"
	
		vout
	]
	
	
	
	
	
	;--------------------------
	;- !PICK-LINK()
	;--------------------------
	; purpose:  given a switching value (first link), will choose a single other input.
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    currently instigates all inputs, even if it wouldn't have to.
	;
	; tests:    
	;--------------------------
	!pick-link: processor '!pick-link [
		vin "!pick-link()"
		
		index: not not pick data 1
		
		;vprobe data
		;vprobe index
		
		;vprobe pick next data true
		;vprobe pick next data false
		
		
		
		plug/liquid:  attempt [ pick next data  index]
		
		
		;vprobe plug/liquid
		vout
	]
	
	
	
	
	;--------------------------
	;- !PICK-CTX()
	;--------------------------
	; purpose:  pick an object attribute given a ctx and a word.
	;
	; inputs:   
	;
	; returns:  
	;
	; notes:    
	;
	; tests:    
	;--------------------------
	!pick-ctx: processor '!pick-ctx [
		vin "!pick-ctx()"
		
		plug/liquid: all [
			object? ctx: pick data 1
			word?   word: pick data 2
			get in ctx word
		]
		
		;v?? ctx
		;v?? word
		
		;vprobe plug/liquid
			
		vout
	]
	


]
