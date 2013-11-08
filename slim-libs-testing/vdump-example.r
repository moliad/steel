rebol [
	; -- Core Header attributes --
	title: "script to show slim's vdump capabilities"
	file: %vdump-example.r
	author: "Maxim Olivier-Adlhoch"
	version: 1.0.0
	date: 2013-11-7
	copyright: "Copyright © 2013 Maxim Olivier-Adlhoch"
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
slim/open 'liquid none
von


dataset: context [
	xxx: [
		1 2 3 4 5
	]
	zzz: context [
		cross-reference: xxx
	]
	circular-reference: none
	inner-circular-ref: none
]
dataset/circular-reference: reduce [ dataset 'some-word ]
dataset/inner-circular-ref: context [ myself: self   another: dataset/zzz]

vdump dataset


ask ""
