;------------------------------------------------------------------------------------
;:::::: Evolution of Sex ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

extensions [ csv ]

globals [
  allele-color-types
  allele-size-types
  parasite-size-types ]

breed [ hosts host ]
breed [ parasites parasite ]

hosts-own [ allele11 allele12 allele21 allele22 sex infecting-parasite ]
parasites-own [ my-host ]

;------------------------------------------------------------------------------------
;:::::: Setup :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

to setup
  clear-all
  ask patches [ set pcolor white ]
  setup-parameters
  setup-parasites
  setup-hosts
  reset-ticks
end

to setup-parameters

  if ( behaviorspace-experiment-name = "parameter-explorer" ) [
    set parasite-mutation-rate random-float 1
    set host-mutation-rate random-float 1
    set parasite-mortality-rate random-float 1
    set parasite-reproductive-rate random-float 1
    set parasite-infectivity random-float 1
    set host-reproductive-rate random-float 1
    set host-population-density random-float 1
    set sexual-to-asexual-ratio random-float 1 ]

  set allele-size-types [ 2 4 ]
  set allele-color-types [ orange blue ]
  setup-parasite-size-types
end

to setup-parasite-size-types
  set parasite-size-types []
  foreach allele-size-types [ i ->
    foreach allele-size-types [ j ->
      set parasite-size-types lput ( ( i + j ) / 2 ) parasite-size-types
    ]
  ]
  set parasite-size-types remove-duplicates parasite-size-types
end

to setup-parasites
  create-parasites host-population-density * count patches [ initialize-parasite ]
end

to initialize-parasite
  set label ""
  set hidden? (not show-parasites)
  set shape "circle"
  set xcor random-xcor
  set ycor random-ycor
  set color ((one-of allele-color-types) - 2)
  set size (one-of parasite-size-types) / 3
  set my-host nobody
end

to setup-hosts
  create-hosts host-population-density * count patches
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
  set shape get-host-shape

  if (position allele11 allele-color-types) < (position allele12 allele-color-types) [
    set color allele12 ]

  if (position allele11 allele-color-types) > (position allele12 allele-color-types) [
    set color allele11 ]

  if (position allele11 allele-color-types) = (position allele12 allele-color-types) [
    set color allele11 ]
end

to-report get-host-shape
  if sex = "asexual" [ report "club" ]
  if sex = "male" [ report "spade" ]
  if sex = "female" [ report "heart" ]
end

;------------------------------------------------------------------------------------
;:::::: Go ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

to go

  ; visuals
  update-visibility-settings

  ; hosts
  ask hosts [ hosts-wander ]
  ask hosts [ host-reproduce ]
  maintain-host-carrying-capacity

  ; parasites
  ask parasites [ parasite-wander ]
  ask parasites [ parasites-reproduce ]
  ask parasites [ parasite-death ]

  tick
end

to update-visibility-settings
  ask hosts [ set hidden? false ]
  ask parasites [ set hidden? (not show-parasites) ]
end

to maintain-host-carrying-capacity
  repeat (count hosts - host-population-density * count patches ) [ ask one-of hosts [ remove-host ] ]
end

;------------------------------------------------------------------------------------
;:::::: Hosts :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

to hosts-wander
  right random 90
  left random 90
  fd .1
  if infecting-parasite != nobody [ ask infecting-parasite [ move-to [patch-here] of myself ] ]
end

to attempt-infection
  ask hosts-on patch-here [
    let matching? (color = ([color] of myself + 2)) and (size = ([size] of myself * 3))
    if matching? and infecting-parasite = nobody [
      if random-float 1.0 < parasite-infectivity [
        set infecting-parasite myself
        ask infecting-parasite [ set my-host myself ]
      ]
    ]
  ]
end

to host-reproduce
  if ( random-float 1.0 < host-reproductive-rate ) [
    if [infecting-parasite] of self = nobody [
      if [sex] of self = "asexual" [ ask self [ hosts-reproduce-asexually ]]
      if [sex] of self = "female" [ ask self [ hosts-reproduce-sexually ]]
    ]
  ]
end

to hosts-reproduce-asexually
  hatch-hosts 1 [
    hosts-update-for-mutation
    set-size-shape-color
  ]
end

