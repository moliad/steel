rebol [
	title: "bump - quick script maintenance"
	version: 0.0.3
	date: 2015-06-24

	;-  / history
	history: {
		v0.0.1 - 2015-06-24
			-First build of new bump tool
	
		v0.0.2 - 2015-06-24
			-removed some console messaging
	
		v0.0.3 - 2015-06-24
			-removed all library verbosity
	}
	;-  \ history

]


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

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
		all [ exists? steel-root-path/slim-path-setup.r         do read steel-root-path/slim-path-setup.r ]
		all [ exists? steel-root-path/../slim-libs/slim/slim.r          steel-root-path/../slim-libs/slim/slim.r ] 
		all [ exists? steel-root-path/slim-libs/slim/slim.r             steel-root-path/slim-libs/slim/slim.r    ] 
		all [ exists? slim-libs/slim/slim.r             				slim-libs/slim/slim.r    ] 
	]
]


slim/vexpose 


ulib:   slim/open/expose 'utils-script none [ bump-script-version  update-script-date  extend-script-history  get-header-value ]
slim/open/expose 'utils-files none [ directory-of  suffix-of  prefix-of]

;von
;ulib/von




;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- ARGS
;
;-----------------------------------------------------------------------------------------------------------


;system/script/args: "C:\dev\projects\steel\tools\bump-test-script.r"

unless system/script/args [
	print "============================================================"
	print [ "ERROR: must supply a path on command line (in os format)"]
	print "============================================================"
	ask "^/Press enter to close"
]


;probe system/script/args

src-path: to-rebol-file system/script/args 


unless exists? src-path [
	print [ "ERROR: Invalid path, source does not exist.^/" src-path]
]


;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- GLOBALS
;
;-----------------------------------------------------------------------------------------------------------
bump-dir: join (directory-of src-path) %bump-versions/

;probe bump-dir



unless exists? bump-dir [
	make-dir/deep bump-dir
]






;-                                                                                                       .
;-----------------------------------------------------------------------------------------------------------
;
;- VERSION HANDLING
;
;-----------------------------------------------------------------------------------------------------------
;-    extract current version

script: read src-path


bump-script-version script
update-script-date  script


sversion: get-header-value script 'version
bump-path: rejoin [bump-dir   prefix-of src-path  "_v" sversion "." suffix-of src-path ]


comment: ask "=================^/Add history?^/=================^/^/(Just press Enter if you want no comment in history):^/^/> "


unless empty? trim comment [
	extend-script-history  script  comment
]

write bump-path script
write src-path script

;print script

;v?? bump-path

;ask "press enter "


