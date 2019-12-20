'ザ タワー オブ ゴルフ by みなつ
option strict:acls:var w=640,h=360:xscreen w,h:backcolor rgb(0,128,255)
padmode 0:var cw=128,ch=96,gw=cw*8,gh=ch*8,hole,shot,total
for hole=1 to 9
 makestage
 game
next
locate 0,1:?"おつかれさまでした!"
end

def game 'ゲームほんぺん
 var x=16,y=gh-9,vx,vy,bx,by,dr=90,pw=32,pmx,brk=0.4,g=0.1,ph=0,bd,cupin=0
 shot=1:inc total:putstat
 while cupin==0
  if ph==0 then 'ほうこうとパワーをきめるフェーズ
   if gspoit(x,y+1)==#yellow then pmx=8 else pmx=32 'バンカーではさいだいパワーげんしょう
   inc dr,(button(0,#BID_LEFT)-button(0,#BID_RIGHT))*2 'ほうこう(direction)
   inc pw,button(0,#BID_UP)-button(0,#BID_DOWN) 'パワー
   dr=max(1,min(179,dr)):pw=max(1,min(pmx,pw)) 'ほうこうとパワーのはんいをせいげんする
   spscale 1,1,pw/32:sprot 1,90-dr:spcolor 1,rgb(255,255*(1-pw/32),0)
   if button(0,#BID_A) then 'ショットボタンがおされたら、ボールいどうフェーズへいこう
    var th=rad(dr),p=sqr(pw)*2.5:vx=cos(th)*p:vy=-sin(th)*p
    sphide 1:beep 91,1000:ph=1
   endif
  else 'ボールのいどうフェーズ
   var i,l=ceil(sqr(vx*vx+vy*vy)) 'ボールがかべをすりぬけるのをふせぐため、lかいのみじかいいどうにぶんかつする
   for i=0 to l-1
    bd=0:inc vy,g/l 'じゅうりょくかそくどをvyにくわえる
    if gspoit(x+vx/l,y+vy/l)==#red then cupin=1:break 'カップインのはんてい
    var s=gspoit(x,y+vy/l),bpw=brk/(1+(s==#yellow)) 'バンカーではブレーキ2ばい
    if s then vy=-bpw*vy:vx=bpw*vx:bd=1 'じょうげのマスにしょうとつしたら、vyをはんてん
    if gspoit(x+vx/l,y) then vx=-bpw*vx:bd=1 'さゆうのマスにしょうとつしたら、vxをはんてん
    if !gspoit(x,y+vy/l) then inc y,vy/l 'ボールのYざひょうをこうしん
    if !gspoit(x+vx/l,y) then inc x,vx/l 'ボールのXざひょうをこうしん
    if gspoit(x,floor(y)+1) && abs(vy)<g then 'ボールのていしはんてい
     inc shot:inc total:putstat:ph=0:pw=32:spshow 1:break
    endif
    if bd then beep 48 'バウンドするおと
   next
  endif
  'ボールとがめんのスクロールいちをこうしん
  bx=x-w/2:by=y-h/2:bx=max(0,min(gw-w,bx)):by=max(-8,min(gh-h,by))
  gofs bx,by:spofs 0,x-bx,y-by:spofs 1,x-bx,y-by:vsync
 wend
 beep 90:beep 89:wait 180 'カップイン!
end

def putstat 'ステータスをこうしん
 gpage 0,3:gfill 0,32,w-1,32+7,#black 'ステータスひょうじエリアをクリア
 var s$=format$("ホール:%d ショット:%d トータル:%d アベレージ:%.1f",hole,shot,total,total/hole)
 gputchr (w-len(s$)*8)/2,32,s$:gpage 0,0
end

def makestage 'ステージのさくせい
 var i,x,y,l,p,b=12-hole,c,green=rgb(0,220,0)
 gpage 0,0:gcls:gfill 0,0,gw-1,gh-1,green:gfill 8,8,gw-9,gh-9,0 'そとわく
 for p=0 to cw*(ch/16-1)-1 'じめんをつくる
  l=rnd(b*4) 'じめんのながさ
  if !rnd(5+b) then c=#yellow else c=green 'ランダムでバンカーにする
  for i=1 to l:x=p mod (cw-2):y=p div (cw-2):putg 1+x,(1+y)*16,c:inc p:next
  inc p,b+rnd(b*3) 'すきまのながさぶんだけスキップする
 next
 'カップのいちきめ、ゴールのマスをおく
 dim o[cw-2]
 for i=0 to cw-3:o[i]=i+1:next 'Xほうこうのマスのざひょうをいれる
 for i=0 to cw-3:swap o[i],o[rnd(cw-2)]:next 'ざひょうをシャッフル
 for i=0 to cw-4:if gspoit(o[i]*8,16*8) then break:endif:next 'じめんがあるかチェック
 putg o[i],15,#red 'カップをびょうが
 'ホールすうをひょうじ&アニメ
 gpage 0,3:gcls:c=rgb(64,255,255,255) 'ひょうじはんいをクリア
 gputchr 160,512+150,format$("HOLE %d/9",hole),5,5 'ホールすうをひょうじ
 spset 3,0,512,w,h:spofs 3,0,0:spanim 3,"C",1,0,-30,c,400,c,-60,0 'いろのアニメ
 'ステージぜんたいをスクロールしてひょうじ
 scrl    0,gh-h,0,-4,gh-h:scrl    0,   0, 4,0,gw-w 'うえいどう、みぎいどう
 scrl gw-w,   0,0, 4,gh-h:scrl gw-w,gh-h,-4,0,gw-w 'したいどう、ひだりいどう
 'スプライトのさくせい
 gpage 0,3:gcls
 gfill 0,0,4,4:spset 0,0,0,5,5:sphome 0,2,4 'ボール
 gline 8,0,8,31:gtri 8,0,5,2,11,2:spset 1,5,0,7,32:sphome 1,3,31 'やじるし
 spset 2,0,32,w,8:spofs 2,0,0:spcolor 2,rgb(192,255,255,255) 'ステータスひょうじよう
end

def putg x,y,c:gfill x*8,y*8,x*8+7,y*8+7,c:end 'じめんをびょうが

def scrl x,y,a,b,l 'ステージをスクロール
 var i:for i=0 to l step 4:gofs x,y:inc x,a:inc y,b:vsync:next:wait 30
end
