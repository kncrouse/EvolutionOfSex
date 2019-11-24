;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  allele-color-types
  allele-size-types
  parasite-size-types
  global-tick-count
  individuals-per-group
  group-radius
  parasites-per-group
  color-allele-dominance]

breed [ phenotypes phenotype ]
breed [ groups group ]
breed [ alleles allele ]
breed [ parasites parasite ]

groups-own [ user-id phenotype-group parasite-group generation-number gene-flow-group ]
phenotypes-own [ parent-group a11 a12 a21 a22 sex infecting-parasite ]
alleles-own [ parent-phenotype allele-type ]
parasites-own [ age host-type parent-group phenotype-host ]

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Setup ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to setup
  clear-all
  ask patches [ set pcolor green ]
  setup-vars
  repeat number-of-groups [ create-new-group ]
  set global-tick-count 0
  reset-ticks
end

to setup-vars
  set allele-size-types [ 1 3 ]
  set allele-color-types [ "blue" "orange" ]
  set parasite-size-types [ 1 2 3 ]
  set color-allele-dominance "dominant-recessive"
  set individuals-per-group 30
  set group-radius 15
  set parasites-per-group 30
end


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                   CREATE A GROUP AND SET PARAMETERS                        ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-new-group
  create-groups 1
  [
    setup-group-vars
  ]
end

to setup-group-vars
  move-to one-of patches
  face one-of neighbors4
  set phenotype-group []
  set parasite-group []
  set hidden? true
  set generation-number 0
  set gene-flow-group nobody
  create-phenotype-group
  create-parasite-group
end


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                   CREATE A PARASITES AND SET PARAMETERS                    ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-parasite-group
  let parent self
  hatch-parasites parasites-per-group
  [
    set parent-group parent
    initialize-parasite
  ]
end

to initialize-parasite
  set label ""
  set shape "circle"
  set color (read-from-string (one-of allele-color-types) - 2)
  set xcor (xcor + random-float group-radius - random-float group-radius)
  set ycor (ycor + random-float group-radius - random-float group-radius)
  set size (one-of parasite-size-types) / 3
  ask parent-group [ set parasite-group lput myself parasite-group ]
  set phenotype-host nobody
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A PHENOTYPE INDIVIDUALS OF group AND SET PARAMETERS           ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-phenotype-group
  let parent self
  hatch-phenotypes individuals-per-group
  [
    set sex initialize-sex
    set a11 initialize-color-allele
    set a12 initialize-color-allele
    set a21 initialize-size-allele
    set a22 initialize-size-allele
    set hidden? false
    set label ""
    set parent-group parent
    set infecting-parasite nobody
    set xcor (xcor + random-float group-radius - random-float group-radius)
    set ycor (ycor + random-float group-radius - random-float group-radius)
    ask parent [ set phenotype-group lput myself phenotype-group ]
    set-size-shape-color
  ]
end

to set-size-shape-color
  set size (([size] of a21) + ([size] of a22)) / 2

  if color-allele-dominance = "recessive-dominant" [
    set shape get-phenotype-shape
    set color [color] of a12 ]
  if color-allele-dominance = "dominant-recessive" [
    set shape get-phenotype-shape
    set color [color] of a11 ]
  if color-allele-dominance = "codominant" [
    set shape word get-phenotype-shape word " " [color] of a12
    set color [color] of a11 ]

  set shape get-phenotype-shape
  set color [color] of a11
end

