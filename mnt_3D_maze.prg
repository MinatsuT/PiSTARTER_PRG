'
' SPCOLVECを使った3D迷路のサンプル by みなつ
'
option strict
acls

var ver$="1.01"
var w=640,h=360
xscreen w,h

'ボタンのマスク
var B_UP   =1<<#BID_UP
var B_DOWN =1<<#BID_DOWN
var B_LEFT =1<<#BID_LEFT
var B_RIGHT=1<<#BID_RIGHT
var B_A    =1<<#BID_A
var B_B    =1<<#BID_B

var wallNum=128
var wallMin=512-wallNum,wallMax=511 '壁のスプライト番号
var spLogo=wallMin-1

padmode 0

makeMaze '迷路の作成
initSpGrp'スプライトと背景グラフィックの初期化
game     '3D迷路本編
end

'==============================================================
'3D迷路本編
'==============================================================
def game
 dim p[2]:set p,8,8          'pはプレイヤーの位置ベクトル
 dim v[2]:set v,0,0          'vはプレイヤーの速度ベクトル
 var brake=0.9               'brakeは減速率
 var a=calcAccel(1,brake)    'aは視線方向への加速度
 dim c[2]:set c,0,1          'cはカメラ(視線)の方向ベクトル
 var rotV=0,rotBrake=0.2     'rotVは旋回速度(角速度),rotBrakeは旋回速度の減速率
 var rotA=calcAccel(rad(1),rotBrake) 'rotAは旋回の加速度(角加速度)
 var vp=0

 spofs 0,p[0],p[1]

 var lastFrame=frame()
 while 1
  if inkey$()==chr$(&h1b) then return
  var now=frame()
  var frames=now-lastFrame
  if frames==0 then continue
  lastFrame=now

  var sx,sy:stick 0 out sx,sy
  var b=button(0)

  while frames>0
   'カメラを回転
   rotV=(rotV+rotA*sx)*rotBrake
   rot c,c,rotV
   norm c,c

   'カメラの方向へ加速
   dim r[2]
   mul r,c,a*(!!(b and B_A)-!!(b and B_B)-sy)
   add v,v,r
   mul v,v,brake
   
   if dist(v)!=0 then
    dim s[2]
    norm s,v
    mul s,s,8
    spcolvec 0,s[0],s[1]
    if sphitsp(0,wallMin,wallMax)<0 then '壁に衝突しなければ,移動する
     add p,p,v
     spofs 0,p[0],p[1]
    endif
   endif

   dec frames
  wend

  '壁のスプライトを表示
  var px=p[0],py=p[1] 'px,pyは,プレイヤーの位置
  var range=h
  var cx=c[0]*range,cy=c[1]*range 'cx,cyは,カメラ(視線)の方向
  dim u[2]:rot90 u,c
  var ux=u[0],uy=u[1] 'ux,uyはカメラと垂直方向
  var x
  for x=0 to w/2-1 '画面の左端から右端に向かって描画
   var t=x-w/2/2
   var xx=px+cx+ux*t,yy=py+cy+uy*t 'xx,yyは注視点=p+camera*400+u*t
   var mag=5
   spcolvec 0,(xx-px)*mag,(yy-py)*mag '注視点を移動ベクトルに設定

   '視線が衝突する壁スプライトを探す
   var i,tt=1,tm,x1,y1,x2,y2
   for i=wallMin to wallMax
    i=sphitsp(0,i,wallMax):if i<0 then break
    sphitinfo out tm,x1,y1,x2,y2
    if tm<tt then tt=tm:xx=round(x1):yy=round(y1)
   next

   var dist=range*mag*tt
   if tt>0 then
    var gx=w/2+t,hh=min(h-1,32*h/dist)
    var rr=lerp(dist,5,300,200,120)
    var gg=lerp(dist,5,300,200,130)
    var bb=lerp(dist,5,300,200,150)
    var sp=t+w/2+1
    var sc=max(1,hh/16)
    spchr 1+x,hh,512,1,h-1
    spcolor 1+x,rgb(rr,gg,bb)
    spshow 1+x
   endif
    
  next
 wend
 
end


