;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  global-tick-count
  allele-color-types
  allele-size-types
  parasite-size-types
  group-radius]

breed [ phenotypes phenotype ]
breed [ parasites parasite ]

phenotypes-own [ allele11 allele12 allele21 allele22 sex infecting-parasite ]
parasites-own [ age phenotype-host ]

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Setup ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to setup
  clear-all
  ask patches [ set pcolor green ]
  setup-vars
  setup-parasites
  setup-phenotypes
  set global-tick-count 0
  reset-ticks
end

to setup-vars
  set allele-size-types [ 1 3 ]
  set allele-color-types [ blue orange ]
  setup-parasite-size-types
  set group-radius 20
end

to setup-parasite-size-types
  set parasite-size-types []
  foreach allele-size-types [
    let i ?
    foreach allele-size-types [
      let j ?
      set parasite-size-types lput ( ( i + j ) / 2 ) parasite-size-types
    ]
  ]
  set parasite-size-types remove-duplicates parasite-size-types
end

to setup-parasites
  create-parasites carrying-capacity
  [
    initialize-parasite
  ]
end

to initialize-parasite
  set label ""
  set hidden? (not show-parasites)
  set age random parasite-lifespan
  set shape "circle"
  set xcor random-xcor
  set ycor random-ycor
  set color ((one-of allele-color-types) - 2)
  set size (one-of parasite-size-types) / 3
  set phenotype-host nobody
end

to setup-phenotypes
  create-phenotypes carrying-capacity
  [
    set hidden? false
    set label ""
    set infecting-parasite nobody
    set xcor random-xcor
    set ycor random-ycor
    set sex initialize-sex
    set allele11 initialize-color-allele
    set allele12 initialize-color-allele
    set allele21 initialize-size-allele
    set allele22 initialize-size-allele
    set-size-shape-color
  ]
end

to-report initialize-sex
  ifelse random-float 1.0 < sexual-to-asexual-ratio
  [ report coin-flip-sex ][
    report "asexual" ]
end

to-report coin-flip-sex
  ifelse random-float 1.0 < 0.5 [ report "male" ][ report "female" ]
end

to-report initialize-color-allele
  report one-of allele-color-types
end

to-report initialize-size-allele
  report one-of allele-size-types
end

to set-size-shape-color
  set size (allele21 + allele22) / 2
  set shape get-phenotype-shape

  if (position allele11 allele-color-types) < (position allele12 allele-color-types) [
    set color allele12 ]

  if (position allele11 allele-color-types) > (position allele12 allele-color-types) [
    set color allele11 ]

  if (position allele11 allele-color-types) = (position allele12 allele-color-types) [
    set color allele11 ]
end

to-report get-phenotype-shape
  if sex = "asexual" [ report "club" ]
  if sex = "male" [ report "spade" ]
  if sex = "female" [ report "heart" ]
end


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  update-visibility-settings
  ask phenotypes [ hosts-wander ]
  ask parasites [ parasite-wander ]
  ask parasites [ parasite-update-age ]
  update-tick-action
  maintain-host-carrying-capacity
  tick
end

to update-visibility-settings
  ask phenotypes [ set hidden? false ]
  ask parasites [ set hidden? (not show-parasites) ]
end

to parasite-update-age
  set age age + 1
  if age > parasite-lifespan [
    if phenotype-host != nobody [ parasites-reproduce ]
    die
  ]
end

to maintain-host-carrying-capacity
  repeat (count phenotypes - carrying-capacity) [ ask one-of phenotypes [ remove-phenotype ] ]
end

to update-tick-action
  if reproduce-every > 0 [
    ifelse global-tick-count <= reproduce-every [
      set global-tick-count global-tick-count + 1
    ][
    set global-tick-count 0
    execute-reproduce
    ]
  ]
end

