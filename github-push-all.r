rebol [

]


root-dir: what-dir

foreach repo [ glass-libs  liquid-libs  misc-libs  utils-libs  slim  win32-libs ] [
	print ["pulling " repo ]
	change-dir join root-dir repo
	cmd: " git push origin "
	call/shell/console/wait cmd
]

ask "all done"


