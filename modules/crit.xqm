xquery version "3.1";
module namespace crit = "http://bdn-edition.de/xquery/crit";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~
: Diese Funktion ist ein erster Versuch, die konvertierte XML über ein
: "tumbling window" zu sortieren: Hier sollen alle Bibelstellen
: zusammengefasst werden, die im Zwischenformat das gleiche Bibelstellenprofil 
: aufweisen. Das funktioniert aber noch nicht vollständig ...
:
: Todo: Eingrenzen auf Hinzufügungen und Löschungen.
: Fragen:   1.) Texkritik:  Fallen Verse aufgrund einer veränderten Lesart weg? 
:           2.) Auslegung:  Wo treten über die Auflagen hinweg die größten Veränderungen innerhalb des Werks auf? 
:                           Hängen diese mit einer veränderten Auslegung bestimmter Verse zusammen?
:
: @version 0.1 (2021-02-23)
: @author ..., Marco Stallmann
:
:)

declare function crit:window($doc)
{
  (: $doc :)
  
  for tumbling window $b in $doc//bibl
  start $start-bibl
  next $next-bibl
  when fn:deep-equal($start-bibl/profile, $next-bibl/profile) = true()
  return
  <bibl>{($start-bibl/ref, $next-bibl/ref, $start-bibl/profile)}</bibl>
  
};

(:~
: Idee: Dynamisches "textkritisches" Bibelstellenregister auf der Basis des
: Zwischenformats
: - Tabelle: Bibelreferenzen | textkritisches Profil | Textstelle der Edition (z.B. Kolumnentitel) | evtl. Kurzhinweis
: - Sortieroption: Wiedergabe nach der Bibelreihenfole (data/bible_structure.xml)
: - Filteroption: diejenigen Bibelreferenzen, die nicht in allen / nur in bestimmten Auflagen vorkommen // Veränderungen in bestimmten Auflagen
: - Highlight-Option: evtl. Hervorhebung bestimmter exegetisch oder dogmatisch relevanter Bibelstellen (evtl. erweitertes Markup der units.xml)
:
: @version 0.1 (2021-xx-xx)
: @author ...
:
:)

declare function crit:register( $doc as item() ) as item()
{
  (: ... :)   
};