to-report get-phenotype-shape
  if sex = "asexual" [ report "club" ]
  if sex = "male" [ report "spade" ]
  if sex = "female" [ report "heart" ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                      CREATE ALLELES AND SET PARAMETERS                     ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to-report initialize-sex
  ifelse random-float 1.0 < sexual-to-asexual-ratio [
    report coin-flip-sex
  ][
    report "asexual"
  ]
end

to-report coin-flip-sex
  ifelse random-float 1.0 < 0.5 [ report "male" ][ report "female" ]
end

to-report initialize-color-allele
  let parent self
  let new-allele nobody
  hatch-alleles 1 [
    set size 1.0
    set label ""
    set hidden? true
    set shape "circle"
    set color read-from-string one-of allele-color-types
    set new-allele self
    set parent-phenotype parent
  ]
  report new-allele
end

to-report initialize-size-allele
  let parent self
  let chosen-allele one-of allele-size-types
  let new-allele nobody
  hatch-alleles 1 [
    set label ""
    set shape "circle"
    set hidden? true
    set allele-type chosen-allele
    set size allele-type
    set color scale-color grey size 0 3
    set new-allele self
    set parent-phenotype parent
  ]
  report new-allele
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  update-visibility-settings
  update-tick-action
  ask phenotypes [ wander update-allele-positions ]
  ask parasites [ wander attempt-infection ]
  ask parasites [
    set age age + 1
    if age > parasite-lifespan [
      if phenotype-host != nobody [ask phenotype-host [ reproduce-parasites remove-phenotype ]]
      die
      ]]
  repeat (count phenotypes - carrying-capacity) [ ask one-of phenotypes [ remove-phenotype ] ]
  tick
end

to update-tick-action
  if reproduce-every > 0 [
    ifelse global-tick-count <= reproduce-every [
      set global-tick-count global-tick-count + 1
    ][
      set global-tick-count 0
      ask groups [execute-reproduce ]
    ]
  ]
end

to update-visibility-settings
  ask phenotypes [ set hidden? false ]
  ask alleles [ set hidden? true ]
  ask parasites [ set hidden? (not show-parasites) ]
end

to execute-reproduce
  set generation-number generation-number + 1
  let old-phenotype-group phenotype-group
  foreach old-phenotype-group [
    if [infecting-parasite] of ? = nobody [
      ;if count phenotypes < carrying-capacity + length old-phenotype-group [
        if [sex] of ? = "asexual" [ ask ? [ reproduce-asexually ]]
        if [sex] of ? = "female" [ ask ? [ reproduce-sexually ]]
      ;]
    ] ;[ ask ? [ reproduce-parasites ] ]
  ]
  ;foreach old-phenotype-group [ ask ? [remove-phenotype ]]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Agent Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to wander
    let new-patch nobody
    ask parent-group [
      set new-patch one-of patches in-radius group-radius
    ]
    face new-patch
    fd 1
end

to update-allele-positions
  ask a11 [ move-to one-of [neighbors] of myself ]
  ask a12 [ move-to one-of [neighbors] of myself ]
  ask a21 [ move-to one-of [neighbors] of myself ]
  ask a22 [ move-to one-of [neighbors] of myself ]
end

to attempt-infection
  if count phenotypes-on patch-here > 0 [
    let potential-host one-of phenotypes-on patch-here
    let matching? matching-phenotype? potential-host
    if matching? and [infecting-parasite] of potential-host = nobody [
      if random-float 1.0 < parasite-infectivity [
        set phenotype-host potential-host
        ask phenotype-host [ set infecting-parasite myself ]
      ]
    ]
  ]
end

to reproduce-parasites
  ask infecting-parasite [
    hatch-parasites offspring-per-parasite
    [
      set age 0
      set phenotype-host nobody
      ask parent-group [ set parasite-group lput myself parasite-group ]
      if random-float 1.0 < parasite-mutation-rate [ initialize-parasite ]
    ]]
end

to-report matching-phenotype? [ pheno ]
  let color-boolean [color] of pheno = (color + 2)
  let size-boolean [size] of pheno = (size * 3)
  report color-boolean and size-boolean
end

to reproduce-asexually
  hatch-phenotypes offspring-per-female [
    let me self
    ask parent-group [ set phenotype-group lput myself phenotype-group ]
    ask a11 [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set a11 myself ]]]
    ask a12 [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set a12 myself ]]]
    ask a21 [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set a21 myself ]]]
    ask a22 [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set a22 myself ]]]
    update-for-mutation
    set-size-shape-color
  ]
