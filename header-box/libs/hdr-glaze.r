rebol [
	file:       %hdr-glaze.r
	

	;-- slim parameters --
	slim-name:   'hdr-glaze
	slim-prefix:  none
	slim-version: 0.9.11
]


slim/register [

	slim/open/expose 'liquid none [
		!plug 
		liquify 
		content
		fill
		link
		unlink
		detach
		attach
	]
		
	slim/open/expose 'group [ !group ]

	
	
	
	 [
		row [
			edtr: script-editor 
			vscrl: scroller
		]
	] attr-row
	
	
	!text-editor: make group-lib/!group [
	
		mtrl: edtr/material
		spct: edtr/aspects
		
		link/reset vscrl/aspects/maximum mtrl/number-of-lines
		link/reset vscrl/aspects/visible mtrl/visible-lines
		attach/to spct/top-off vscrl/aspects/value 'value
		fill vscrl/aspects/value 0
	]
]