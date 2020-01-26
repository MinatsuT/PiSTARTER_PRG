'
' ”勾配＊フェード関数”の基本パターンの重ね合わせによるパーリンノイズ by みなつ
' 平野付き 海マシ 歩き回れる メッシュが見える バージョン
'
'
option strict

acls
var SW=640,SH=360
'var SW=1280,SH=720
var CX=SW/2,CY=SH/2
VAR VRAMW=1280,VRAMH=1024
'xscreen SW,SH
'xscreen 1280,720
'CX=1280/2:CY=720/2

VAR VER$="1.02"

'パーリンノイズ関係
var grid=128
dim parlinPtn[grid*4+1,grid*4+1]
var gridCenter=grid*2
var octaveMin=2
var octaveMax=5
'octaveMin=1
'octaveMax=0

'地形データ
var mapW=256,mapH=256
dim map[mapW,mapH]
dim mapCol[mapW,mapH]
var mapMag=1/2 '地形マップの表示倍率
var mapOX=SW-mapW*mapMag,mapOY=0 '地形マップの表示位置

'地形パラメータ。生成される地面の高度(-0.5～0.5)の扱いを決める
VAR plain=0.03          '平地の基準高度
VAR plainMax=plain+0.25 '平地の最大高度。plain～plainMaxの地面を平地として平らにする。
var sea=plain-0.02      '海面の基準高度。これより低い地面は海とみなす。
var tall=48             '描画時の高さの倍率。大きくすると山が高くなる。
var tmag=(1-plain)/(1-plainMax)

'描画関係
var viewRange=64        '描画する最大距離
var size=viewRange*2+1
dim gx[size,size]
dim gy[size,size]
dim gz[size,size]
dim col[size,size]
var lodMax=3            'LoDの段階
dim idxI[size*size*lodMax]
dim idxJ[size*size*lodMax]
dim idxZ[size*size*lodMax]
dim idxIdx[size*size*lodMax]
dim refI[size*size*lodMax],refJ[size*size*lodMax]
dim lod[size*size*lodMax]
var lastRefIdx

var camz=400      'カメラの基準距離。カメラからcamz離れたときに１倍、camz*2離れると1/2倍、…で表示される。
var frontZ=0.1   'ニアクリップの距離
var vp=0          'ダブルバッファリング用の表示ページフラグ
var dispGrid=TRUE '地面のグリッドの表示フラグ
'var debugCol

'スプライトの番号
var sp_map=0
var sp_sky=1
var sp_csr=2

'移動スピード(単位：マス目/秒)
var spd=4

'createSlope
initRefOrder
createPerlinPattern
createWorld
createSky
createMap
createCsr
visible 0,1,1
flight
end

def initRefOrder
 dim tmpDist[size*size*lodMax]
 var sortStart=0
 var range=viewRange
 var vMin,vMax,stp
 var l,u,v,dist,idx=0
 
 for l=lodMax-1 to 0 step -1
  stp=pow(2,l)
  vMax=pow(range,2)
  vMin=pow(range/2-stp*2,2)*(l!=0)
  range=range/2

  for v=-viewRange to viewRange step stp
   for u=-viewRange to viewRange step stp
    dist=u*u+v*v
    if dist>=vMin && dist<=vMax then
     refI[idx]=viewRange+u
     refJ[idx]=viewRange+v
     tmpDist[idx]=dist
     lod[idx]=stp
     inc idx
    endif
   next
  next

  lastRefIdx=idx
  rsort sortStart,lastRefIdx-sortStart,tmpDist,refI,refJ,lod
  sortStart=lastRefIdx
 next
end

def createCsr
 spset sp_csr,64,96,16,16,1
 sphome sp_csr,8,8
end

