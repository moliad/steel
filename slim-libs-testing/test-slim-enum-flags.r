rebol [
	; -- Core Header attributes --
	title: "Slim flag enum testing"
	file: %test-slim-enum-flags.r
	version: 1.0.0
	date: 2014-5-21
	author: "Maxim Olivier-Adlhoch"
	purpose: {tests the flag enum dialect which helps in integrating C libs}
	web: http://www.revault.org/
	source-encoding: "Windows-1252"

	; -- Licensing details  --
	copyright: "Copyright © 2014 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
	license: {Copyright © 2014 Maxim Olivier-Adlhoch

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
		2013-01-01 - v0.1.0
			-creation of history.
	}
	;-  \ history

	;-  / documentation
	documentation: {
		User documentation goes here
	}
	;-  \ documentation
]




do %../../slim-libs/slim/slim.r

slim/vexpose
von
slim/von

vprint "6666"

flags: enum/flags 'PRFX [
	one    ; 1
	two    ; 2
	three  ; 4
	four   ; 8

	merge1:  one | two ; 3
	merge2 = one OR four ; 9
	
	set1: #FFFF  ; direct hex value (converted internally to an integer)
	five   ; 16
	
	set2 = 10  ; bit number (1024)
	
	eleven   ; 2048
]

vprobe flags

ask "..."