end

to reproduce-sexually
  let eligible-males get-eligible-males
  let mate nobody
  if length eligible-males > 0 [ set mate one-of eligible-males ]

  if mate != nobody [
    hatch-phenotypes offspring-per-female [
      let me self
      ask parent-group [ set phenotype-group lput myself phenotype-group ]

      let first-allele-set []
      set first-allele-set lput a11 first-allele-set
      set first-allele-set lput a12 first-allele-set
      set first-allele-set lput [a11] of mate first-allele-set
      set first-allele-set lput [a12] of mate first-allele-set

      ask one-of first-allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set a11 myself ]]]
      ask one-of first-allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set a12 myself ]]]

      let second-allele-set []
      set second-allele-set lput a21 second-allele-set
      set second-allele-set lput a22 second-allele-set
      set second-allele-set lput [a21] of mate second-allele-set
      set second-allele-set lput [a22] of mate second-allele-set

      ask one-of second-allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set a21 myself ]]]
      ask one-of second-allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set a22 myself ]]]

      set sex coin-flip-sex
      set label ""
      update-for-mutation
      set-size-shape-color
    ]
  ]
end

to update-for-mutation
  if random-float 1.0 < host-mutation-rate [
    ask a11 [ die ]
    set a11 initialize-color-allele ]
  if random-float 1.0 < host-mutation-rate [
    ask a12 [ die ]
    set a12 initialize-color-allele ]
  if random-float 1.0 < host-mutation-rate [
    ask a21 [ die ]
    set a21 initialize-size-allele ]
  if random-float 1.0 < host-mutation-rate [
    ask a22 [ die ]
    set a22 initialize-size-allele ]
  if random-float 1.0 < host-mutation-rate [ set sex initialize-sex ]
end

to-report get-eligible-males
  let eligible-males []

  ; GATHERS ALL MALES IN GROUP
  foreach (([phenotype-group] of parent-group)) [
    if [sex] of ? = "male" [
      set eligible-males lput ? eligible-males
    ]
  ]
  ; GATHERS ALL MALES IN ADJACENT GROUP
  if ([gene-flow-group] of parent-group != nobody) [
    foreach (([phenotype-group] of [gene-flow-group] of parent-group)) [
      if [sex] of ? = "male" [
        set eligible-males lput ? eligible-males
      ]
    ]
  ]
  report eligible-males
end

to remove-phenotype
  ask parent-group [ set phenotype-group remove myself phenotype-group ]
  if infecting-parasite != nobody [ ask infecting-parasite [ die ] ]
  ask a11 [ die ]
  ask a12 [ die ]
  ask a21 [ die ]
  ask a22 [ die ]
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

SWITCH
11
340
220
373
allow-gene-flow?
allow-gene-flow?
0
1
-1000

TEXTBOX
9
224
223
242
------------ Mutation --------------
11
0.0
1

TEXTBOX
8
322
231
340
----------- Gene Flow --------------
11
0.0
1

TEXTBOX
10
379
236
397
--------- Natural Selection ----------
11
0.0
1

TEXTBOX
11
128
230
156
----------- Reproduction -----------
11
0.0
1

SLIDER
9
242
220
275
host-mutation-rate
host-mutation-rate
0
1.0
0
.01
1
NIL
HORIZONTAL

SLIDER
10
146
221
179
sexual-to-asexual-ratio
sexual-to-asexual-ratio
0
1.0
0.9
.01
1
NIL
HORIZONTAL

