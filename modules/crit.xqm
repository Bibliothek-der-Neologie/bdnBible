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