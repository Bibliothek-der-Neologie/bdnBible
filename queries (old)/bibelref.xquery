xquery version "3.1";

import module namespace main = "http://bdn-edition.de/xquery/main" at "modules/main.xqm";
import module namespace chapter = "http://bdn-edition.de/xquery/chapter" at "modules/chapter.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/html";

declare variable $bible-structure := doc("data/bibel_structure.xml");
declare variable $luther-bibel := doc("data/bibel_luther_1912_apo.xml");
declare variable $griesbach := doc("data/griesbach_full.xml");
declare variable $nösselt := doc("data/nösselt_full.xml");



(: 
Hier wird die Funktion chapter:edition-stats() aus dem Modul chapter.xqm ausgeführt und zwar für den Leittext (repräsentiert durch die lehren runden Klammern"()".
Wenn ihr das für eine andere Auflage erzeugen wollt, dann gebt einfach den Buchstaben der Auflage da an, wo jetzt die beiden Klammern stehen, z.B. chapter:edition-stats($griesbach, "a"))
Das Format, was ihr nach der Konversion seht ist XML, geordnert nach Kapiteln, Sektionene und darin die Bibelstellen. Ich spreche dann immer von "Zwischenformat", weil man das dann in andere Analyseprozesse 
einpflegt; nur zur Info. Schaut euch doch die Infos mal an, die in dem Output stehen. Ansonsten schaut doch auch mal in die entsprechenden Module im "modules" Ordner
:)
let $griesbach-statistik := chapter:edition-stats($griesbach, ())
return $griesbach-statistik


(:Probiert es dochmal mit der c Auflage:)
(:let $griesbach-statistik := chapter:edition-stats($griesbach, "c")
return $griesbach-statistik:)







(:## Spielwiese ##:)

(:let $order := main:bibel-order($bible-structure)
return main:bibel-stellen($griesbach, $order):)

(:main:chapter-refs($griesbach):)

(:let $griesbach-stellen := main:bibel-stellen( $griesbach ):)
(:return $griesbach-stellen:)

(:let $n := $griesbach-stellen[tei:citedRange/@from]
(\:return main:parse-bibel-refs($n):\)
return main:parse-bibel-refs($griesbach-stellen)//ref:)

(:main:ref2luther("Joh:5:19", $luther-bibel, $bible-structure):)
(:main:link-ref-to-index( "Joh:5:19", $bible-structure ):)
(:main:book2index( "Joh", $bible-structure ):)
(:main:index-book-stats( "Joh", $bible-structure ):)
