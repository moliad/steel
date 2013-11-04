rebol [

]

;-------------------------
; setup globals
;-------------------------
root-dir: join what-dir %slim-libs/

git-connection-mode: 'ssh

git-url-base: switch git-connection-mode [
	ssh [
		"git@github.com:moliad/" 
	]
	
	https [
		"https://github.com/moliad/" 
	]
]



;--------------------------
;- get-slim-package()
;--------------------------
get-slim-package: func [
	package
][
	print "^/^/---"
	print "pull-project()"
	
	path: rejoin [ root-dir package ]
	?? path
	
	either exists? path [
		print ["UPDATING " package ]
		cmd: "git pull origin "
		change-dir path
		?? cmd
		call/show/console/wait cmd
	][
		print ["CLONING " package "" ]
		cmd: rejoin [ "git clone " git-url-base  package ".git" ]
		;make-dir path
		change-dir root-dir
		?? cmd
		call/show/console/wait cmd
	]
]




;-------------------------
; grab all the stuff from Github
;-------------------------
make-dir root-dir

foreach package [ glass-libs  liquid-libs  misc-libs  utils-libs  slim  win32-libs ] [
	get-slim-package package
]

ask "all done"


