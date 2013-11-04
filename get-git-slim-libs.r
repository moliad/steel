rebol [
	; -- Core Header attributes --
	title: "Git clone tool for slim libs"
	file: %get-git-slim-libs.r
	version: 0.9.0
	date: 2013-11-4
	author: "Maxim Olivier-Adlhoch"
	purpose: {Easily downloads all slim libraries from a Git server to your system.}
	web: http://www.revault.org/
	source-encoding: "Windows-1252"

	; -- Licensing details  --
	copyright: "Copyright © 2013 Maxim Olivier-Adlhoch"
	license-type: "Apache License v2.0"
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

	;-  / history
	history: {
		v0.0.1 - 2013-10-25
			-first public release

		v0.9.0 - 2013-11-04
			-RENAMED SCRIPT TO get-git-slim-libs.r (was get-git-slim-libs.r)
			-Now doesn't assume Github is always used, but only has setup for it by default.
			-added header and some notes about how to shift to https download
			-Now checks to see if we should download in same folder or a slim-libs sub-folder.
			-Added 'SET-GIT-URL  function
			-Added argument handling to force https or ssh modes (currently uses Github).
			-Added -no-ask argument , prevents asking for confirmation when launching.
			-Added -log  option
			-Added -shell option
			-Added -only option
			-Added -help option
			-Added formatted a lot of documentation, including command line examples.
			
	}
	;-  \ history

	;-  / documentation
	documentation: {
        
    get-git-slim-libs.r
    
    
    USAGE:
    ======
        Run this script through Rebol, to easily manage the retreival 
        and update of all or some of the slim libraries
        
        We currently assume that Github is used as the main repository 
        for Slim.
        
        This may change (or have forks),in the future, at which point, 
        there will be additional options.
    
    
    
    NOTES:
    ======
        Its useful to use the -qs options For Rebol itself since it will 
        prevent the requestor which asks for permission to open external 
        commands.
        
        The -shell option should usually work, but some circumstances 
        may cause it to fail. I use the non -shell mode by default, to be 
        sure, the defaults always allow downloads.
        
        All options are compatible, even if it may create weird use cases:
        
       		like   -log -help .  :-)
	        using  -log  without  -no-ask  option.  :-)
        
        Double clicking on the icon in windows, when Rebol is associated 
        with the .r file type, will work automatically.
        
        The default options download all packages, show prompts, Displays 
        external Dos shell windows and prints all activity
        in the Rebol Console.
        
    
    ARGS:  
    ======
        -https  : Force https for xfer

        -ssh    : Force ssh for xfer, ssh is the current default mode.
        
        -no-ask : Don't ask for confirmation before launching Git 
                  Transfers.
        
        -log    : Log output to file instead of console, note that we 
                  *only* accept Rebol syntax paths.
                  
                  Also note that the-log parameter REQUIRES a path 
                  or else an error is raised.
                  
        -shell  : Try to use Git in shell mode, if it works in your setup 
                  (stops showing a DOS console, but may fail 
                  and hang without warning)
                  
        -only   : Only Get given packages. 
                  Note: this allows you get other moliad repositories  
                  that are not in list of slim pacakages, like glass 
                  documentation !
                  
        -help   : Displays this help on the command-line and ends 
                  immediately.
        
        
    EX:
    ======
        rebol -qs get-git-slim-libs.r
        rebol -qs get-git-slim-libs.r -no-ask -log %git-slim.log
        rebol -qs get-git-slim-libs.r -only slim
        rebol -qs get-git-slim-libs.r -only [slim misc-libs]
        rebol -qs get-git-slim-libs.r shell -no-ask -log %slim-git.log
    
	}
	;-  \ documentation
]





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- SETUP GLOBALS
;
;-----------------------------------------------------------------------------------------------------------
;--------------------------
;-     root-dir:
;
; where do we dump the slim packages (folders with modules in them)
;
; note:  this is setup later.
;--------------------------
root-dir: none

;--------------------------
;-     git-connection-mode:
;
; how to connect to git, based on 'SET-GIT-URL setups.
;--------------------------
git-connection-mode: 'ssh


;--------------------------
;-     git-url-base:
;
; the url to use for connecting to Git  
;--------------------------
git-url-base: none


;--------------------------
;-     confirm?:
;
; should we ask for confirmation before starting git transfers
;
; we confirm by default... use -no-ask option to skip confirmation.
;--------------------------
confirm?: true


;--------------------------
;-     shell-cmd?:
;
; use /shell mode for CALL function instead of /SHOW
;--------------------------
shell-cmd?: none


;--------------------------
;-     log?:
;
; should we log to file, instead of printing on console?
;--------------------------
log?: false



;--------------------------
;- package-list:
;
; what packages to get on Git server
;
; these can be changed using -only argument
;--------------------------
package-list: [ slim  utils-libs  misc-libs  liquid-libs  glass-libs  win32-libs ]


;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- GET & PARSE COMMAND-LINE ARGUMENTS
;
;-----------------------------------------------------------------------------------------------------------

args: any [system/script/args ""]