SLIDER
10
186
222
219
offspring-per-female
offspring-per-female
0
10
2
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
"blue-small" 1.0 0 -8020277 true "" "plot (count phenotypes with [ (color = blue ) and (size = 1) and (sex != \"asexual\")])"
"blue-medium" 1.0 0 -13345367 true "" "plot (count phenotypes with [ (color = blue ) and (size = 2) and (sex != \"asexual\")])"
"blue-large" 1.0 0 -14730904 true "" "plot (count phenotypes with [ (color = blue ) and (size = 3) and (sex != \"asexual\")])"
"orange-small" 1.0 0 -612749 true "" "plot (count phenotypes with [ (color = orange ) and (size = 1) and (sex != \"asexual\")])"
"orange-medium" 1.0 0 -955883 true "" "plot (count phenotypes with [ (color = orange) and (size = 2) and (sex != \"asexual\")])"
"orange-large" 1.0 0 -6995700 true "" "plot (count phenotypes with [ (color = orange ) and (size = 3) and (sex != \"asexual\")])"

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
"blue-small" 1.0 0 -8020277 true "" "plot (count phenotypes with [ (color = blue ) and (size = 1) and (sex = \"asexual\")])"
"blue-medium" 1.0 0 -13345367 true "" "plot (count phenotypes with [ (color = blue ) and (size = 2) and (sex = \"asexual\")])"
"blue-large" 1.0 0 -14730904 true "" "plot (count phenotypes with [ (color = blue ) and (size = 3) and (sex = \"asexual\")])"
"orange-small" 1.0 0 -612749 true "" "plot (count phenotypes with [ (color = orange ) and (size = 1) and (sex = \"asexual\")])"
"orange-medium" 1.0 0 -955883 true "" "plot (count phenotypes with [ (color = orange ) and (size = 2) and (sex = \"asexual\")])"
"orange-large" 1.0 0 -6995700 true "" "plot (count phenotypes with [ (color = orange ) and ( size = 3 ) and (sex = \"asexual\")])"

BUTTON
411
11
522
44
reproduce now
ask groups [ execute-reproduce ]
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
100
1
1
ticks
HORIZONTAL

INPUTBOX
12
26
222
86
carrying-capacity
1000
1
0
Number

SLIDER
8
475
222
508
parasite-lifespan
parasite-lifespan
0
100
12
1
1
ticks
HORIZONTAL

SLIDER
9
437
221
470
parasite-infectivity
parasite-infectivity
0
1.0
0.7
.01
1
NIL
HORIZONTAL

SLIDER
9
398
222
431
offspring-per-parasite
offspring-per-parasite
0
100
14
1
1
NIL
HORIZONTAL

SLIDER
8
282
221
315
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
8
514
221
547
show-parasites
show-parasites
0
1
-1000

PLOT
1036
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
"blue-small" 1.0 0 -8020277 true "" "plot (count parasites with [ (color = blue - 2) and (size = 1 / 3)])"
"blue-medium" 1.0 0 -13345367 true "" "plot (count parasites with [ (color = blue - 2) and (size = 2 / 3)])"
"blue-large" 1.0 0 -14730904 true "" "plot (count parasites with [ (color = blue - 2) and (size = 3 / 3)])"
"orange-small" 1.0 0 -612749 true "" "plot (count parasites with [ (color = orange - 2) and (size = 1 / 3)])"
"orange-medium" 1.0 0 -955883 true "" "plot (count parasites with [ (color = orange - 2) and (size = 2 / 3)])"
"orange-large" 1.0 0 -6995700 true "" "plot (count parasites with [ (color = orange - 2) and (size = 3 / 3)])"

TEXTBOX
11
10
229
28
------------ Population -------------
11
0.0
1

PLOT
709
23
1029
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
"asexual" 1.0 0 -4539718 true "" "plot ((count phenotypes with [ sex = \"asexual\" ]))"
"sexual" 1.0 0 -11053225 true "" "plot ((count phenotypes with [ sex != \"asexual\" ]))"

SLIDER
12
91
223
124
number-of-groups
number-of-groups
0
10
1
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Version 1.06

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
