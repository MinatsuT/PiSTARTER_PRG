acls
xscreen out sw,sh,sa

cx=sw/2:cy=sh/2
r=cy*0.8

stp=1
while 1
 for j=0 to 360
  for i=0 to 360 step stp
   x1=cx+r*cos(rad(i))
   y1=cy+r*sin(rad(i))
   x2=cx+r*cos(rad(i+stp))
   y2=cy+r*sin(rad(i+stp))
   c=hsv(i+90+j,0,0)
   gtri cx,cy, x1,y1, x2,y2, c
  next
 next
wend

def hsv(h,s,v)
 var r,g,b
 gh=((h-60*1+180) mod 360)-180
 bh=((h-60*3+180) mod 360)-180
 rh=((h-60*5+180) mod 360)-180

 g=max(0,120-abs(gh))/60 *255
 b=max(0,120-abs(bh))/60 *255
 r=max(0,120-abs(rh))/60 *255
 return rgb(r,g,b)
end
