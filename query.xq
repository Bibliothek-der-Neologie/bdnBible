(: xquery version "3.1"; :)
import module namespace bdn = "http://bdn-edition.de/xquery/bdn" at "modules/bdn.xqm";
import module namespace units = "http://bdn-edition.de/xquery/units" at "modules/units.xqm";
import module namespace freq = "http://bdn-edition.de/xquery/freq" at "modules/frequency.xqm";
import module namespace crit = "http://bdn-edition.de/xquery/crit" at "modules/crit.xqm";
import module namespace xqdoc-to-html = 'http://basex.org/modules/xqdoc-to-html' at "xqdoc-to-html/xqdoc-to-html.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare variable $bible := doc("data/bible_structure.xml");
declare variable $no_conv := doc("data/converted/noesselt.xml");
declare variable $gr_conv := doc("data/converted/griesbach.xml");
declare variable $gr_full := doc("data/griesbach_full.xml");
declare variable $le_conv := doc("data/converted/less.xml");
declare variable $te_conv := doc("data/converted/teller.xml");
declare variable $st_conv := doc("data/converted/steinbart.xml");
declare variable $sa_conv := doc("data/converted/sack.xml");

declare variable $gr_om := $gr_full//tei:rdg[@type="om"]//preceding-sibling::tei:lem//tei:citedRange;
declare variable $gr_pt := $gr_full//tei:rdg[@type="pt"]//tei:citedRange;
declare variable $gr_ptl := $gr_full//tei:rdg[@type="ptl"]//tei:citedRange;


(: Zwischenformat generieren :)
(: doc("data/griesbach_full.xml") => bdn:convert() :)


(: a) Verweishäufigkeiten und Verwendungskontexte von biblischen Sinneinheiten :)

(: Bibelstellen den Sinneinheiten zuordnen :)
(: units:listitems($gr_conv) :) 

(: Auflistung aller im Band vorkommenden Sinneinheiten inkl. entsprechender Refs :)
(: units:listitems($gr_conv) => units:group() :) 

(: Vergleich zweier oder mehrer Bände :)
(: units:compare(($gr_conv, $st_conv, $sa_conv)) :)


(: b) Bibelstellendichte und relative Häufigkeiten :)

(: freq:table2($gr_conv, $bible) :)

(: freq:table_all($st_conv, $bible) :) 

(: freq:table_spec($te_conv, $bible, "Röm") :)

(: freq:count_spec($gr_conv, "Röm") :)


(: c) Bibelstellen und Textvarianz :)

crit:window($gr_conv)

(: Abfrage für @type="om", @type="pt" und @type="ptl" :)
(: Ergebnis läst sich mit bdn:citedRange nicht verarbeiten :)

(: $gr_full//tei:rdg[@type="om"]//preceding-sibling::tei:lem//tei:citedRange :)  (: = Variable "$gr_om" :)
(: $gr_full//tei:rdg[@type="pt"]//tei:citedRange :) (: = Variable "$gr_pt" :)
(: $gr_full//tei:rdg[@type="ptl"]//tei:citedRange :) (: = Variable "$gr_ptl" :)


(: HTML-Dokumentation erzeugen :)

(: xqdoc-to-html:create(
  file:base-dir() || 'modules/',
  file:base-dir() || 'documentation/',
  'Documentation',
  false()
) :)