parse/all args [
	some [
		  ["-http" opt "s" [" " | end]] ( git-connection-mode: 'https )
		| ["-ssh"          [" " | end]] ( git-connection-mode: 'ssh )
		| ["-no-ask"       [" " | end]] ( confirm?: false )
		| ["-shell"        [" " | end]] ( shell-cmd?: true )
		| ["-help"         [" " | end]] ( print system/script/header/documentation  ask "^/^/Press 'Enter' or 'Return' to Quit, 'Escape' to Halt into Rebol Interpreter")
		| ["-log " ; note trailing space
			here: there: ; if the value after -log is invalid, we continue here.
			(
				;print "LOG!!"
				either all [
					attempt [data: load/next here]
					not empty? data
					there: second data ; continue after next token... good or bad (-log REQUIRES one parameter).
					file? first data
					#"/" <> last first data ; cannot be a dir path.
				][
					;---
					; sets path to log to.
					;
					log?: clean-path first data 
					
					;---
					; we replace print function, so all prints go to file instead.
					;
					; note that this doesn't affect the 'PRIN func and those which use it ... like 'ASK
					;
					print: func [
						data
					][
						write/append log? join reform data "^/"
					]
				][
					Print  rejoin ["ERROR: Invalid parameter to -Log option:^/(must be Rebol formatted Filepath, must not be folder path): " mold pick any [data [] ] 1]
					halt
				]
			)
		  ] :there

		| [ "-only " ; note trailing space
			here: there: ; if the value after -only is invalid, we continue here.
			(
				either all [
					attempt [data: load/next here]
					not empty? data
					there: second data ; continue after next token... good or bad (-only REQUIRES one parameter).
					any [
						block? first data
						word? first data
					]
				][
					package-list: compose [ (first data) ]
					foreach package package-list [
						unless word? package [
							Print  rejoin ["ERROR: Invalid parameter to -only option^/(must be word or block of words): " mold pick any [data [] ] 1]
							halt
						]
					]
				][
					Print  rejoin ["ERROR: Invalid parameter to -only option^/(must be word or block of words): " mold pick any [data [] ] 1]
					halt
				]
			)
		  ] :there

	
		| here: thru " " (print ".")
	]
]

;if log? [
;]

;print ["haha: " data]
;?? data
;print "test"
;
;probe "?"
;ask ">>>>>>>>>>"
;
;quit

;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- FUNCTIONS
;
;-----------------------------------------------------------------------------------------------------------


;--------------------------
;-     set-git-url()
;--------------------------
; purpose:  given a mode, returns the root Git url to use.
;
; inputs:   Git protocol to use
;
; returns:  Url as a string
;--------------------------
set-git-url: func [
	mode [word!]
][
	switch mode [
		ssh   [ "git@github.com:moliad/" ]
		https [ "https://github.com/moliad/" ]
	]	
]






;--------------------------
;-     get-slim-package()
;--------------------------
get-slim-package: func [
	package
][
	print "^/^/---"
	print ["get-slim-package(" package ")" ]
	
	path: rejoin [ root-dir package ]
	?? path
	
	
;	buffer: either log? [
;		log?
;	][
	buffer: make string! 20'000
;	]
	
	either exists? path [
		print ["UPDATING Existing package" ]
		cmd: "git pull origin "
		change-dir path
	][
		print ["CLONING New package" ]
		cmd: rejoin [ "git clone " git-url-base  package ".git" ]
		change-dir root-dir
		?? cmd
	]
	
	either shell-cmd? [
		call/shell/output/error/wait cmd buffer buffer
	][
		;---
		; we have to use the annoying /show refinement to make it safe in all situations...
		; some ways of launching Rebol do not work properly with /shell, when it is used, unfortunately.
		call/show/output/error/wait cmd buffer buffer
	]
	;prin buffer
	;ask "HAHA!"
	print buffer
]






;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- MAIN LOOP
;
;-----------------------------------------------------------------------------------------------------------



print "===================================="
print ["  " system/script/header/title "^/" ]
print ["        script:" mold system/script/header/file ]
print ["       version:" mold system/script/header/version ]
print ["  command-line:" any [ system/script/args {""}] ]
print ["          time:" now/date  now/time ]
print "^/====================================^/"



;--------------------------
;-     root-dir:
;
; where do we dump the slim packages (folders with modules in them)
;--------------------------
print "setting up...^/^/"

script-dir: what-dir
print ["    script dir: " to-local-file script-dir ]

either (rev-dir: reverse %/slim-libs/) = ( copy/part ( reverse copy script-dir ) length? rev-dir ) [
	print "                 (Running within an existing slim-libs folder)"
	root-dir: script-dir
][
	print "                 (Running above the slim libs folder)"  ; (or will be, once we're done, since this is a new install.)
	root-dir: join what-dir %slim-libs/
]

print ["^/ slim root dir: " to-local-file root-dir ]


;-------------------------
;-     setup the url to use
;-------------------------
git-url-base: set-git-url git-connection-mode



;-------------------------
;-     finish pre-launch report and wait for user to confirm (maybe prevented on command-line)
;-------------------------

print ["^/  git url base: " git-url-base "(" uppercase to-string git-connection-mode "mode )" ]
print "^/^/^/"

if confirm? [
	ask "^/Press 'Enter' or 'Return' to continue, 'Escape' to Halt into Rebol Interpreter ..."
]


;-------------------------
;-     grab all the stuff from Github
;-------------------------
make-dir root-dir

foreach package package-list [
	get-slim-package package
]


either confirm? [
	print "^/^/^/All Done^/"
	ask   "^/Press 'Enter' or 'Return' to Quit ...^/"
][
	print "-------------^/^/get-git-slim-libs.r - All Done"
]


