option strict
'============================================================
' 手まり柄生成プログラム by みなつ
'
'♦入力ファイルは、1000x1000ドットのpngファイルです。同心円状のテクスチャを描いておくとよいです。
'♦変換後、自動保存されます。
'
var infile$="TemariTextureExample.png" '入力ファイル名
var outfile$="out.png" '出力ファイル名
var os=4      'オーバーサンプリングの値(1だとオーバーサンプリングなし)
'============================================================
acls:tprio -1
var w,h,aspect:xscreen out w,h,aspect
var refPage=1,outPage=2 'テクスチャ参照ページと、出力ページ
var cx1=512,cx2=512,cy=512
var r=500,r2=r*r,PI2=PI()/2,os2=os*os

sppage outPage:spset 0, 0,0,1024,1024
var scl=h/1024:spscale 0,scl,scl

load format$("grp%d:%s",refPage,infile$),cx1-r,cy-r
if result!=1 then ?format$("[%s]が読み込めませんでした。",infile$):stop
spherecopy rad(-60) '上方に６０度傾ける
save format$("grp%d:%s",outPage,outfile$)

def spherecopy th
 var x,y
 for y=-r to r
  for x=-r to r
   if (x*x+y*y)/r2>1 then continue
   var x1,y1,r1=0,g1=0,b1=0,stp=1/os
   gpage 0,refPage
   for y1=y to y+1-stp step stp
    for x1=x to x+1-stp step stp
     var cs2=(x1*x1+y1*y1)/r2
     if cs2>1 then continue
     var z1=sqr(1-cs2)*r
     var x2=x1,y2=y1*cos(th)-z1*sin(th),z2=y1*sin(th)+z1*cos(th)
     var th2=acos(abs(z2)/r),d1=th2*r/PI2,d=sqr(x2*x2+y2*y2)
     var x3,y3
     if d then x3=x2/d*d1:y3=y2/d*d1
     var rr,gg,bb:rgbread gspoit(cx1+x3,cy+y3) out rr,gg,bb
     r1=r1+rr:g1=g1+gg:b1=b1+bb
    next
   next
   gpage 0,outPage:gpset cx2+x,cy+y,rgb(r1/os2,g1/os2,b1/os2)
  next
 next
end