to execute-reproduce
  let old-phenotype-group phenotypes
  ask old-phenotype-group [
    if [infecting-parasite] of self = nobody [
      if [sex] of self = "asexual" [ ask self [ hosts-reproduce-asexually ]]
      if [sex] of self = "female" [ ask self [ hosts-reproduce-sexually ]]
    ]
  ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Agent Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to hosts-wander
  right random 90
  left random 90
  fd .3
end

to parasite-wander
  right random 90
  left random 90
  fd 1
  attempt-infection
end

to attempt-infection
  ask phenotypes-on patch-here [
    let matching? (color = ([color] of myself + 2)) and (size = ([size] of myself * 3))
    if matching? and infecting-parasite = nobody [
      if random-float 1.0 < parasite-infectivity [
        set infecting-parasite myself
        ask infecting-parasite [ set phenotype-host myself ]
      ]
    ]
  ]
end

to parasites-reproduce
  hatch-parasites offspring-per-parasite
  [
    set age 0
    set phenotype-host nobody
    if random-float 1.0 < parasite-mutation-rate [
      initialize-parasite
      set xcor [xcor] of self
      set ycor [ycor] of self
    ]
  ]
  ask phenotype-host [ remove-phenotype ]
end

to hosts-reproduce-asexually
  hatch-phenotypes offspring-per-female [
    hosts-update-for-mutation
    set-size-shape-color
  ]
end

to hosts-reproduce-sexually
  let eligible-males phenotypes in-radius group-radius with [ sex = "male" ]

  if any? eligible-males [
    let mate one-of eligible-males

    hatch-phenotypes offspring-per-female [

      let a11List []
      set a11List lput allele11 a11List
      set a11List lput ([allele11] of mate) a11List
      set allele11 one-of a11List

      let a12List []
      set a12List lput allele12 a12List
      set a12List lput ([allele12] of mate) a12List
      set allele12 one-of a12List

      let a21List []
      set a21List lput allele21 a21List
      set a21List lput ([allele21] of mate) a21List
      set allele21 one-of a21List

      let a22List []
      set a22List lput allele22 a22List
      set a22List lput ([allele22] of mate) a22List
      set allele22 one-of a22List

      set sex coin-flip-sex
      hosts-update-for-mutation
      set-size-shape-color
    ]
  ]
end

to hosts-update-for-mutation
  if random-float 1.0 < host-mutation-rate [
    set allele11 initialize-color-allele ]
  if random-float 1.0 < host-mutation-rate [
    set allele12 initialize-color-allele ]
  if random-float 1.0 < host-mutation-rate [
    set allele21 initialize-size-allele ]
  if random-float 1.0 < host-mutation-rate [
    set allele22 initialize-size-allele ]
  if random-float 1.0 < host-mutation-rate [
    set sex initialize-sex ]
end

to remove-phenotype
  if infecting-parasite != nobody [ ask infecting-parasite [ die ] ]
  die
end

@#$#@#$#@
GRAPHICS-WINDOW
232
53
698
540
-1
-1
11.122
1
10
1
1
1
0
1
1
1
0
40
0
40
1
1
1
ticks
30.0

BUTTON
324
11
402
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
239
11
316
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
8
219
222
237
------------ Mutation --------------
11
0.0
1

TEXTBOX
9
318
235
336
--------- Natural Selection ----------
11
0.0
1

TEXTBOX
10
123
229
151
----------- Reproduction -----------
11
0.0
1

SLIDER
8
237
219
270
host-mutation-rate
host-mutation-rate
0
1.0
0.05
.01
1
NIL
HORIZONTAL

SLIDER
9
141
220
174
sexual-to-asexual-ratio
sexual-to-asexual-ratio
0
1.0
0.5
.01
1
NIL
HORIZONTAL

SLIDER
9
181
221
214
offspring-per-female
offspring-per-female
0
10
3
1
1
NIL
HORIZONTAL

PLOT
1034
286
1355
534
Sexual Phenotype Frequencies
time
number of individuals
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"blue-small" 1.0 0 -8020277 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 1) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"
"blue-medium" 1.0 0 -13345367 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 2) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"
"blue-large" 1.0 0 -14730904 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 3) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"
"orange-small" 1.0 0 -612749 true "" "plot 100 * (count phenotypes with [ (color = orange ) and (size = 1) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"
"orange-medium" 1.0 0 -955883 true "" "plot 100 * (count phenotypes with [ (color = orange) and (size = 2) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"
"orange-large" 1.0 0 -6995700 true "" "plot 100 * (count phenotypes with [ (color = orange ) and (size = 3) and (sex != \"asexual\")] / (count phenotypes with [sex != \"asexual\"] + 0.00000001))"

