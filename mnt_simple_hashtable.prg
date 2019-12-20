option strict
cls
put "orange"   ,"みかん"          '[orange]=みかん       をセット
put "apple"    ,"りんご"          '[apple]=りんご        をセット
put "pineapple","パイナップル"       '[pineapple]=パイナップル をセット

?"apple="    +get$("apple")    '[apple]を取得
?"orange="   +get$("orange")   '[orange]を取得
?"pineapple="+get$("pineapple")'[pineapple]を取得

put "apple"    ,"アポー"          '[apple]=アポー をセット("りんご"は上書きされる)
?:?"apple="+get$("apple")      '[apple]を取得

del("apple")                   '[apple]を削除
?:?"apple="+get$("apple")
end

'==================================================
'INSTRまかせの簡易連想配列 by みなつ
'==================================================
var HT$
def put k$,v$
 del k$
 inc HT$,chr$(0)+k$+chr$(1)+chr$(len(v$))+v$ '(0)+key+(1)+len+val のフォーマット
end

def get$(k$)
 var p=find(k$)
 if p<0 then return ""
 var l=p+len(k$)+2
 return mid$(HT$,l+1,asc(HT$[l]))
end

def del k$
 var p=find(k$)
 if p<0 then return
 var l=p+len(k$)+2
 HT$=subst$(HT$,p,len(k$)+3+asc(HT$[l]),"")
end

def find(k$)
 return instr(HT$,chr$(0)+k$+chr$(1))
end