to hosts-reproduce-sexually
  let eligible-males hosts with [ sex = "male" ]

  if any? eligible-males [
    let mate one-of eligible-males

    hatch-hosts 1 [

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
end

to remove-host
  if infecting-parasite != nobody [ ask infecting-parasite [ die ] ]
  die
end

;------------------------------------------------------------------------------------
;:::::: Parasites :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

to parasite-wander
  right random 90
  left random 90
  fd 1
  attempt-infection
end

to parasites-reproduce
  if ( my-host != nobody and random-float 1.0 < parasite-reproductive-rate ) [
    hatch-parasites 1
    [
      if random-float 1.0 < parasite-mutation-rate [
        initialize-parasite
        set xcor [xcor] of self
        set ycor [ycor] of self
      ]
    ]
  ]
end

to parasite-death
  if ( random-float 1.0 < parasite-mortality-rate ) [
    if ( my-host != nobody ) [ ask my-host [ remove-host ]]
    die
  ]
end

;------------------------------------------------------------------------------------
;:::::: Data Collection :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;------------------------------------------------------------------------------------

to collect-data

  ifelse ( not file-exists? "../output/output.csv" ) [

    file-open "../output/output.csv"
    csv:to-file "../output/output.csv" (list (list
      "behaviorspace-experiment-name"
      "behaviorspace-run-number"
      "date-and-time"
      "world-width"
      "world-height"
      "ticks"
      "sexual-to-asexual-ratio"
      "host-population-density"
      "host-reproductive-rate"
      "host-mutation-rate"
      "parasite-mortality-rate"
      "parasite-infectivity"
      "parasite-reproductive-rate"
      "parasite-mutation-rate"
      "who-won"
      "number-of-parasites"
      "number-of-asexual-hosts"
      "number-of-sexual-hosts"
    ))

    collect-data

  ][

    let oldfile csv:from-file "../output/output.csv"

    file-open "../output/output.csv"
    csv:to-file "../output/output.csv"
    (lput
      (list
        behaviorspace-experiment-name
        behaviorspace-run-number
        date-and-time
        world-width
        world-height
        ticks
        sexual-to-asexual-ratio
        host-population-density
        host-reproductive-rate
        host-mutation-rate
        parasite-mortality-rate
        parasite-infectivity
        parasite-reproductive-rate
        parasite-mutation-rate
        who-won
        number-of-parasites
        number-of-asexual-hosts
        number-of-sexual-hosts
      )

      oldfile )

    file-close

  ]

end

to-report who-won
  report (ifelse-value
    ( not any? hosts ) [ "parasites" ]
    ( count hosts with [ sex = "asexual" ] >= count hosts with [ sex = "male" or sex = "female" ] ) [ "asexual" ]
    [ "sexual" ])
end

to-report number-of-parasites
  report count parasites
end

to-report number-of-asexual-hosts
  report count hosts with [ sex = "asexual" ]
end

to-report number-of-sexual-hosts
  report count hosts with [ sex = "male" or sex = "female" ]
end
@#$#@#$#@
GRAPHICS-WINDOW
229
10
741
523
-1
-1
2.52
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
199
0
199
1
1
1
ticks
30.0

BUTTON
113
10
218
43
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
12
10
107
43
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
12
280
238
298
------------ Parasites -------------
11
0.0
1

SLIDER
10
227
221
260
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
119
220
152
sexual-to-asexual-ratio
sexual-to-asexual-ratio
0
1.0
0.5
.01
1
NIL
HORIZONTAL

PLOT
1075
273
1396
521
Sexual Phenotype Frequencies
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
"blue-small" 1.0 0 -8020277 true "" "plot (count hosts with [ (color = blue ) and (size = 1) and (sex != \"asexual\")])"
"blue-medium" 1.0 0 -13345367 true "" "plot (count hosts with [ (color = blue ) and (size = 2) and (sex != \"asexual\")])"
"blue-large" 1.0 0 -14730904 true "" "plot (count hosts with [ (color = blue ) and (size = 3) and (sex != \"asexual\")])"
"orange-small" 1.0 0 -612749 true "" "plot (count hosts with [ (color = orange ) and (size = 1) and (sex != \"asexual\")])"
"orange-medium" 1.0 0 -955883 true "" "plot (count hosts with [ (color = orange) and (size = 2) and (sex != \"asexual\")])"
"orange-large" 1.0 0 -6995700 true "" "plot (count hosts with [ (color = orange ) and (size = 3) and (sex != \"asexual\")])"

PLOT
750
273
1069
521
Asexual Phenotype Frequencies
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
"blue-small" 1.0 0 -8020277 true "" "plot (count hosts with [ (color = blue ) and (size = 1) and (sex = \"asexual\")])"
"blue-medium" 1.0 0 -13345367 true "" "plot (count hosts with [ (color = blue ) and (size = 2) and (sex = \"asexual\")])"
"blue-large" 1.0 0 -14730904 true "" "plot (count hosts with [ (color = blue ) and (size = 3) and (sex = \"asexual\")])"
"orange-small" 1.0 0 -612749 true "" "plot (count hosts with [ (color = orange ) and (size = 1) and (sex = \"asexual\")])"
"orange-medium" 1.0 0 -955883 true "" "plot (count hosts with [ (color = orange ) and (size = 2) and (sex = \"asexual\")])"
"orange-large" 1.0 0 -6995700 true "" "plot (count hosts with [ (color = orange ) and ( size = 3 ) and (sex = \"asexual\")])"

SLIDER
8
347
220
380
parasite-infectivity
parasite-infectivity
0
1.0
0.1
.01
1
NIL
HORIZONTAL

SLIDER
7
419
220
452
parasite-mutation-rate
parasite-mutation-rate
0
1.0
0.05
.01
1
NIL
HORIZONTAL

SWITCH
12
49
217
82
show-parasites
show-parasites
1
1
-1000

PLOT
1075
10
1394
265
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
9
97
227
115
-------------- Hosts ---------------
11
0.0
1

PLOT
750
10
1069
265
Sexual vs Asexual Strategies
time
percent of individuals
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"asexual" 1.0 0 -4539718 true "" "plot ((count hosts with [ sex = \"asexual\" ]) / count hosts )"
"sexual" 1.0 0 -11053225 true "" "plot ((count hosts with [ sex != \"asexual\" ]) / count hosts )"

SLIDER
9
155
220
188
host-population-density
host-population-density
0
1
0.03
.01
1
NIL
HORIZONTAL

SLIDER
8
311
221
344
parasite-mortality-rate
parasite-mortality-rate
0
1
0.005
.001
1
NIL
HORIZONTAL

SLIDER
9
191
220
224
host-reproductive-rate
host-reproductive-rate
0
1
0.003
0.001
1
NIL
HORIZONTAL

SLIDER
8
383
220
416
parasite-reproductive-rate
parasite-reproductive-rate
0
1
0.1
.001
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Evolution of Sex is a NetLogo model that illustrates the advantages and disadvantages of sexual and asexual reproductive strategies. It seeks to demonstrate the answer to the question:

#### "Why do we have sex?"

After all, wouldn't it be a better strategy to simply clone yourself? There are many advantages to asexual reproduction:

1. Your offspring possess all of your own genetic material.
2. You get to make a copy of 100% of your genes.
2. You don't have to worry about finding a mate.

Conversely, there are many disadvantages to sexual reproduction:

1. You have to share your genetic material with an unrelated individual.
2. You get to make a copy of only 50% of your genes.
3. You have to expend time and energy looking for and obtaining a mate.

From this, it may seem like sexual reproduction is an evolutionary puzzle as it appears too costly to ever be advantageous. However, as this model shows, under certain conditions, a sexual reproductive strategy can win out over an asexual strategy. By introducing parasites to the environment, it creates a selective pressure that makes it more advantageous NOT to simply make a clone of yourself! The reason is simple: if a parasite can infect you, it can also infect all of your clones. However, if your offspring only obtain 50% of their genetic material from you, they are less likely to be susceptible to the same parasite that can infect you. Sexual reproducers are able to mix their genetic material in ways that produce new combinations that parasites have not yet evolved to attack. In short, in the arms race between the hosts and the parasites, sexually reproducing hosts are able to keep up much better than asexually reproducing hosts can.

## HOW IT WORKS

When the model is initialized, a population of hosts and parasites are created.

There are many options for the reproductive strategy of the initial host population: 100% sexual reproducers, 100% asexual reproducers, or some ratio of the two. They come in different shapes: spade = male, heart = female, club = asexual. They come in different colors: orange or blue. And finally, they come in different sizes: small, medium, large. The combination of these options represents the phenotype of the host.

The phenotype is determined by the host's genotype. There are two alleles for color: orange and blue. Blue is dominant over orange. There are two alleles for size: small and large. These alleles are codominant, which allows for the expression of a medium-sized host if they possess both one small and one large allele.

All together, this creates six phenotypes for host: blue-small, blue-medium, blue-large, orange-small, orange-medium, and orange-large. The parasites, in turn, are assigned one of these six types as their infection strategy. Upon initialization, the parasites are given a random type. However, when they reproduce, which they do asexally, all of their offspring possess the same infection strategy as their parent.

When the simulation runs, host and parasites wander randomly about their environment. Host females that are in close enough proximity to a male host will reproduce sexually at each INTERBIRTH-INTERVAL. Parasites that come into contact with a host that corresponds to their own phenotype will have some probability, according to the PARASITE-INFECTIVITY setting, of infecting that host. Infected hosts then become incubation containers for the parasite's offspring. When a parasite reaches its PARASITE-LIFESPAN, it and its host die and its offspring are released into the environment.


## HOW TO USE IT

### Host Settings

Write in the CARRYING-CAPACITY input box to determine the maximum number of host individuals for your simulation. This maintains a density dependent mortality rate while the simulation is running.

The SEXUAL-TO-ASEXUAL-RATIO slider determines the initial ratio of sexual and asexual hosts in the population. When hosts mutate, it also determines the likelihood of a different reproductive strategy appearing.

The INTERBIRTH-INTERVAL slider determines how often a female reproduces.

The OFFSPRING-PER-FEMALE slider determines how many offspring each female has when she reproduces. All asexual hosts are females.

The HOST-MUTATION-RATE slider determines the rate at which each host allele mutates. The higher the mutation rate, the more likely that one or more of the parent alleles won't be correctly copied in the offspring alleles. It also determines the rate at which an offspring will assume a different reproductive strategy than its parent.

### Parasite Settings

The OFFSPRING-PER-PARASITE slider determines how many offspring each parasite has when it reproduces. Parasites only reproduce at the end of their lifespan and if they have infected a host.

The PARASITE-MUTATION-RATE slider determines the rate at which each parasite mutates its infection strategy. Again, there are six strategy options: blue-small, blue-medium, blue-large, orange-small, orange-medium, and orange-large.

The PARASITE-INFECTIVITY slider determines how easily a parasite is able to infect a host once it comes into contact with a host whose phenotype matches its own infection strategy.

The PARASITE-LIFESPAN slider determines how long a parasite lives. If a parasite hasn't found a host in that time span, they simply die. However, if they have found a host, they reproduce before they die.

Use the SHOW-PARASITES switch to decide whether you want to display the parasites in the environment or not. With this switch turned off, it may be easier to see the behavior of the host individuals. However, the parasites are still present and infecting the hosts, even if they aren't visible.

### Buttons

Press SETUP after all of the settings have been chosen. This will initialize the program to create a population of hosts and parasites.

Press GO to make the simulation run continuously. Hosts and parasites will move about the environment, reproducing or infecting when they can. To stop the simulation, press the GO button again.

### Output

While it is running, the simulation will show the results of this parasite-host interaction in four graphs:

The ASEXUAL VS. SEXUAL STRATEGIES graph shows the population count of both asexual and sexual hosts through time.

The PARASITE PHENOTYPE FREQUENCIES graph shows the prevalence of each of the six infection strategies through time.

The ASEXUAL PHENOTYPE FREQUENCIES graph shows the prevalence of each of the six phenotypes for asexual hosts through time.

THE SEXUAL PHENOTYPE FREQUENCIES graph shows the prevalence of each of the six phenotypes for sexual hosts through time.

## THINGS TO NOTICE

The purpose of this model is to demonstrate that under certain conditions sexual reproduction can be more beneficial than asexual reproduction. Pay attention to how the settings affect how often sexual reproducers are able to outcompete asexual reproducers:

1. Does it matter what the CARRYING-CAPACITY is set to?
2. How do the host reproductive settings OFFSPRING-PER-FEMALE and INTERBIRTH-INTERVAL affect the ability of the host population to survive a parasite infection?
3. How do the HOST-MUTATION-RATE and PARASITE-MUTATION-RATE settings affect which reproductive strategy wins or whether the hosts survive a parasite infection? What happens if you set a mutation rate to zero?
4. Which combination of OFFSPRING-PER-PARASITE, PARASITE-INFECTIVITY, and PARASITE-LIFESPAN settings makes the parasites most effective in infecting the host population? Which combination makes the parasites least effective? How do these settings affect which reproductive strategy wins?
5. When you set the initial host population to 100% sexual or 100% asexual, which strategy is better able to fight off the parasites? Which strategy more often goes to extinction?

Finally, make sure to pay special attention to the graphical outputs. How do the host phenotype frequencies and parasite infection strategies affect each other? What patterns do you notice?

## ACKNOWLEDGEMENTS

Thank you to M L Wilson for the conceptual idea of this model.

## COPYRIGHT AND LICENSE

© 2019 K N Crouse.

The model may be freely used, modified and redistributed provided this copyright is included and the resulting models are not used for profit.

Contact K N Crouse at crou0048@umn.edu if you have questions about its use.
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="parameter-explorer" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>collect-data</final>
    <timeLimit steps="10000"/>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>carefully [ collect-data ] [ print error-message ]</final>
    <timeLimit steps="1000"/>
    <enumeratedValueSet variable="parasite-mutation-rate">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="host-mutation-rate">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="parasite-mortality-rate">
      <value value="0.001"/>
      <value value="0.005"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="parasite-reproductive-rate">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="parasite-infectivity">
      <value value="0.05"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="host-reproductive-rate">
      <value value="0.001"/>
      <value value="0.005"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sexual-to-asexual-ratio">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="host-population-density">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
199
0
199

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
46
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
