rebol [
	; -- Core Header attributes --
	title: "Fluid tests"
	file: %fluid-tests.r
	version: 1.0.0
	date: 2013-10-18
	author: "Maxim Olivier-Adlhoch"
	purpose: "Fluid library test and example script"
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
		v1.0.0 - 2013-10-18
			-first release should test every function of v1.0.4 of fluid
	}
	;-  \ history

	;-  / documentation
	documentation: ""
	;-  \ documentation
]


;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- LIBS
;
;-----------------------------------------------------------------------------------------------------------

do %../../slim-libs/slim/slim.r

fl: slim/open/expose 'fluid none  [  flow  probe-graph catalogue ]
slim/open/expose 'liquid none [ content fill processor !plug link attach liquify ]
fl/von  ; uncomment to see debug of flow.

slim/vexpose
von


;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUG TYPES
;
;-----------------------------------------------------------------------------------------------------------

; add plug classes to the catalogue, so they can be used within any flow block


;-------------------------
;-    !sum
;
; here we use 'PROCESSOR which is a high-level function from the liquid api which builds plug classes.
;-------------------------
catalogue processor '!sum [
	fx: 0
	plug/liquid: foreach x data [fx: fx + any [all [number? x  x]  0 ]]
]


;-------------------------
;-    !int
;
; the following plug converts its current value to integer
;
; here we use a more low-level approach which uses more RAM but is more Rebol "style compliant" .
;-------------------------
catalogue !int: make !plug [
	valve: make valve [
		type: '!int
		
		purify: func [
			plug
		][
			plug/liquid: to-integer plug/liquid
			false
		]
	]
]
;---
; we tell this plug to use itself as its own pipe server class.
; 
; thus, any pipe being served by this plug will send integers to all of its clients,
; even when filled with something else.
;---
!int/valve/pipe-server-class: !int





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- PLUG INSTANCES
;
;-----------------------------------------------------------------------------------------------------------

p: liquify/fill !plug 100





;-                                                                                                         .
;-----------------------------------------------------------------------------------------------------------
;
;- FLOW EXAMPLES AND TESTS
;
;-----------------------------------------------------------------------------------------------------------
;-    basic flow

vprint ""
vprint "---------------------------------------------"
vprint " basic Flow operations"
vprint "---------------------------------------------"
graph: flow/debug [

	a: #plug  ; liquify (instanciate) a new plug of type !plug (filled with nothing so far)
	a: 10     ; fill value into plug, using previously liquified plug since 'A already exists.
	
	b: 3      ; liquify a mew plug, using default type, and dumping value 3.  This is a basic container.
			  ; this basically imitates the previous two lines into one.

	ref: :b   ; create reference to another plug. (the same plug with two names)
	ref-p: :p ; create reference to external plug. (the plug is not within flow, but exists)
	
	;----
	; thr following creates a new plug class on-the-fly and catalogues it for the rest of THIS flow.
	; once the flow is done, this class is not available anymore.
	;
	; internally, the plug/valve/type is set to !add
	;
	; ideally, you should not use this too often, since it duplicates classes at each call to flow, but
	; in many cases, you create plugs which are only used for one graph, so its handy.
	;
	; it can also be very useful for tools which create, save and load plugs on the fly. this means you can use
	; the flow dialect directly to express all parts of your project.
	;
	; notice that by using /debug, you get the catalogue within FLOW's result graph.
	#add: [
		vin ["adding up: " mold data]
		fx: 0
		plug/liquid: foreach x data [vprobe fx: fx + any [all [number? x  x]  0 ]]
		vout
	]
	
	total: #add    ; allocate an !add plug
	total < a      ; link a couple of plugs to total
	total < b      ;
	
	value: total   ; process 'TOTAL and fill 'VALUE with its result (doesn't copy series data)
				   ; note there is no link or connection between 'TOTAL or 'VALUE
				   
	a: 2           ; note that although 'TOTAL will react to 'A change, 'VALUE will not because its not linked.
	
]
probe-graph graph


;---------------------
;-    subgraphs
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " subgraph manipulations"
vprint "---------------------------------------------"
graph: flow/debug [
	a: 10
	b: 1
	
	t: #sum [a b]  ; create a new !sum and link it to two other plugs, using a subgraph, in one line.
	t2: #sum [ t sum: #sum [a b] #sum [a b] ] ; a more complex subgraph which allocates additional !sum nodes 
												  ; and assigns one of them to the S word in the graph.
	
]
probe-graph graph
	
	
	
	
;---------------------
;-    piping
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " piping manipulations"
vprint "---------------------------------------------"


graph: flow/debug [
	p1: "1"        ; generate three containers.
	p2: "2"
	p3: "3"
	
	p3 | p1 | p2   ; pipe the three containers ( the first plug is used to determine which one provides pipe server )
				   ; at this point they all share the same value
	
	i: #int        ; create an !int type plug
	i: "55"        ; set it to a loadable string
	
	i2: "22"
	i3: "33"
	i | i2 | i3    ; we now pipe values to 'I which will all contain an integer!
	
	ii: #int       ; an alternate just to show differences in pipe server master.
	ii: "66"       
	ii2: "77"      
	ii3: "88"      
	
	ii2 | ii | ii3  ; only 'II will be an integer because the pipe server is not setting int... only it is.
]
probe-graph graph




;---------------------
;-    inline class creation
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " inline plug class creation"
vprint "---------------------------------------------"
graph: flow/debug [
	x: 10
	blk: [ ]
	fx: ( vprobe "tADAM" plug/liquid: to-pair data/1 data/2 ) [ x x ]
	acc: (plug/liquid: data)
	fxx: rejoin [ acc [ x x x fx ] ]
]
probe-graph graph


;---------------------
;-    context merging (in-line binding)
;---------------------
vprint ""
vprint "---------------------------------------------"
vprint " context merging"
vprint "---------------------------------------------"
fl/voff
graph: flow [
	x: 6
]
other-graph: flow [
	x: 6
]

fl/von
obj: context [
	x: 10
	y: 20
	z: 30
]

blah: context [
	a: 1
	b: 2
	c: 3
]

ctx: context [
	gr: blah
]

new-graph: flow/debug [
	; test importing a simple object
	/using obj
	obj-total: #sum [ x y z ]
	
	; test importing a graph
	/using graph
	x: 1
	Y: :x
	
	/probe-graph
	
	; test re-binding to new graph
	/using other-graph
	x: 2
	s: #sum [ x y ]
	
	
	; paths are allowed to import contexts.
	/using ctx/gr
	gr-total: #sum [ a b c ]
]
probe-graph new-graph


ask "..."
