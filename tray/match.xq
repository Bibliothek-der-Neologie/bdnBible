xquery version "3.1";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $node := doc("data/sack_4_5_a70-92.xml");
declare variable $bible := doc("data/bibel_luther_1912_apo.xml");

(:~ 
:
: Konversion: In einem Textparagraphen wird jeder Satz in ein phrase-Element geschrieben, um darin "contains text" zu testen.
: Todo: vgl. die Arbeiten von Marco Büchner zu den Themen "Text Re-Use" / "Paraphrasierung" / "Zitat-Findung"; Umwandlung in Modul
: @author BdN
: @version 1.0
:)


declare function local:convert($node){
  typeswitch($node)  
  case element(div) return <div>{local:passthru($node)}</div>   
  case element(p) return <p>{local:phrases($node)}</p>
  case element(note) return <note>{local:passthru($node)}</note>
  case element(bibl) return local:bibl($node)
  default return local:passthru($node)
};

(:~ 
:
: Tokenisierung
: Todo: Umwandlung in small-caps, Eliminierung von Satzzeichen, Tokenliste pro Satz
: @author BdN
: @version 1.0
:)

declare function local:phrases($node) 
{
  for $phrase in fn:tokenize($node//text(), "[.]")
  count $n
  return <phrase n="{$n}">{fn:normalize-space($phrase) || "."}</phrase>
};

declare function local:bibl($node)
{
  let $n-value := fn:tokenize($node/citedRange/@n, ":") 
  return <ref book="{$n-value[1]}" chapter="{$n-value[2]}" verse="{$n-value[3]}"></ref>
};

declare function local:passthru
  ($nodes as node()*) as item()* {
  for $node in $nodes/node() return local:convert($node)
};


(:~ 
: Diese Funktion sucht einen vorgegebenen Bibelvers $book, $chapter, $verse in der Lutherbibel und gibt den Text aus.
:
: @author BdN
: @version 1.0
::)


declare function local:search($book, $chapter, $verse)
{
 $bible//BIBLEBOOK[@bsname = $book]/CHAPTER[@cnumber = $chapter]/VERS[@vnumber = $verse]  
};


(: contains text mit Bibelvers :)

declare function local:score($node, $book, $chapter, $verse)
{
  let $match := local:search($book, $chapter, $verse)
  
  let $lines := local:convert($node)/p/phrase
  
  for $line score $score in $lines[. contains text {$match/text()} any word]
  order by $score descending
  return $line
    transform with
    { insert node attribute score { $score } into . }
};


(:~ 
: Diese Funktion durchsucht die Sätze eines Textabschnitts nach Entsprechungen in der Lutherbibel.
:
: @author BdN
: @version 1.0
::)

declare function local:score2($node, $book, $chapter, $verse)
{
  let $lines := local:convert($node)/p/phrase
  
  let $match := local:search($book, $chapter, $verse)
  let $tokens := fn:tokenize($match)
  
  for $line in $lines
  let $count := fn:count($tokens[fn:contains($line, .)])
  let $word-count := fn:count(fn:tokenize($line))
  return <line count="{$count}" rel="{$count div $word-count}">{$line}</line> 
};

(: local:convert($node) :)

(: 10.2 contains text :)

(: let $lines := local:convert($node)/p/phrase
for $line in $lines
where $line contains text "gnädig"
return $line :)


(: 10.2.1 scoring :)

(: let $lines := local:convert($node)/p/phrase
for $line score $score in $lines[. contains text "gnädig"]
order by $score descending
return $line
  transform with
  { insert node attribute score { $score } into . } :)
  

(: 10.2.2 any-all options :)

(: let $lines := local:convert($node)/p/phrase
for $line in $lines
where $line contains text { "gnädig", "und", "barmherzig" } all 
return $line :)


(: 10.2.3 cardinality :)

(: let $lines := local:convert($node)/p/phrase
for $line in $lines
where $line contains text { "erbarmet" } occurs at least 2 times
return $line :)


(: 10.2.4 positional filters :)

(: let $lines := local:convert($node)/p/phrase
for $line in $lines[. contains text ("gnädig" ftor "barmhertzig")]
return $line :) 


(: Bestimmten Vers in der Lutherbibel 1912 suchen und tokenisieren! :)

(: local:search("Ps", 145, 8) :)


(: contains text mit Bibelvers :)

(: local:score($node, "Ps", 145, 8) :)


(: Neuer Versuch mit fn:contains() :)

local:score2($node, "Ps", 145, 8)


(: Erinnerung: Konvertierter Paragpraph! Jede angegebene Bibelstelle mit jedem Satz vergleichen? :)

(: local:convert($node) :)