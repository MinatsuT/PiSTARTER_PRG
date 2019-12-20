acls
w=640:h=360 'Width, Height
xscreen w,h

cx=w/2:cy=50 '消失点
gline  0,cy,  w,cy
gline cx, 0, cx, h


r=200:th=0
while 1
 th=th+rad(1)
 x=r*cos(th):z=r*sin(th)
 
 if z>0 then
  spset 0,0:sphome 0,8,8
  spset 1,0:sphome 1,8,8
 else
  spset 0,1:sphome 0,8,8
  spset 1,1:sphome 1,8,8
 endif
 
 spofs3d 0, x, 0,z
 spofs3d 1, x,50,z
 vsync
wend

def spofs3d sp,x,y,z
 c=300 'カメラを画面からどれくらい手前に設置しているのかという距離
 d=c+z 'カメラから物体への距離。(Zは奥に正としている)
 scale=(1/d)*c '拡大率はカメラからの距離dに反比例する。z=0(すなわちd=c)のとき拡大率を1としたいので、cをかける。
 spofs sp, cx+x*scale,cy+y*scale
 spscale sp, scale,scale
 
 if sp==1 then
  xx=cx
  if z>0 then
   gpset cx+x*scale,cy+y*scale,rgb(0,255,0)
   gline xx,cy+y,cx+x*scale,cy+y*scale,rgb(0,255,0)
  else
   gpset cx+x*scale,cy+y*scale,rgb(255,0,0)
   gline xx,cy+y,cx+x*scale,cy+y*scale,rgb(255,0,0)
  endif
 endif
end
