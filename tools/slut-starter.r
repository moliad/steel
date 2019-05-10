#!/usr/bin/rebol

REBOL [
	; -- Core Header attributes --
	title: "Slut launch script"
	file: %slut-starter.r
	version: 1.0.0
	date: 2013-10-26
	author: "Maxim Olivier-Adlhoch"
	purpose: "Slim Unit Testing startup script."
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
		v1.0.0 - 2013-10-26
			-First public release}
	;-  \ history

	;-  / documentation
	documentation: {
		slut is the Unit Testing engine used by Steel.  This is its default unit test launching script.
		
		
		Arguments
		----
		
		Just give the script a file as an argument and it will collect all slut tests and run them.  
		
		If the file has one or more slim startup blocks, then tests within will be bound to their 
		respective library before execution.
		
		This script is used to execute all the unit tests for slim libraries which have them.
		
		
		Inline Test definitions
		----
		
		What makes slut special is that you can put your tests inline within comments of your code.
		
		This has quite a few advantages: 
		
		* tests stay close to the code they are meant to verify so they are easy to relate to what code
		 they actually end up testing.  Usually tests are far away from the code, so it may be quite hard
		 to manually track what test verifies what code.
		 
		* being close means changed code also means updated tests.
		
		* No tests in the code, means no tests... there is no excuse for the old... "oh, I forgot to
		 test that"... a single look at the code tells you if you've added a test for anything.
		
		* Easy to launch tests on the "current" file you are editing which also makes it easy to test
		 while you are changing the code.
		 
		* Easy to write tests while you are writing code .. in fact its so easy, it can even be used
		 to replace REPL testing of you code.  since you can easily define what it should be able to 
		 do before adding the code for it... right as you are coding.
		 
		* When a test fails, you get its line number, so you can instantly jump to the problem code... 
		 no need for any additonal management or tools.
		 
		* Being comments, they have NO execution hit, no binding cost whatsoever.
		
		* If you are using source versioning, the tests stay with the code.  If you are testing a branch,
		 your tests will stay with that branch and will not create any bogus reports.  This means you can
		 immediately edit tests for any new or changed features and they will be testable immediately.
		 
		 Normally, very volatile code will end up being very hard to unit test because the test scripts
		 require to much management and tracking.  It ends up being easy to forget to update the test scripts
		 to/from different branches with different tests and to tag everything EVERY time.
		 
		 There is nothing worse than a unit test report which doesn't actually test the proper code or follow
		 the code's changes.
		
		* People who have Unit testing as their main job will remain close to the source, which also makes it
		 more likely that your developpers will want to interact with them... because they can give 
		 file and line numbers to interact with in the discussion... its not a vague, not my dept, issue.
		 
		* When doing rotating unit testing shifts (devs doing a few hours of tests a week), you are still 
		 looking at the same text files, so you are much more productive.
		
			 
		Test specifications
		----
		
		You should look at the slut.r module within the slim repository for specifics on how to define tests
		
		The best is probably to look within a few slim libraries (mainly the utils-libs) which have quite a
		few tests within them.
		
			 
		
		Report
		----
		
		Once tests are done, it gives you a clean report of what tests passed, which ones failed,
		and possibly those which give you an error message.
		
		note that it gives you the line number and the test count which it finds, so its very easy to track
		your tests within the code.
		
		It also gives you a count of all the tests which passed/failed so you can easily get a bird's eye
		view.
		
		
		
		Slim Setup
		----
		
		Note that you can easily setup slim by adding a file within the root of steel.
		
		slim-path-setup.r will be checked for existence and run whenever it does.  you just need to put
		the path to your slim.r file there.  
		
		This file is part of the steel .gitignore file, so it wont try to commit it back ... 
		i.e. its really local to your installation.
		
		Alternatively, it will try to find slim outside of steel or within steel, if you put it there.
		
		
		
		To do:
		----
		
		* I need to add an argument to allow it to choose which tests to launch from those it collects, since each test is labeled, its easy to chose which ones to launch.
		
		* Add arguments to control what reporting is given.
	}
		
	;-  \ documentation
]



;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------
unless value? 'slim [
	slim-path: clean-path  any [
		all [ exists? %../slim-path-setup.r 		do %../slim-path-setup.r ]
		all [ exists? %../../slim-libs/slim/slim.r  %../../slim-libs/slim/slim.r ] 
		all [ exists? %../slim-libs/slim/slim.r     %../slim-libs/slim/slim.r    ] 
	]

	?? slim-path
	do slim-path
]

slut: slim/open/expose 'slut none [ =extract-tests= ]
slim/vexpose



;-----------------------------------------------------------------------------------------------------------
;
;- MANAGE ARGS
;
;-----------------------------------------------------------------------------------------------------------
args: system/script/args

unless args [
	if args: try [
		rejoin [
			system/script/path
			system/script/header/file
		]
	][
		args: to-local-file args
	]
]

print "========================="
print "test-engine.r arguments:"
probe args
print "========================="



;---
;-    script path
script-path: to-rebol-file args





;-----------------------------------------------------------------------------------------------------------
;
;- MAIN
;
;-----------------------------------------------------------------------------------------------------------

?? script-path

unless exists? script-path [
	to-error ["Unable to test given path: " script-path ]
]

;slut/von
slut/extract script-path

test-results: slut/do-tests;/verbose ;/only [ liquid zdiv-error-test ]

?? test-results


ask "press enter to quit..."

