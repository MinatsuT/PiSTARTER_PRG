'
' UIテスト1 by みなつ
'
exec "prg3:libGoogleIMEg"
option strict
acls
var sw,sh,aspect
xscreen out sw,sh,aspect
var cx=sw/2,cy=sh/2

'showSig

var ws=256,wox=1280-ws,woy=0
makewin ws

prgedit 3
while 1
 showDemo 1
 showDemo 1/2
 showDemo 1/3
 showDemo 1/4
 showDemo 1/5
 showDemo 1/4
 showDemo 1/3
 showDemo 1/2
wend
end

'スロット3の内容を使ってウインドウ表示(速度指定付き)
def showDemo spd
 dim m$[15]
 var i
 for i=0 to 15-1
  m$[i]=left$(prgget$(),16)
 next
 showWin m$,spd
 wait 30
end

'ウインドウ表示
def showWin m$,spd
 gpage 0,1
 spclr
 sppage 1
 spset 0, wox,woy, ws,ws, 1
 var wx=(sw-ws)/2,wy=(sh-ws)/2
 spofs 0, wx,wy,1023
 spcolor 0,rgb(192,255,255,255)
 sphide 0

 var msp[0]
 gfInit
 gfill 0,0,ws-1,ws-1,0
 var i
 for i=0 to len(m$)-1
  var sx=0,sy=16*i
  gfPutchr sx,sy,m$[i]
  var sp=spset(sx,sy,ws-16,16,1)
  sphome sp,(ws-16)/2,-16*i
  spofs sp,wx+ws/2,wy+8,1022
  sphide sp
  push msp,sp
 next

 var m=16
 for i=0 to m*1.2 step spd
  var r=i/(m*1)
  var s=sin(min(1,r)*pi()/2)
  s=sig(r)
  spscale 0,s,s:spshow 0
  showLine msp,r
  vsync
 next
end

'一行表示
def showLine msp,r
 var i
 for i=0 to len(msp)-1
  var sp=msp[i]
  var s=r-0.02*i
  spscale sp,sig(s),sig(s*2)
  spshow sp
 next
end

'シグモイド関数(0〜1の範囲に正規化)
def sig(x)
 return 1/(1+exp(6-12*x))
end

'ウインドウの背景を作成
def makewin s
 gpage 0,1
 var x,sb=128,db=64
 for x=0 to s-1
  var b=(lerp(x,s*1/8,s, sb,sb-db) div 8)*8
  gline wox+x,woy+0, wox+x,woy+s-1, rgb(0,0,b)
 next

 var f=10
 gtri wox+0,woy+0, wox+0,woy+f-1, wox+f-1,woy+0, 0
 var m=1,e=s-1-m

 var c
 c=rgb(0,0,sb/2)
 gline wox+1+f+m, woy+1+m,    wox+1+e,    woy+1+m,   c
 gline wox+1+e,   woy+1+m,    wox+1+e,    woy+1+e,   c
 gline wox+1+e,   woy+1+e,    wox+1+m,    woy+1+e,   c
 gline wox+1+m,   woy+1+e,    wox+1+m,    woy+1+f+m, c
 gline wox+1+m,   woy+1+f+m,  wox+1+f+m,  woy+1+m,   c

 var v=255
 c=rgb(v,v,v)
 gline wox+f+m,woy+m,  wox+e,   woy+m,    c
 gline wox+e, woy+m,   wox+e,   woy+e,    c
 gline wox+e, woy+e,   wox+m,   woy+e,    c
 gline wox+m, woy+e,   wox+m,   woy+f+m, c
 gline wox+m, woy+f+m, wox+f+m, woy+m,    c


 gfill wox+s-1-m-1,  woy+s-1-16*1, wox+s-1-1,woy+s-1-1, c
 gfill wox+s-1-16*1, woy+s-1-m-1,  wox+s-1-1,woy+s-1-1, c
end


'補間
'--------------------------------------------------------------
def lerp(x,inStart,inEnd,outStart,outEnd)
 var inDiff=inEnd-inStart
 var outDiff=outEnd-outStart
 var outMin=min(outStart,outEnd)
 var outMax=max(outStart,outEnd)
 return max(outMin,min(outMax,outStart+(x-inStart)/inDiff*outDiff))
end

