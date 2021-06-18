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
  for tumbling window $b in $doc//bibl
  start $start-bibl
  next $next-bibl
  when fn:deep-equal($start-bibl/profile, $next-bibl/profile) = true()
  return
  <bibl>{($start-bibl/ref, $next-bibl/ref, $start-bibl/profile)}</bibl>  
};

(:~
: Idee: Dynamisches "textkritisches" Bibelstellenregister auf der Basis des: Zwischenformats
: - Tabelle: Bibelreferenzen | textkritisches Profil | Textstelle der Edition (z.B. Kolumnentitel) | evtl. Kurzhinweis
: - Sortieroption: Wiedergabe nach der Bibelreihenfole (data/bible_structure.xml)
: - Filteroption: diejenigen Bibelreferenzen, die nicht in allen / nur in bestimmten Auflagen vorkommen // Veränderungen in bestimmten Auflagen
: - Highlight-Option: evtl. Hervorhebung bestimmter exegetisch oder dogmatisch relevanter Bibelstellen (evtl. erweitertes Markup der units.xml)
:
: @version 0.1 (2021-06-18)
: @author ...
:
:)

declare function crit:register( $doc ) 
{
  let $bibls-with-places := crit:bibl-places ( $doc )  
  let $filtered := crit:filter ( $bibls-with-places )
  return element {"register"}{ $doc//edition, $doc//listWit,
    for $ana in doc( "../data/bible_structure.xml")//tei:bibl/@ana/data()
    return crit:sort-chapter( $filtered , $ana ) 
    }
};

(:~
: Textstelle der Edition 
:
: Todo: Ggf. umstellen auf Kolumnentitel?
:
: @version 0.1 (2021-06-18)
: @author ...
:
:)

declare function crit:bibl-places ( $doc ){
  element {"bibls"} { for $bibl in $doc//bibl 
    return element { "bibl" } {
      attribute { "place" } { $bibl/parent::div/@id }, 
      $bibl/ref, $bibl/profile
        }
   }
};

(:~
: Nur Bibelreferenzen mit mindestens einem @is = "false" (also textkritisch relevante)
:
: @version 0.1 (2021-06-18)
: @author ...
:
:)
declare function crit:filter ( $doc ) {
  element {"bibls"} {
    $doc//bibl[.//profile/wit/@is = "false"]
  }
};

(:~
: Sortierung nach Bibel-Reihenfolge
:
: @version 0.1 (2021-06-18)
: @author ...
:
:)
declare function crit:sort-chapter( $doc, $ana ){
  let $bibls := $doc//bibl[./ref/@*[1] = $ana]
  for $bibl in $bibls
  order by $bibl/ref[1]/@*[2]/fn:number(), $bibl/ref[1]/@*[3]/fn:number()
  return $bibl
};

(:~
: Konversion der Neusortierung in HTML-Tabelle
:
: @version 0.1 (2021-06-18)
: @author ...
:
:)
declare function crit:register_table ( $doc ){
  let $register := crit:register( $doc )
  let $filename := "output/crit_register_"||fn:lower-case(substring($doc//edition, 1, 2))||".html"
  
  return file:write( $filename,
    <html>
      <head>
        <title>Bibelstellenregister</title>
      </head>
      <body>
        <div>
          <p>Bibelstellenregister: {$doc//edition/data()}</p>
        </div>
        <table>{
         
         <tr>
           <td>Bibelreferenzen</td>
           
           <td>Ort</td>
            
           {for $wit in $doc//listWit/witness return <td>{$wit/@id/data()}</td>}           
         </tr>,
                 
         for $bibl in $register//bibl
         return 
         <tr>
           <td>{
             for $ref in $bibl/ref 
             return 
               if ($ref/@book)                  
               then fn:concat($ref/@book, " ", $ref/@chapter, ",", $ref/@verse) 
               else fn:concat($ref/@from-book, " ", $ref/@from-chapter, ",", $ref/@from-verse, "–", $ref/@to-verse) 
         }</td>        
         
         <td>{$bibl/@place/data()}</td>
                    
          {
             for $wit in $bibl//wit 
             return 
               if ($wit/@is = "true") 
               then <td style="color:green">✓</td> 
               else <td style="color:red">x</td> 
          }            
          
         </tr>
}			</table>
  </body></html>)
};