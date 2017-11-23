rebol [

]


SLIM-DEBUG-PROFILE-FUNCL: true


steel-root-path: clean-path %../

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
		all [ exists? steel-root-path/slim-path-setup.r         do read steel-root-path/slim-path-setup.r ]
		all [ exists? steel-root-path/../slim-libs/slim/slim.r          steel-root-path/../slim-libs/slim/slim.r ] 
		all [ exists? steel-root-path/slim-libs/slim/slim.r             steel-root-path/slim-libs/slim/slim.r    ] 
	]
]


slim/vexpose

slim/von



;--------------------------
;-     a()
;--------------------------
a: funcl [
	msg
][
	vin "a()"
	vprint msg
	vout
]


;--------------------------
;-     b()
;--------------------------
b: funcl [
	msg
][
	vin "b()"
	vprobe msg
	vout
	msg
]



a 'test
a 77

probe b 888
a b "return value test"



slim-debugger/profiler/stats/limit 3

ask "..."