PLOT
709
286
1028
534
Asexual Phenotype Frequencies
time
number of individuals
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"blue-small" 1.0 0 -8020277 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 1) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"
"blue-medium" 1.0 0 -13345367 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 2) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"
"blue-large" 1.0 0 -14730904 true "" "plot 100 * (count phenotypes with [ (color = blue ) and (size = 3) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"
"orange-small" 1.0 0 -612749 true "" "plot 100 * (count phenotypes with [ (color = orange ) and (size = 1) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"
"orange-medium" 1.0 0 -955883 true "" "plot 100 * (count phenotypes with [ (color = orange ) and (size = 2) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"
"orange-large" 1.0 0 -6995700 true "" "plot 100 * (count phenotypes with [ (color = orange ) and ( size = 3 ) and (sex = \"asexual\")] / (count phenotypes with [sex = \"asexual\"] + 0.00000001))"

BUTTON
411
11
522
44
reproduce now
execute-reproduce
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
529
11
692
44
reproduce-every
reproduce-every
0
100
50
1
1
ticks
HORIZONTAL

INPUTBOX
13
58
223
118
carrying-capacity
200
1
0
Number

SLIDER
7
414
221
447
parasite-lifespan
parasite-lifespan
0
100
15
1
1
ticks
HORIZONTAL

SLIDER
8
376
220
409
parasite-infectivity
parasite-infectivity
0
1.0
0.15
.01
1
NIL
HORIZONTAL

SLIDER
8
337
221
370
offspring-per-parasite
offspring-per-parasite
1
200
100
1
1
NIL
HORIZONTAL

SLIDER
7
277
220
310
parasite-mutation-rate
parasite-mutation-rate
0
1.0
0.2
.01
1
NIL
HORIZONTAL

SWITCH
7
453
220
486
show-parasites
show-parasites
1
1
-1000

PLOT
1034
23
1355
278
Parasite Phenotype Frequencies
time
number of individuals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"blue-small" 1.0 0 -8020277 true "" "plot 100 * (count parasites with [ (color = blue - 2) and (size = 1 / 3)] / ((count parasites) + 0.00000001))"
"blue-medium" 1.0 0 -13345367 true "" "plot 100 * (count parasites with [ (color = blue - 2) and (size = 2 / 3)] / ((count parasites) + 0.00000001))"
"blue-large" 1.0 0 -14730904 true "" "plot 100 * (count parasites with [ (color = blue - 2) and (size = 3 / 3)] / ((count parasites) + 0.00000001))"
"orange-small" 1.0 0 -612749 true "" "plot 100 * (count parasites with [ (color = orange - 2) and (size = 1 / 3)] / ((count parasites) + 0.00000001))"
"orange-medium" 1.0 0 -955883 true "" "plot 100 * (count parasites with [ (color = orange - 2) and (size = 2 / 3)] / ((count parasites) + 0.00000001))"
"orange-large" 1.0 0 -6995700 true "" "plot 100 * (count parasites with [ (color = orange - 2) and (size = 3 / 3)] / ((count parasites) + 0.00000001))"

TEXTBOX
12
42
230
60
------------ Population -------------
11
0.0
1

PLOT
709
23
1028
278
Sexual vs Asexual Strategies
time
number of individuals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"asexual" 1.0 0 -4539718 true "" "plot 100 * ((count phenotypes with [ sex = \"asexual\" ]) / (count phenotypes + 0.00000001 ))"
"sexual" 1.0 0 -11053225 true "" "plot 100 * ((count phenotypes with [ sex != \"asexual\" ]) / (count phenotypes + 0.00000001 ))"