def createMap
 var ox=512 'マップのオフセット
 gpage 0,SPPAGE()
 var i,j,gx,gy=0,stp=1/mapMag
 for j=0 to mapH-1 step stp
  gx=ox
  for i=0 to mapW-1 step stp
   gpset gx,gy,mapCol[i,j]
   inc gx
  next
  inc gy
 next
 spset sp_map,ox,0,mapW/stp,mapH/stp,1
 spofs sp_map,mapOX,mapOY
 spcolor sp_map,rgb(128,255,255,255)
 gpage 0,0
end

def createSlope
 fill map,0
 var i,j
 for j=0 to mapH-1
  for i=0 to mapW-1
   map[i,j]=-2+(i+j)/mapH*0.5
  next
 next
end

def createWorld
 width 16
 color #LIME

 var h
 for h=0 to 300
  gline SW-10,SH-h,SW-1,SH-h,byg2rgb(h,1)
 next

 fill map,0
 locate 0,(SH div 16)-1
 var o
 for o=octaveMin to octaveMax
  var oct=pow(2,o-1),amp=pow(2,o-octaveMin)
  ?format$("Octave=%d(x%D) Amp=1/%d",o,oct,amp)
  makeMap 1/oct,1/amp
  viewMap
 next
 cls

 var i,j
 for j=0 to mapH-1
  for i=0 to mapW-1
   't=-0.5〜0.5
   var t=map[i,j]

   '平野を作る
   if t>plain then t=plain+max(0,t-plainMax)*tmag
   '海面を作る
   t=max(t,sea)
   map[i,j]=t
  next
 next

 for j=0 to mapH-1
  for i=0 to mapW-1
   var i1=(i+1) mod mapW
   var j1=(j+1) mod mapH
   t=max(map[i,j],map[i1,j],map[i1,j1],map[i,j1])

   '色を設定 h: 青(0) 緑(100) 黄(200)
   h=100+(t-plain)*300
   'h=(h div 30)*30
   var b=0.8
   if t<=sea then h=10:b=0.7 '海

   '色を少しランダムにする
   randomize 1,i+j*mapH
   dec h,rnd(1,10)-5
   mapCol[i,j]=byg2rgb(h,b)
  next
 next
end

def createSky
 var w=16
 var ox=VRAMW-w
 '空
 gpage 0,SPPAGE()
 var eyeLevel=0
 var skyHeight=SH-eyeLevel
 var i
 for i=0 to skyHeight
  var gy=SH-eyeLevel-i
  var rr=lerp(i,30,skyHeight,200,90)
  var gg=lerp(i,30,skyHeight,200,162)
  var bb=lerp(i,30,skyHeight,200,255)
  gline ox,gy,ox+w-1,gy,rgb(rr,gg,bb)
 next
 spset sp_sky,ox,0,w,SH,1
 spofs sp_sky,0,0,1000
 spscale sp_sky,SW/w,1
 gpage 0,0
end

def flight
 width 8
 gclip 0,0,0,SW-1,SH-1
 gclip 1,0,0,SW-1,SH-1

 dim cam[3]:set cam,mapW/2,0,mapH/2
 dim ck[3]:set ck,0,0,1:norm ck
 dim ci[3]:roty ci,ck,pi()/2:ci[1]=0:norm ci
 dim cj[3]:cross cj,ck,ci:norm cj
 'padmode 0

 load "dat:cam",cam
 load "dat:ci",ci
 load "dat:cj",cj
 load "dat:ck",ck
 
' set cam,140.11,8.80 ,163.64
' set ci ,-0.13 ,0.98 ,-0.22
' set cj ,-0.99 ,-0.13,0.04
' set ck ,0.01  ,0.22 ,0.98

 var st=millisec
 var nxt=st+5000
 var frames=0,fps
 var last=millisec
 dim v[3],ascendingForce[3]
 var rollW=0,rollA=0.005,rollBrk=0.9
 var pitchW=0,pitchA=0.005,pitchBrk=0.9
 var g=0.1,vtok=0.02
 var fwdV=0,fwdA=0.05,fwdMax=g/vtok*1.2
 var fwdBrk=fwdMax/(fwdMax+fwdA)
 var ground
 var autoFwd=0
 var autoR=0
 var autoL=0
 var autoU=0
 var autoD=0

 CLS
 LOCATE 0,0:?"グリッド表示";" ON"*dispGrid;"OFF"*!dispGrid

 VAR LAST_BTN,BTN,BTN_PRESS
 while 1
  var now=millisec
  var dur1=now-last
  last=now
