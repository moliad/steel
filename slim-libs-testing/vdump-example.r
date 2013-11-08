rebol [
	title: "simply illustrates how vdump can map out object and block references."
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