TEXTBOX
83
17
180
39
SETTINGS
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

Version 1.07

## HOW TO USE IT


## THINGS TO NOTICE


## THINGS TO TRY


## COPYRIGHT AND LICENSE

Copyright 2016 K N Crouse.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

club
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122

club 0
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -16777216 true false 88 103 124

club 105
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13345367 true false 88 103 124

club 115
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -8630108 true false 88 103 124

club 125
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -5825686 true false 88 103 124

club 135
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2064490 true false 88 103 124

club 15
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2674135 true false 88 103 124

club 25
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -955883 true false 88 103 124

club 35
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -6459832 true false 88 103 124

club 45
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1184463 true false 88 103 124

club 55
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -10899396 true false 88 103 124

club 65
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13840069 true false 88 103 124

club 75
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -14835848 true false 88 103 124

club 85
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -11221820 true false 88 103 124

club 9.9
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1 true false 88 103 124

club 95
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13791810 true false 88 103 124

heart
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

heart 0
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -16777216 true false 86 71 127

heart 105
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13345367 true false 86 71 127

heart 115
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -8630108 true false 86 71 127

heart 125
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -5825686 true false 86 71 127

heart 135
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2064490 true false 86 71 127

heart 15
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2674135 true false 86 71 127

heart 25
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -955883 true false 86 71 127

heart 35
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -6459832 true false 86 71 127

heart 45
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1184463 true false 86 71 127

heart 55
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -10899396 true false 86 71 127

heart 65
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13840069 true false 86 71 127

heart 75
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -14835848 true false 86 71 127

heart 85
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -11221820 true false 86 71 127

heart 9.9
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1 true false 86 71 127

heart 95
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13791810 true false 86 71 127

spade
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210

spade 0
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -16777216 true false 83 98 134

spade 105
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13345367 true false 83 98 134

spade 115
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -8630108 true false 83 98 134

spade 125
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -5825686 true false 83 98 134

spade 135
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2064490 true false 83 98 134

spade 15
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2674135 true false 83 98 134

spade 25
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -955883 true false 83 98 134

spade 35
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -6459832 true false 83 98 134

spade 45
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1184463 true false 83 98 134

spade 55
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -10899396 true false 83 98 134

spade 65
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13840069 true false 83 98 134

spade 75
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -14835848 true false 83 98 134

spade 85
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -11221820 true false 83 98 134

spade 9.9
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1 true false 83 98 134

spade 95
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13791810 true false 83 98 134

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
238
104
666
535
0
0
0
1
1
1
1
1
0
1
1
1
0
40
0
40

BUTTON
91
87
153
120
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
91
153
153
186
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
153
120
215
153
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
29
120
91
153
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
146
12
243
61
LOCATED AT:
NIL
3
1

MONITOR
17
12
136
61
YOU ARE GROUP:
NIL
3
1

MONITOR
361
12
503
61
ADJACENT GROUP:
NIL
3
1

BUTTON
522
13
649
62
reproduce now
NIL
NIL
1
T
OBSERVER
NIL
R

MONITOR
253
12
350
61
GENERATION:
NIL
3
1

MONITOR
124
198
225
247
asexual %
NIL
5
1

MONITOR
124
252
225
301
sexual %
NIL
3
1

MONITOR
124
306
225
355
allele one %
NIL
3
1

MONITOR
17
306
117
355
allele one count
NIL
3
1

MONITOR
124
361
225
410
allele two %
NIL
3
1

MONITOR
17
361
117
410
allele two count
NIL
3
1

MONITOR
124
415
226
464
allele three %
NIL
3
1

MONITOR
17
415
117
464
allele three count
NIL
3
1

MONITOR
124
469
226
518
allele four %
NIL
3
1

MONITOR
17
469
117
518
allele four count
NIL
3
1

MONITOR
17
198
117
247
asexual count
NIL
3
1

MONITOR
17
252
117
301
sexual count
NIL
3
1

TEXTBOX
19
67
661
85
----------------------------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
48
515
198
533
NIL
11
0.0
1

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
