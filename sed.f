
\ Simple Editor - SED     2017-02-22 9:07 Greenwish Time

0x80000 constant edlim
edlim allocate throw constant edbuf 

variable edrow
variable edcol
variable toprow       \ row number at the top of the screen

46 constant maxcrows
63 constant maxcol
 6 constant lgmc
edlim maxcol 1+ / constant maxrow

: crow> \ -- row    cursore row on screen
  edrow @ toprow @ - ;

: curset  edcol @ crow> at-xy ;
: currowmove  crow> + 0 max toprow @ + edrow ! curset ;
: curcolmove  edcol @ + 0 max maxcol min edcol ! curset ;

\ ___CASE ACTIONS________________

: curleft  -1 curcolmove ;
: curright  1 curcolmove ;
: curup    -1 currowmove ;
: curdown   1 currowmove ;
\ _______________________________


\ gforth codes
0x80000000 value cul
0x80000001 value cur
0x80000002 value cup 
0x80000003 value cud
0x80000004 value hom
0x80000005 value end
0x80000006 value pgu
0x80000007 value pgd
0x80000008 value ins
0x80000009 value del
0xA0000009 value dr1
0xC0000009 value dr2

\ general codes
  8 value bs1
127 value bs2
 10 value cr1
 13 value cr2
 12 value ref
  5 value exi

: initialize-sed \ --
  0 edrow !
  0 edcol !
  0 toprow !
  edbuf edlim blank ;

\ cursore position in buffert
: edpoint \ -- ad 
  edrow @ lgmc lshift
  edcol @ + 
  edbuf + ;

: >edbuf \ c --
  edpoint c! ;

\ type rest of row
: .row>> \ -- 
  edpoint maxcol edcol @ - 1+ curset type ; 

: .row \ row --
  edrow @ swap edrow !
  edcol @ 0 edcol !
  .row>>
  edcol ! edrow ! ;

: .rows \ row n --
  0 do dup i + .row loop drop ;

: .rows-below \ n --
  edrow @ maxcrows .rows ;

: row> \ --
  edpoint dup 1+ maxcol edcol @ - move
  bl edpoint c! ;

: row< \ -- 
  edpoint dup 1- maxcol edcol @ - 1+ move ;

: rowins \ --
  crow> lgmc lshift dup 
  locals| n | edbuf + 
  dup maxcol 1+ + dup >r
  edlim n - move 
  r> maxcol 1+ blank ;

: rowenddown \ --
  edpoint crow> 1+ lgmc lshift edbuf +
  maxcol edcol @ - 1+ move 
  edpoint maxcol edcol @ - blank ;

: inchar \ c --
  edcol @ maxcol = if bl >edbuf exit then
  row> >edbuf .row>> curright ;

: .ascii \ c -- c flag
  dup bl bs2 within 
  if dup inchar true else false then ;

\ ___CASE ACTIONS________________

: home  0 edcol ! curset ;

: return \ --
  rowins rowenddown 
  .rows-below
  curdown home ;

: insrow \ --
  rowins .rows-below curset ; 

: eol \ --
  crow> lgmc lshift edbuf + maxcol 1+ -trailing
  edcol ! drop curset ;

: delrow \ -- 
  home edpoint 
  dup maxcol 1+ + swap
  maxrow edrow @ - lgmc lshift move 
  .rows-below curset ; 

: backsp \ --
  edcol @
  if row< curleft .row>> curset exit then
  edpoint eol edcol @       \ ad1 chars#
  curup eol 
  edpoint 1+                \ ad2 
  swap move 
  edcol @ 1+ edrow @ 2>r    \ the final cur pos
  curdown delrow 
  curup curup .rows-below
  2r> edrow ! edcol ! curset ;

: delch \ --
  curright backsp ;

: refresh-screen \ --
  page 0 maxcrows .rows curset ;

\ _______________________________

: sed \ --
  page initialize-sed
  begin ekey .ascii
     if drop false
     else false swap
        case 
          cul of curleft endof 
          cur of curright endof
          cud of curdown endof
          cup of curup endof
          cr1 of return endof
          cr2 of return endof
          bs1 of backsp endof
          bs2 of backsp endof
          hom of home endof 
          end of eol endof
          del of delch endof
          dr1 of delrow endof
          dr2 of delrow endof
          ins of insrow endof
          ref of refresh-screen endof
          exi of 0= endof
        endcase
     then
  until ;