'debugCol=0
'cls

  var k$=inkey$()
  if k$==" " then autoFwd=!autoFwd
  if k$==chr$(&h1C) then autoR=!autoR
  if k$==chr$(&h1D) then autoL=!autoL
  if k$==chr$(&h1E) then autoU=!autoU
  if k$==chr$(&h1F) then autoD=!autoD

  BTN=BUTTON()
  BTN_PRESS=(NOT LAST_BTN) AND BTN
  LAST_BTN=BTN

  dec cam[0],floor(cam[0]/mapW)*mapW
  dec cam[2],floor(cam[2]/mapH)*mapH
  
  var xx=cam[0]
  var yy=-cam[2]
  var mx=(floor(xx)+mapW*1000) mod mapW
  var my=(floor(yy)+mapH*1000) mod mapH
  var mXx=(mx+1) mod mapW
  var mYy=(my+1) mod mapH
 
  var t1=map[mx,my]
  var t2=map[mXx,my]
  var t3=map[mx,mYy]
  var deX=xx-floor(xx)
  var deY=yy-floor(yy)
  var t=t1+(t2-t1)*deX+(t3-t1)*deY

if 0 then
  rollW=0:pitchW=0
  if button(0,#BID_LEFT)  || autoL then rollW=rad(5)
  if button(0,#BID_RIGHT) || autoR then rollW=rad(-5)
  if button(0,#BID_UP)    || autoU then pitchW=rad(5)
  if button(0,#BID_DOWN)  || autoD then pitchW=rad(-5)
endif
  if button(0,#BID_LEFT)  || autoL then rollW=rollW+rollA
  if button(0,#BID_RIGHT) || autoR then rollW=rollW-rollA
  if button(0,#BID_UP)    || autoU then pitchW=pitchW+pitchA
  if button(0,#BID_DOWN)  || autoD then pitchW=pitchW-pitchA

  var sx,sy:stick 0 out sx,sy
  if abs(sx)>0.1 then inc rollW,-rollA*sx
  if abs(sy)>0.1 then inc pitchW,-pitchA*sy
  
  rollW=rollW*rollBrk
  pitchW=pitchW*pitchBrk
  rotn ci,ci,ck,rollW
  rotn ck,ck,ci,pitchW
  norm ck:norm ci:cross cj,ck,ci

  if button(0,#BID_B) || autoFwd then fwdV=(fwdV+fwdA)*fwdBrk
  if button(0,#BID_A) then fwdV=max(0,fwdV-fwdA)

  copy v,ck
  mul v,v,dur1/1000*fwdV
  v[1]=v[1]-g
  add cam,cam,v
  mul ascendingForce,cj,fwdV*vtok
  add cam,cam,ascendingForce

  'cam[1]=min(t*tall+0.6,max(t*tall+0.4,cam[1]))
  ground=t*tall+0.4
  if cam[1]<ground then
   cam[1]=ground
   set cj,0,1,0
   ck[1]=0:norm ck
   cross ci,cj,ck
   rollW=0:pitchW=0
  endif


  gpage vp,!vp
  drawAhead cam,ci,cj,ck
  IF BTN_PRESS and (1<<#BID_Y) THEN
   dispGrid=!dispGrid
   'LOCATE 0,0:?"グリッド表示";" ON"*dispGrid;"OFF"*!dispGrid
  ENDIF
  gputchr 0,8*0,"グリッド表示"+" ON"*dispGrid+"OFF"*!dispGrid
  gputchr 0,8*2,format$("spd=%6.2f",fwdV)
  gputchr 0,8*3,format$("altitude=%6.2f",cam[1])
  gputchr 0,8*1,format$("%6.2ffps",fps)
  vp=!vp

  spofs sp_csr,mapOX+cam[0]*mapMag,mapOY+(mapH-cam[2])*mapMag,-10
  sprot sp_csr,-deg(atan(ck[2],ck[0]))+90

  inc frames
  var ed=millisec
  if ed>=nxt then
   var dur=(ed-st)/1000
   fps=frames/dur
   'locate 0,1:?format$("%6.2ffps",fps)
   gputchr 0,8*1,format$("%6.2ffps",fps)
   st=ed
   nxt=st+5000
   frames=0
  endif
 wend

end

def drawAhead cam,ci,cj,ck
 fill idxI,0
 fill idxJ,0
 fill idxIdx,0
 fill gx,0
 fill gy,0
 fill gz,0
 
 var u,v,x,y,i,j,idx=0
 var p[3],cp[3],scl,m=0
 var mx,my

 var ci0=ci[0],ci1=ci[1],ci2=ci[2]
 var cj0=cj[0],cj1=cj[1],cj2=cj[2]
 var ck0=ck[0],ck1=ck[1],ck2=ck[2]

 var cp0,cp1,cp2
 var cam0=cam[0],cam1=cam[1],cam2=cam[2]
 var refIdx,lodStp
 for refIdx=0 to lastRefIdx-1
  i=refI[refIdx]
  j=refJ[refIdx]
  lodStp=lod[refIdx]

  x=floor(cam[0]/lodStp)*lodStp+i-viewRange
  y=-floor(cam[2]/lodStp)*lodStp+j-viewRange
  my=(y+mapH*1000) mod mapH
  mx=(x+mapW*1000) mod mapW
  col[i,j]=mapCol[mx,my]

  cp0=x-cam0
  cp1=map[mx,my]*tall-cam1
  cp2=-y-cam2

  gz[i,j]=cp0*ck0+cp1*ck1+cp2*ck2
  if gz[i,j]<frontZ-1 then continue

  gx[i,j]=cp0*ci0+cp1*ci1+cp2*ci2
  gy[i,j]=cp0*cj0+cp1*cj1+cp2*cj2

  if gx[i,j]!=0 && (gz[i,j]+lod[refIdx]*2)/abs(gx[i,j])<0.7 then continue

  idxI[idx]=i
  idxJ[idx]=j
  idxZ[idx]=gz[i,j]
  idxIdx[idx]=refIdx
  idx=idx+1
 next
 var lastIdx=idx

 gcls

 var ox=0,oy=0 '表示オフセット
 var minZ,maxZ,zeroCheck
 var i1,j1
 var cc,c,rr,gg,bb,av,colScl
 var scl1,scl2,scl3,scl4
 var ggx1,ggx2,ggx3,ggx4
 var ggy1,ggy2,ggy3,ggy4
 var ggz1,ggz2,ggz3,ggz4

 for idx=0 to lastIdx-1
  i=idxI[idx]
  j=idxJ[idx]
  refIdx=idxIdx[idx]
  if i>=size-2 || j>=size-2 then continue
  'if lod[refIdx]<=1 then continue
  i1=i+lod[refIdx]
  j1=j+lod[refIdx]
  if i1>=size-1 || j1>=size-1 then continue

  maxZ=max(gz[i,j],gz[i1,j],gz[i1,j1],gz[i,j1])
  zeroCheck=gz[i,j]*gz[i1,j]*gz[i1,j1]*gz[i,j1]
  if maxZ<frontZ || zeroCheck==0 then continue

  cc=col[i,j]
  rgbread cc out rr,gg,bb
  av=(rr+gg+bb)/3
  colScl=max(0.5,1-maxZ/30)
  RR=av+(rr-av)*colScl
  GG=av+(gg-av)*colScl
  BB=av+(bb-av)*colScl+(1-colScl)*8
  cc=rgb(RR,GG,BB)
  c=rgb(rr*0.9,gg*0.9,bb*0.9)

  minZ=min(gz[i,j],gz[i1,j],gz[i1,j1],gz[i,j1])
  if minZ<frontZ then
   dim gtx[4],gty[4],gtz[4]
   gtx[0]=gx[i ,j ]
   gty[0]=gy[i ,j ]
   gtz[0]=gz[i ,j ]

   gtx[1]=gx[i1,j ]
   gty[1]=gy[i1,j ]
   gtz[1]=gz[i1,j ]

   gtx[2]=gx[i1,j1]
   gty[2]=gy[i1,j1]
   gtz[2]=gz[i1,j1]

   gtx[3]=gx[i ,j1]
   gty[3]=gy[i ,j1]
   gtz[3]=gz[i ,j1]
   drawTriangle gtx,gty,gtz,cc,c,frontZ,0
   drawTriangle gtx,gty,gtz,cc,c,frontZ,2
  else
   scl1=camz/gz[i ,j ]
   scl2=camz/gz[i1,j ]
   scl3=camz/gz[i1,j1]
   scl4=camz/gz[i ,j1]
   
   ggx1=cx+gx[i ,j ]*scl1
   ggx2=cx+gx[i1,j ]*scl2
   ggx3=cx+gx[i1,j1]*scl3
   ggx4=cx+gx[i ,j1]*scl4
   ggy1=cy-gy[i ,j ]*scl1
   ggy2=cy-gy[i1,j ]*scl2
   ggy3=cy-gy[i1,j1]*scl3
   ggy4=cy-gy[i ,j1]*scl4

   'var minX=min(ggx1,ggx2,ggx3,ggx4)
   'var maxX=max(ggx1,ggx2,ggx3,ggx4)
   'var minY=min(ggy1,ggy2,ggy3,ggy4)
   'var maxY=max(ggy1,ggy2,ggy3,ggy4)
   'if maxX<0 && minX>SW && maxY<0 && minY>SH then continue
   if min(ggx1,ggx2,ggx3,ggx4)<0 && max(ggx1,ggx2,ggx3,ggx4)>SW && min(ggy1,ggy2,ggy3,ggy4)<0 && max(ggy1,ggy2,ggy3,ggy4)>SH then continue

   gtri ggx1,ggy1,ggx2,ggy2,ggx3,ggy3,cc
   gtri ggx3,ggy3,ggx4,ggy4,ggx1,ggy1,cc

   IF dispGrid THEN
    gline ggx1,ggy1,ggx2,ggy2,c
    gline ggx2,ggy2,ggx3,ggy3,c
    gline ggx3,ggy3,ggx4,ggy4,c
    gline ggx4,ggy4,ggx1,ggy1,c
   ENDIF
  endif
 next
end

def drawTriangle gxIn,gyIn,gzIn,cc,c,frontZ,idx
 dim gx[5],gy[5],lineFlag[5],g=0
 var i,i0,i1,i2
 var scl=camz/frontZ
'debugCol=rgb(rnd(255),rnd(255),128)
'cc=debugCol:color debugCOl

'var ii
'?"gxIn ";:for ii=0 to 3:?gxIn[ii];" ";:next:?
'?"gyIn ";:for ii=0 to 3:?gyIn[ii];" ";:next:?
'?"gzIn ";:for ii=0 to 3:?gzIn[ii];" ";:next:?
'dim idxNum[0]

 var x1,y1,z1
 var x2,y2,z2
 for i=0 to 2
  i0=(idx+i) mod 4
  i1=(idx+((i+1) mod 3)) mod 4
  if gzIn[i0]>=frontZ then
   var s=camz/gzIn[i0]
   gx[g]=cx+gxIn[i0]*s
   gy[g]=cy-gyIn[i0]*s
   lineFlag[g]=(i<2)
   g=g+1
'push idxNum,i0
'?"push1"
   if gzIn[i1]>=frontZ then
    if i==2 then
     'add last
     var s1=camz/gzIn[i1]
     gx[g]=cx+gxIn[i1]*s1
     gy[g]=cy-gyIn[i1]*s1
     lineFlag[g]=0
     g=g+1
'push idxNum,i1
'?"add last"
    endif
   else
    x1=gxIn[i0]
    y1=gyIn[i0]
    z1=gzIn[i0]

    x2=gxIn[i1]
    y2=gyIn[i1]
    z2=gzIn[i1]
    
    z1=abs(z1-frontZ)
    z2=abs(z2-frontZ)
    x2=(x1*z2+x2*z1)/(z1+z2)
    y2=(y1*z2+y2*z1)/(z1+z2)
    gx[g]=cx+x2*scl
    gy[g]=cy-y2*scl
    lineFlag[g]=0
    g=g+1
'?"push1-mid"
'push idxNum,i0
   endif
  else
   if gzIn[i1]<frontZ then
    'nothing to draw
'?"nothig to draw"
   else
    x1=gxIn[i0]
    y1=gyIn[i0]
    z1=gzIn[i0]

    x2=gxIn[i1]
    y2=gyIn[i1]
    z2=gzIn[i1]
    
    z1=abs(z1-frontZ)
    z2=abs(z2-frontZ)
    x2=(x1*z2+x2*z1)/(z1+z2)
    y2=(y1*z2+y2*z1)/(z1+z2)
    gx[g]=cx+x2*scl
    gy[g]=cy-y2*scl
    lineFlag[g]=(i<2)
    g=g+1
'?"push2-mid"
'push idxNum,i0
   endif
  endif
 next

'?"gxLen=";g
 for i=0 to g-2 step 2
  i1=(i+1) mod g
  i2=(i+2) mod g
  gtri gx[i],gy[i],gx[i1],gy[i1],gx[i2],gy[i2],cc
  'gtri gx[i],gy[i],gx[i1],gy[i1],gx[i2],gy[i2],#red
  IF dispGrid THEN
   if lineFlag[i] then gline gx[i],gy[i],gx[i1],gy[i1],c
   if lineFlag[i1] then gline gx[i1],gy[i1],gx[i2],gy[i2],c
  ENDIF
  'gline gx[i],gy[i],gx[i1],gy[i1],#cyan
  'gline gx[i1],gy[i1],gx[i2],gy[i2],#cyan
  'gline gx[i2],gy[i2],gx[i],gy[i],#cyan
'gputchr gx[i],gy[i],str$(idxNum[i])
'gputchr gx[i1],gy[i1],str$(idxNum[i1])
'gputchr gx[i2],gy[i2],str$(idxNum[i2])
'?gx[i],gy[i],gx[i1],gy[i1],gx[i2],gy[i2],cc
'waitKey
 next
'waitKey
end

def makeMap scl,amp
 var ix,iy,stp=grid*scl
 for iy=0 to mapH-1 step stp
  for ix=0 to mapW-1 step stp
   rotDraw ix,iy,scl,rad(rnd(360)),amp
  next
 next
end

def waitKey
 repeat:vsync:until inkey$()!=""
end

def rotDraw x,y,scl,th,amp
 var u,v,size=grid*scl

 for v=-size to size
  for u=-size to size
   var px=gridCenter+(u*cos(th)-v*sin(th))/scl
   var py=gridCenter+(u*sin(th)+v*cos(th))/scl
   if px<0 || py<0 || px>grid*4 || py>grid*4 then continue

   var gx=(x+u+mapW) mod mapW
   var gy=(y-v+mapH) mod mapH
   inc map[gx,gy],parlinPtn[px,py]*amp

   var c=(1+map[gx,gy])*128
   gpset gx,gy,rgb(c,c,c)
  next
 next
end

def createPerlinPattern
 var x,y,gradU=1,gradV=0

 for y=-grid to grid
  var v=y/grid
  var fv=1-fad(abs(v))

  for x=-grid to grid
   var u=x/grid
   var fu=1-fad(abs(u))

   var c=(u*gradU+v*gradV)*fu*fv
   parlinPtn[gridCenter+x,gridCenter+y]=c
  next
 next
end

def fad(t)
 return t*t*t*(t*(t*6-15)+10)
end

var direc
def viewMap
 dim cam[3],camTo[3]
 set camTo,0,0,0 'カメラの注視点

 'inc direc,5
 var th=rad(-90+20+direc)
 var r=max(mapW,mapH)
 set cam,r*cos(th),180,r*sin(th) 'カメラの位置
 'set cam,r*cos(th)*0.9,r*0.2,r*sin(th)*0.9 'カメラの位置
 drawMap cam,camTo
end

def drawMap cam,camTo
 dim gx[mapW,mapH]
 dim gy[mapW,mapH]
 dim gz[mapW,mapH]
 dim col[mapW,mapH]
 dim idxI[mapW*mapH]
 dim idxJ[mapW*mapH]
 dim idxZ[mapW*mapH]

 dim ck[3]:sub ck,camTo,cam:norm ck
 dim ci[3]:roty ci,ck,pi()/2:ci[1]=0:norm ci
 dim cj[3]:cross cj,ck,ci:norm cj

 var x,y,i,j,stp=4,idx=0
 VAR T

 for y=-mapH/2 to (mapH-1)/2 step stp
  j=y-(-mapH/2)
  for x=-mapW/2 to (mapW-1)/2 step stp
   i=x-(-mapW/2)

   var p[3],cp[3],scl,m=0,mag=SW

   t=map[i,j]
   if t>plain then t=plain+max(0,t-plainMax)*tmag
   t=max(t,sea)
   set p,x,t*tall,-y
   sub cp,p,cam
   gz[i,j]=iprod(cp,ck)
   scl=mag/(camz+gz[i,j])
   gx[i,j]=cx+iprod(cp,ci)*scl
   gy[i,j]=cy-iprod(cp,cj)*scl

   var h=100+(t-plain)*600
   h=(h div 30)*30
   var b=1-0.2+t
   if t==sea then h=0:b=1
   col[i,j]=byg2rgb(h,b)

   idxI[idx]=i
   idxJ[idx]=j
   idxZ[idx]=gz[i,j]
   inc idx
  next
 next
 var lastIdx=idx

 rsort idxZ,idxI,idxJ

'gcls
 var ox=150,oy=-70 '表示オフセット
 var l=len(idxZ)
 for idx=0 to lastIdx-1
  if idxZ[idx]<=-camz+10 then continue
  i=idxI[idx]
  j=idxJ[idx]
  if i>=mapH-stp || j>=mapW-stp then continue
  var c=col[i,j]
  var ggx1=gx[i    ,j    ]+ox
  var ggx2=gx[i+stp,j    ]+ox
  var ggx3=gx[i+stp,j+stp]+ox
  var ggx4=gx[i    ,j+stp]+ox
  var ggy1=gy[i    ,j    ]+oy
  var ggy2=gy[i+stp,j    ]+oy
  var ggy3=gy[i+stp,j+stp]+oy
  var ggy4=gy[i    ,j+stp]+oy

  var rr,gg,bb
  rgbread c out rr,gg,bb
  var cc=rgb(rr*0.7,gg*0.7,bb*0.7)
  gtri ggx1,ggy1,ggx2,ggy2,ggx3,ggy3,cc
  gtri ggx3,ggy3,ggx4,ggy4,ggx1,ggy1,cc
'  gline ggx1,ggy1,ggx2,ggy2,c
'  gline ggx2,ggy2,ggx3,ggy3,c
'  gline ggx3,ggy3,ggx4,ggy4,c
'  gline ggx4,ggy4,ggx1,ggy1,c
 next
end

def byg2rgb(h,v)
 'h=0〜200
 var hh=h*510/200
 var r=hh-255
 var g=hh
 var b=255-hh
 return rgb(r*v,g*v,b*v)
end


'三次元ベクトル計算ルーチン(左手係)
DEF V3$(A)
 RETURN FORMAT$("(%6.2F,%6.2F,%6.2F)",A[0],A[1],A[2])
END

DEF PRNT A
 ?V3$(A)
END

DEF SET C,X,Y,Z
 C[0]=X
 C[1]=Y
 C[2]=Z
END

DEF ADD C,A,B
 C[0]=A[0]+B[0]
 C[1]=A[1]+B[1]
 C[2]=A[2]+B[2]
END

DEF SUB C,A,B
 C[0]=A[0]-B[0]
 C[1]=A[1]-B[1]
 C[2]=A[2]-B[2]
END

DEF MUL C,A,B
 C[0]=A[0]*B
 C[1]=A[1]*B
 C[2]=A[2]*B
END

DEF DIVD C,A,B
 C[0]=A[0]/B
 C[1]=A[1]/B
 C[2]=A[2]/B
END

DEF DIST(A)
 RETURN SQR(A[0]*A[0]+A[1]*A[1]+A[2]*A[2])
END

DEF IPROD(A,B)
 RETURN A[0]*B[0]+A[1]*B[1]+A[2]*B[2]
END

DEF CROSS C,A,B
 C[0]=A[1]*B[2]-B[1]*A[2]
 C[1]=A[2]*B[0]-B[2]*A[0]
 C[2]=A[0]*B[1]-B[0]*A[1]
END

DEF NORM A
 VAR D=SQR(A[0]*A[0]+A[1]*A[1]+A[2]*A[2])
 A[0]=A[0]/D
 A[1]=A[1]/D
 A[2]=A[2]/D
END

DEF ROTX C,A,TH
 VAR SN=SIN(TH),CS=COS(TH)
 VAR X=A[0],Y=A[1],Z=A[2]
 C[0]=X
 C[1]=Y*CS-Z*SN
 C[2]=Y*SN+Z*CS
END

DEF ROTY C,A,TH
 VAR SN=SIN(TH),CS=COS(TH)
 VAR X=A[0],Y=A[1],Z=A[2]
 C[0]=Z*SN+X*CS
 C[1]=Y
 C[2]=Z*CS-X*SN
END

DEF ROTZ C,A,TH
 VAR SN=SIN(TH),CS=COS(TH)
 VAR X=A[0],Y=A[1],Z=A[2]
 C[0]=X*CS-Y*SN
 C[1]=X*SN+Y*CS
 C[2]=Z
END

DEF ROTN C,A,N,TH
 VAR SN=SIN(TH),CS=COS(TH)
 VAR CS1=1-CS
 VAR A1=A[0],A2=A[1],A3=A[2]
 VAR N1=N[0],N2=N[1],N3=N[2]
 VAR N12CS1=N1*N2*CS1
 VAR N23CS1=N2*N3*CS1
 VAR N31CS1=N3*N1*CS1
 VAR N1SN=N1*SN
 VAR N2SN=N2*SN
 VAR N3SN=N3*SN
 C[0]=A1*(CS+N1*N1*CS1) + A2*(N12CS1-N3SN)  + A3*(N31CS1+N2SN)
 C[1]=A1*(N12CS1+N3SN)  + A2*(CS+N2*N2*CS1) + A3*(N23CS1-N1SN)
 C[2]=A1*(N31CS1-N2SN)  + A2*(N23CS1+N1SN)  + A3*(CS+N3*N3*CS1)
END

'補間
'--------------------------------------------------------------
def lerp(x,inStart,inEnd,outStart,outEnd)
 var inDiff=inEnd-inStart
 var outDiff=outEnd-outStart
 var outMin=min(outStart,outEnd)
 var outMax=max(outStart,outEnd)
 return max(outMin,min(outMax,outStart+(x-inStart)/inDiff*outDiff))
end

