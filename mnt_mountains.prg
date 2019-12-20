option strict
acls
var w=640,h=360
xscreen w,h

var size=512 'やまのよこはば
dim t[size+1] 'たかさをかくのうするはいれつ
backcolor rgb(0,128,255)

while 1
 'しょきか
 fill t,0:t[size/2]=rndf()
 var stp=size/2 'ちゅうてんをもとめるときのはば
 var range=1.0  'らんすうのはば

 repeat
  var i
  for i=0 to size-1 step stp
   t[i+stp/2] = (t[i]+t[i+stp])/2+range*(rndf()-0.5) 'ちゅうてんのたかさ
  next
  stp=stp/2     'ちゅうてんをもとめるはばを1/2に
  range=range/2 'らんすのんばも1/2に
 until stp<2 'ちゅうてんをもとめるは2みまんになったらしゅうりょう

 var bottom=h*0.8
 gcls:gfill 0,bottom,w,h,#green
 var ofs=(w-size)/2
 for i=0 to size-1
  var col=#green
  if t[i]<0 then col=#blue 'たかさが0みまんのばあいは、あおにする
  gline ofs+i,bottom, ofs+i,bottom-t[i]*bottom,col
 next
 vsync 60
wend

