xquery version "3.1";
import module namespace bdn = "http://bdn-edition.de/xquery/bdn" at "modules/bdn.xqm";
import module namespace units = "http://bdn-edition.de/xquery/units" at "modules/units.xqm";
import module namespace freq = "http://bdn-edition.de/xquery/freq" at "modules/frequency.xqm";
import module namespace crit = "http://bdn-edition.de/xquery/crit" at "modules/crit.xqm";
import module namespace xqdoc-to-html = 'http://basex.org/modules/xqdoc-to-html' at "xqdoc-to-html/xqdoc-to-html.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare variable $bible := doc("data/bible_structure.xml");
declare variable $no_conv := doc("data/converted/nö.xml");
declare variable $gr_conv := doc("data/converted/gr.xml");
declare variable $le_conv := doc("data/converted/le.xml");
declare variable $te_conv := doc("data/converted/te.xml");
declare variable $st_conv := doc("data/converted/st.xml");
declare variable $sa_conv := doc("data/converted/sa.xml");


(: Zwischenformat generieren :)

(: ... mit textkritischen Profilen :)
(: doc("data/griesbach_full.xml") => bdn:convert() :) 


(: ... mit Apparaten :)
(: doc("data/less_full.xml") => bdn:convert1() :) 


(: ... in Datei schreiben (s. data/converted/) :)
(: bdn:convert_write(doc("data/bahrdtsemler_full.xml")) :)



(: a) Verweishäufigkeiten und Verwendungskontexte von biblischen Sinneinheiten :)

(: Datei units_equal.xml aktualisieren :)
(: units:equalunits(doc("data/units.xml"), doc("data/bible_structure.xml")) :)

(: Auflistung aller Entsprechungen zu allen Sinneinheiten in einem oder mehreren Bänden :)
(: units:collect_chapter(($te_conv, gr_conv)) :)
(: units:collect_verse(($te_conv, gr_conv)) :)

(: HTML-Vergleich (s. output) :)
units:compare(($gr_conv, $st_conv), "verse") 


(: b) Bibelstellendichte und relative Häufigkeiten :)

(: freq:table_all($st_conv, $bible) :) 

(: freq:table_spec($te_conv, $bible, "Röm") :)

(: freq:count_spec($gr_conv, "Röm") :)

(: Ausgabe der Referenzhäufigkeit für jedes biblische Buch (s. output) :)
(: freq:table2($te_conv) :)



(: c) Bibelstellen und Textvarianz :)

(: crit:window($gr_conv) :)

(: Abfrage für @type="om", @type="pt" und @type="ptl" :)
(: Ergebnis lässt sich mit bdn:citedRange nicht verarbeiten :)

(: $gr_full//tei:rdg[@type="om"]//preceding-sibling::tei:lem//tei:citedRange :)  (: = Variable "$gr_om" :)
(: $gr_full//tei:rdg[@type="pt"]//tei:citedRange :) (: = Variable "$gr_pt" :)
(: $gr_full//tei:rdg[@type="ptl"]//tei:citedRange :) (: = Variable "$gr_ptl" :)

(: crit:register($gr_conv) :)
(: crit:register_table($te_conv) :)



(: HTML-Dokumentation erzeugen :)

(: xqdoc-to-html:create(
  file:base-dir() || 'modules/',
  file:base-dir() || 'documentation/',
  'Documentation',
  false()
) :)



