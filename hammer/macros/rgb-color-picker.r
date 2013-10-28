;------------------------------------------------------
; Adding your own color picker to Hammer!
;------------------------------------------------------
pane-name: to-word random "glirughsoierughsergoih4343573094587" ; we use a random name

set pane-name gl/layout/within/tight compose/deep [
    column tight  (globals/pane-title-color) (globals/pane-title-color) 3x3 [
        column (globals/pane-bg-color) (globals/pane-bg-color)  tight [
            row 1x1 (globals/pane-title-color)(globals/pane-title-color) corner 0 [
                tool-icon #close no-label [gl/unframe ( pane-name )]
                title "Color Picker" left stiff 80x-1 (globals/pane-title-text-color)
            ]
            shadow-hseparator
            row  5x5 [
                rgb-lbl: label stiff 75x75 3 with [
                    actions: make actions [
                        select: func [event][
                            report rejoin ["copied value to clipboard : " content rgb-clr ]
                            write clipboard:// to-string content rgb-clr
                        ]
                    ]
                ]
                column [
                    r-scr: scroller stiff 128x20
                    g-scr: scroller stiff 128x20            
                    b-scr: scroller stiff 128x20
                ]
            ]
        ]
    ]
] 'column


;------------------------------------------------------
; link up scrollers, color box and data converters.
;------------------------------------------------------
r-val: liquify !plug
g-val: liquify !plug
b-val: liquify !plug

fill r-scr/aspects/maximum 259
fill g-scr/aspects/maximum 259
fill b-scr/aspects/maximum 259

attach/to r-val r-scr/aspects/value 'value
attach/to g-val g-scr/aspects/value 'value
attach/to b-val b-scr/aspects/value 'value

rgb-clr: liquify/link processor '!to-color [
    plug/liquid: to-tuple reduce [ data/1 data/2 data/3 ]
] reduce [ r-val g-val b-val ]

link/reset rgb-lbl/aspects/color rgb-clr
link/reset rgb-lbl/aspects/label rgb-clr


;------------------------------------------------------
; Adding an icon which displays the color picker.
;------------------------------------------------------
gl/layout/within compose/deep [
    icon stiff 60x60 #marble "Color" [
        show-pane/side ( pane-name )
    ]
] icon-toolbox

show-pane/side get pane-name


