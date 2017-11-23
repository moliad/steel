#!/usr/bin/rebol

REBOL [
	; -- Core Header attributes --
	title: "Slut launch script"
	file: %slut-starter.r
	version:	2.3.7
	date: 		2015-06-24
	author: "Maxim Olivier-Adlhoch"
	purpose: "Slim Unit Testing startup script."
	web: http://www.revault.org/
	source-encoding: "Windows-1252"

	; -- Licensing details  --
	copyright: "Copyright © 2013 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
	license: {Copyright © 2013 Maxim Olivier-Adlhoch
	limitations under the License.}

	;-  / history
	history: {
		v1.0.0 - 2013-10-26
			-First public release

		v2.3.5 - 2015-06-24
			-h jy yj
	
		v2.3.6 - 2015-06-24
			-b kyg iuy
	
		v2.3.7 - 2015-06-24
			-testing final version of bump.r
	}
	;-  \ history

	;-  / documentation
	documentation: {
		slut is the Unit Testing engine used by Steel.  This is its default unit test launching script.
	}
		
	;-  \ documentation
]



;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------
slim-path: clean-path any [
	all [ exists? %../slim-path-setup.r do read %../slim-path-setup.r ]
	all [ exists? %../../slim-libs/slim/slim.r  %../../slim-libs/slim/slim.r ] 
	all [ exists? %../slim-libs/slim/slim.r     %../slim-libs/slim/slim.r    ] 
]

?? slim-path

do slim-path

slut: slim/open/expose 'slut none [ =extract-tests= ]
slim/vexpose

