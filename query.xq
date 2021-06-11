xquery version "3.1";
import module namespace bdn = "http://bdn-edition.de/xquery/bdn" at "modules/bdn.xqm";
import module namespace units = "http://bdn-edition.de/xquery/units" at "modules/units.xqm";
import module namespace freq = "http://bdn-edition.de/xquery/freq" at "modules/frequency.xqm";
import module namespace crit = "http://bdn-edition.de/xquery/crit" at "modules/crit.xqm";
import module namespace xqdoc-to-html = 'http://basex.org/modules/xqdoc-to-html' at "xqdoc-to-html/xqdoc-to-html.xqm";


declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $bible := doc("data/bibel_structure.xml");
declare variable $units := doc("data/units.xml");
declare variable $equalunits := units:equalunits($units, $bible);

declare variable $gr := doc("data/griesbach_full.xml");
declare variable $gr_small := doc("data/griesbach_small.xml");
declare variable $gr_converted := bdn:convert($gr);
declare variable $gr_converted_doc := doc("data/converted/griesbach.xml"); (: bdn:convert($gr) als XML abgespeichert. :)
declare variable $gr_items := units:listitems($gr_converted, $equalunits);
declare variable $gr_unit_groups := units:group($gr_items);

declare variable $noe := doc("data/nösselt_full.xml");
declare variable $noe_converted := bdn:convert($noe);
declare variable $noe_items := units:listitems($noe_converted, $equalunits);
declare variable $noe_unit_groups := units:group($gr_items);

declare variable $bs := doc("data/bahrdtsemler_full.xml");
declare variable $bs_converted := bdn:convert($bs);
declare variable $bs_items := units:listitems($bs_converted, $equalunits);
declare variable $bs_unit_groups := units:group($bs_items);

declare variable $le := doc("data/less_full.xml");
declare variable $le_converted := bdn:convert($le);
declare variable $le_items := units:listitems($le_converted, $equalunits);
declare variable $le_unit_groups := units:group($le_items);

declare variable $te := doc("data/teller_full.xml");
declare variable $te_converted := bdn:convert($te);
declare variable $te_items := units:listitems($te_converted, $equalunits);
declare variable $te_unit_groups := units:group($te_items);

declare variable $st := doc("data/steinbart_full.xml");
declare variable $st_converted := bdn:convert($st);
declare variable $st_items := units:listitems($st_converted, $equalunits);
declare variable $st_unit_groups := units:group($st_items);

declare variable $sa := doc("data/sack_test.xml");
declare variable $sa_converted := bdn:convert($sa);
declare variable $sa_items := units:listitems($sa_converted, $equalunits);
declare variable $sa_unit_groups := units:group($sa_items);

declare variable $collection := <collection>{($noe_items, $gr_items, $bs_items, $le_items, $te_items, $st_items)}</collection>;

(: Zwischenformat generieren :)

bdn:convert(doc("data/less_full_11-06-2021.xml"))
(: bdn:convert(doc("data/sack_full_11-06-2021.xml")) :)


(: a) Verweishäufigkeiten und Verwendungskontexte von biblischen Sinneinheiten :)

(: units:compare($collection, "verse") :)
(: units:group($gr_items) :)


(: b) Bibelstellendichte und relative Häufigkeiten :)

(: freq:table2($gr_converted, $bible) :)
(: freq:table($gr) :)

(: freq:table_all($st_converted, $bible) :) 

(: freq:table_spec($te_converted, $bible, "Röm") :)

(: freq:count_spec($gr_converted, "Röm") :)


(: c) Bibelstellen und Textvarianz :)

(: crit:window($gr_converted) :)





(: HTML-Dokumentation erzeugen :)

(: xqdoc-to-html:create(
  file:base-dir() || 'modules/',
  file:base-dir() || 'documentation/',
  'Documentation',
  false()
) :)



