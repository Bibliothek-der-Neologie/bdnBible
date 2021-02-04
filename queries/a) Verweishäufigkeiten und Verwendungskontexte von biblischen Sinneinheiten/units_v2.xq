xquery version "3.1";

import module namespace bdn = "http://bdn-edition.de/xquery/bdn" at "bdn.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/html";

declare variable $bible := doc("Luther1912Apo.xml");
declare variable $xml := doc("griesbach_full.xml");

declare function local:list-units($b)
{
  $b//unit
};

declare function local:book($u)
{
  $u/ancestor::BIBLEBOOK/@bsname/data()
};

declare function local:chapter($u)
{
  fn:number($u/ancestor::CHAPTER/@cnumber/data())
};

declare function local:verse-min($u)
{
  fn:number(($u/VERS)[1]/@vnumber/data())
};

declare function local:verse-max($u)
{
  fn:number(($u/VERS)[last()]/@vnumber/data())
};

declare function local:process-verse-unit($u)
{
<unit book="{local:book($u)}" from-chapter="{local:chapter($u)}" from-verse="{local:verse-min($u)}" to-chapter="{local:chapter($u)}" to-verse="{local:verse-max($u)}" name="{$u/@name}"></unit>
};

declare function local:process-ref-unit($u)
{
  let $components := fn:tokenize($u/@ref, " ")  
  let $book := local:book($bible//unit[@xml:id = $components[1]])
  let $chapter-min := local:chapter($bible//unit[@xml:id = $components[1]])
  let $chapter-max := local:chapter($bible//unit[@xml:id = $components[last()]])
  let $verse-min := local:verse-min($bible//unit[@xml:id = $components[1]])
  let $verse-max := local:verse-max($bible//unit[@xml:id = $components[last()]])
  return
  <unit book="{$book}" from-chapter="{$chapter-min}" from-verse="{$verse-min}" to-chapter="{$chapter-max}" to-verse="{$verse-max}" name="{$u/@name}"></unit>
};

declare function local:process-chapter-units($u)
{  
  let $book := local:book($u//unit[1])
  let $chapter-min := ($u//CHAPTER/@cnumber)[1]
  let $chapter-max := ($u//CHAPTER/@cnumber)[last()]
  let $verse-min := ($u//VERS/@vnumber)[1]
  let $verse-max := ($u//VERS/@vnumber)[last()]
  return
  <unit book="{$book}" from-chapter="{$chapter-min}" from-verse="{$verse-min}" to-chapter="{$chapter-max}" to-verse="{$verse-max}" name="{$u/@name}"></unit>
};

declare function local:units($b)
{
  for $u in $b//unit
  return 
    if ($u[@ref]) then local:process-ref-unit($u)
    else if ($u//CHAPTER) then local:process-chapter-units($u)
    else local:process-verse-unit($u)    
};

declare function local:unit-n-refs($u, $x)
{
  let $xml-n-refs := $x//tei:citedRange/@n/data(fn:tokenize(., " "))
  let $relevant := $xml-n-refs[
    ( (fn:tokenize(., ":"))[1] eq $u/@book/data() ) and
    ( fn:number(fn:tokenize(., ":")[2]) ge $u/@from-chapter/fn:number() and 
      fn:number(fn:tokenize(., ":")[2]) le $u/@to-chapter/fn:number() ) and
    ( fn:number(fn:tokenize(., ":")[3]) ge $u/@from-verse/fn:number() and 
      fn:number(fn:tokenize(., ":")[3]) le $u/@to-verse/fn:number() )
]
return $relevant
};

declare function local:unit-fromto-refs($u, $x)
{
  let $relevant := $x//tei:citedRange[
    ( @from/fn:tokenize(., ":")[1] eq $u/@book ) and
    ( @from/fn:number(fn:tokenize(., ":")[2]) ge $u/@from-chapter/fn:number() ) and
    ( @from/fn:number(fn:tokenize(., ":")[3]) ge $u/@from-verse/fn:number() )
    
    and 
    
    ( @to = "f" or 
      @to = "ff" or 
    ( @to/fn:tokenize(., ":")[1] eq $u/@book and 
      @to/fn:number(fn:tokenize(., ":")[2]) le $u/@to-chapter/fn:number() and 
      @to/fn:number(fn:tokenize(., ":")[3]) le $u/@to-verse/fn:number() )  ) 
  ]
  return $relevant
};

(: local:units($bible) :)

let $ualt := $bible//unit[@xml:id="id_prie_1"]
let $u := local:process-verse-unit($ualt)
return local:unit-fromto-refs($u, $xml)

(: <table>{
for $u in local:units($bible)
return 
<row>
<cell>{$u/@name}</cell>
<cell>{fn:count(local:unit-fromto-refs($u, $xml)) + fn:count(local:unit-n-refs($u, $xml))}</cell>
</row>
}</table> :)

    