'==============================================================
'迷路の作成
'==============================================================
def makeMaze
 spset wallMin+0,512,0,512,1
 spofs wallMin+0,0,-1
 spcol wallMin+0,false
 spset wallMin+1,512,0,512,1
 spofs wallMin+1,0,512
 spcol wallMin+1,false
 spset wallMin+2,512,0,1,512
 spofs wallMin+2,-1,0
 spcol wallMin+2,false
 spset wallMin+3,512,0,1,512
 spofs wallMin+3,512,0
 spcol wallMin+3,false

 var i
 for i=wallMin+4 to wallMax
  spset i,0
  while 1
   var x=rnd(512-16),y=rnd(512-16)
   if sqr(x*x+y*y)>32 then break
  wend
  spofs i,x,y
  spcol i,false
  spcolor i,0
 next
end


'==============================================================
'スプライトと背景グラフィックの初期化
'==============================================================
def initSpGrp
 var i,rr,gg,bb

 'プレイヤーのスプライト(当たり判定に使用する)
 spset 0,0,0,1,1
 spcol 0,false

 '壁のスプライト画像
 gpage 0,sppage()
 var eyeLevel=h/6
 gtri 1,512+h-1-eyeLevel,h-1,512,h-1,512+h-1

 '壁のスプライト定義
 for i=0 to w/2-1
  var sp=1+i
  spset sp,0,512,0,h-1
  spofs sp,i*2,0,1
  spscale sp,2,1
 next

 '空
 gpage 0,0
 var skyHeight=h-eyeLevel
 for i=0 to skyHeight
  var gy=h-eyeLevel-i
  rr=lerp(i,30,skyHeight,200,90)
  gg=lerp(i,30,skyHeight,200,162)
  bb=lerp(i,30,skyHeight,200,255)
  gline 0,gy,w-1,gy,rgb(rr,gg,bb)
 next

 '地面
 for i=eyeLevel to 0 step -1
  gy=h-1-i
  rr=lerp(i,eyeLevel,0,100,192)
  gg=lerp(i,eyeLevel,0,110,192)
  bb=lerp(i,eyeLevel,0,130,192)
  gline 0,gy,w-1,gy,rgb(rr,gg,bb)
 next

 'ロゴ
 spset spLogo,4095
 spofs spLogo,w-8*7,h-12
end


'==============================================================
'ユーティリティ
'==============================================================

'60Hzを基準としたフレーム数
'--------------------------------------------------------------
def frame():return floor(millisec*60/1000):end

'補間
'--------------------------------------------------------------
def lerp(x,inStart,inEnd,outStart,outEnd)
 var inDiff=inEnd-inStart
 var outDiff=outEnd-outStart
 var outMin=min(outStart,outEnd)
 var outMax=max(outStart,outEnd)
 return max(outMin,min(outMax,outStart+(x-inStart)/inDiff*outDiff))
end

'加速度を計算
'--------------------------------------------------------------
def calcAccel(vMax,brake)
 return vMax*(1/brake-1)
end


'２次元ベクトル演算
'--------------------------------------------------------------
def prnt a:?format$("%6.2f,%6.2f",a[0],a[1]):end
def set a,x,y:a[0]=x:a[1]=y:end
def add c,a,b:c[0]=a[0]+b[0]:c[1]=a[1]+b[1]:end
def mul c,a,b:c[0]=a[0]*b:c[1]=a[1]*b:end
def divd c,a,b:c[0]=a[0]/b:c[1]=a[1]/b:end
def dist(a):return sqr(a[0]*a[0]+a[1]*a[1]):end
def iprod(a,b):return a[0]*b[0]+a[1]*b[1]:end
def norm c,a:divd c,a,dist(a):end
def rot c,a,t:var sn=sin(t),cs=cos(t),a0=a[0],a1=a[1]:c[0]=a0*cs-a1*sn:c[1]=a0*sn+a1*cs:end
def rot90 c,a:var a0=a[0],a1=a[1]:c[0]=-a1:c[1]=a0:end
def flor c,a:c[0]=floor(a[0]):c[1]=floor(a[1]):end
def equal(a,b):return a[0]==b[0]&&a[1]==b[1]:end


