\ Simple Editor - SED     2017-02-24 11:42 Greenwich Time

base @ decimal
0x80000 constant edlim
edlim allocate throw constant edbuf 
: clear-edbuf  edbuf edlim blank ;

variable edrow
variable edcol
variable toprow       \ row number at the top of the screen

46 constant maxcrows
63 constant maxcol
 6 constant lgmc
edlim maxcol 1+ / constant maxrow

: bl> \ ad1 n1 -- ad2 n2 
  begin over c@ bl <> over 0> and
  while 1 under+ 1-
  repeat ;

: nobl> \ ad1 n1 -- ad2 n2
  begin over c@ bl = over 0> and
  while 1 under+ 1-
  repeat ;

: <bl \ ad1 n1 -- ad2 n2
  begin over dup c@ bl <> swap edbuf > and
  while -1 under+ 1+
  repeat ;

: <nobl \ ad1 n1 -- ad2 n2
  begin over dup c@ bl = swap edbuf > and
  while -1 under+ 1+
  repeat ;

variable opfile
variable fid

80 constant mxfn

create filename mxfn allot align

: rows# \ -- n
  edbuf edlim -trailing
  nip lgmc rshift 1+ ;

: getfilename \ -- ad n
  0 0 at-xy mxfn spaces
  0 0 at-xy ." File name: "
  filename dup mxfn accept ;

: createfile \ -- 
  getfilename r/w create-file throw fid ! 
  true opfile ! ;

: openfile \ --
  getfilename r/w open-file throw fid ! 
  true opfile ! ;

: resetfile \ --
  0. fid @ reposition-file throw ;

: lf/cr \ ad1 n1 -- ad2 n2    make use of filename buffer
  tuck filename swap  \ n1 ad1 fad n1 
  move                \ n1
  filename swap       \ fad n1
  2dup + 13 swap c!   \ fad n1 (13 fad+n1)
  1 + ;               \ fad n1+1

: saveopen \ --
  rows# 0
  do i lgmc lshift edbuf + maxcol -trailing lf/cr
     fid @ write-line throw
  loop ;

: loadtext \ --
  clear-edbuf maxrow 1+ 0
  do i lgmc lshift edbuf + maxcol 
     fid @ read-line throw nip 0=
     if leave then 
  loop ;

: crow> \ -- row    cursore row on screen
  edrow @ toprow @ - ;
  
: curset  edcol @ crow> at-xy ;
: currowmove  crow> + 0 max toprow @ + edrow ! curset ;
: curcolmove  edcol @ + 0 max maxcol min edcol ! curset ;

\ ___CASE ACTIONS not changing the buffer _______________

: curleft  -1 curcolmove ;
: curright  1 curcolmove ;
: curup    -1 currowmove ;
: curdown   1 currowmove ;
: home  0 edcol ! curset ;
: attop  0 edrow ! home ;

: bottom \
  rows# edrow ! home ;

: eol \ --
  crow> lgmc lshift edbuf + maxcol 1+ -trailing
  edcol ! drop curset ;
\ _______________________________________________________

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
0x4000001B value wo<
0x7000001B value wo>

\ general codes
  8 value bs1
127 value bs2
 10 value cr1
 13 value cr2
 12 value ref   \ ctrl l
  5 value exi   \ ctrl e
  2 value bot   \ ctrl b
 20 value top   \ ctrl t 
 19 value sav   \ ctrl s
 15 value ope   \ ctrl o
 24 value sa2   \ ctrl x
 14 value new   \ ctrl n
  1 value w1<   \ ctrl a
  6 value w1>   \ ctrl f

: initialize-sed \ --
  0 edrow !
  0 edcol !
  0 toprow !
  false opfile !
  clear-edbuf ;

\ cursore position in buffert
: edpoint \ -- ad 
  edrow @ lgmc lshift
  edcol @ + 
  edbuf + ;

: >edbuf \ c --
  edpoint c! ;

: >colrow \ ad -- 
  edbuf - dup maxcol and edcol !
  lgmc rshift edrow ! ;

: edadn \ -- ad n
  edpoint edlim over edbuf - - ;

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

\ ___CASE ACTIONS changing the buffer____________________

: return \ --
  rowins rowenddown 
  .rows-below
  curdown home ;

: insrow \ --
  -1 edrow +! 
  rowins .rows-below curset
  1 edrow +! 
  home ; 

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
  maxcol edcol @ - 1- min   \ chars to be moved
  edpoint 1+                \ ad2 
  swap move 
  edcol @ 1+ edrow @ 2>r    \ the final cur pos
  curdown delrow 
  curup curup .rows-below
  2r> edrow ! edcol ! curset ;

: delch \ --
  curright backsp ;
\ _______________________________________________________

: refresh-screen \ --
  page 0 maxcrows .rows curset ;
  
: savefile \ --
  opfile @ 
  if resetfile
  else createfile refresh-screen
  then saveopen ;

: loadfile \ --
  page 
  openfile
  loadtext
  refresh-screen ;

: closed \ -- 
  opfile @ 
  if fid @ close-file throw then ;

: clearall \ --
  closed clear-edbuf refresh-screen 
  false opfile ! attop ;

: nextword \ --
  edadn -trailing bl> nobl> drop >colrow curset ;

: prevword \ --
  edadn <bl <nobl <bl nobl> drop >colrow curset ;
\ _______________________________________________________

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
          bot of bottom endof
          top of attop endof
          ref of refresh-screen endof
          sav of savefile endof
          sa2 of savefile endof
          ope of loadfile endof
          new of clearall endof
          wo< of prevword endof
          w1< of prevword endof
          wo> of nextword endof
          w1> of nextword endof
          exi of closed 0= endof
        endcase
     then
  until ;

base ! 
