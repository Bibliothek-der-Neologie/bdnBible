xquery version "3.1";
module namespace units = "http://bdn-edition.de/xquery/units";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: Wandelt die Sinneinheiten-Datei (units.xml) in eine Liste von gleichartigen
Elementen "unit" um, die vergleichbar sind.
:
: Erklären: Wo wird dies unten benötigt?
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)
declare function units:equalunits($units, $bible)
{
  for $u in $units//unit
  let $from-book := ($u/@from-book, $u/ancestor::book/@name)[1]
  let $from-chapter := ($u/@from-chapter, $u/ancestor::chapter/@n/data())[1]
  let $from-verse := $u/@from-verse
  let $to-book := ($u/@to-book, $u/ancestor::book/@name)[1]
  let $to-chapter :=  ($u/@to-chapter, $u/ancestor::chapter/@n/data())[1] 
  let $to-verse := $u/@to-verse 
  
  let $verse-count := fn:sum(
      for $n in ( $from-chapter to $to-chapter ) (: ($from-chapter + 1) to ($to-chapter - 1) wird [noch] nicht akzeptiert. :)
      return  $bible//tei:bibl[@ana = $from-book]/tei:biblScope[@n = $n]/@to/data() )
  return <unit from-book="{$from-book}" from-chapter="{$from-chapter}" from-verse="{$from-verse}" to-book="{$to-book}" to-chapter="{$to-chapter}" to-verse="{$to-verse}"
    verses="{$verse-count}">{$u/data()}</unit>
};

(:~
: Nimmt ein gegebenes Element "ref" aus der konvertieren Quellenschrift-XML
: und sucht in der Liste "equalunits" diejenigen Elemente heraus, die zu dem
: "ref" passen. Diese sog. "matches" werden dann zusammen mit dem "ref" in
: einem Element "item" ausgegeben. Vgl. dann die Funktion units:listitems
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)

declare function units:find($ref, $equalunits) (: Todo: Datentypen! :)
{
  let $ref-from-book := ($ref/@from-book, $ref/@book)
  let $ref-to-book := ($ref/@to-book, $ref/@book)
  let $ref-from-chapter := ($ref/@from-chapter, $ref/@chapter)  
  let $ref-to-chapter := ($ref/@to-chapter, $ref/@chapter)
  let $ref-from-verse := ($ref/@from-verse, $ref/@verse)
  let $ref-to-verse := ($ref/@to-verse, $ref/@verse)
  
  let $matches := $equalunits[
    (
      @from-book/data() eq $ref-from-book and
      @to-book/data() eq $ref-to-book
    ) 
    
    and
    
    (
      (
        fn:number( @from-chapter/data() ) lt fn:number( $ref-from-chapter/data() )  and
        fn:number( @to-chapter/data() ) gt fn:number( $ref-to-chapter/data() ) 
      )  
    
      or
    
      (
        fn:number( @from-chapter/data() ) eq fn:number( $ref-from-chapter/data() ) and
        fn:number( @to-chapter/data() ) gt fn:number( $ref-to-chapter/data() ) and
        fn:number( @from-verse/data() ) lt fn:number( $ref-from-verse/data() )      
      )
    
      or
    
      (
        fn:number( @from-chapter/data() ) eq fn:number( $ref-from-chapter/data() ) and
        fn:number( @to-chapter/data() ) eq fn:number( $ref-to-chapter/data() ) and
        fn:number( @from-verse/data() ) le fn:number( $ref-from-verse/data() ) and
        ( fn:number( @to-verse/data() ) ge fn:number( $ref-to-verse/data() ) or fn:contains($ref-to-verse, "f") )     
      )
    
      or
    
      (
        fn:number( @from-chapter/data() ) lt fn:number( $ref-from-chapter/data() ) and
        fn:number( @to-chapter/data() ) eq fn:number( $ref-to-chapter/data() ) and
        ( fn:number( @to-verse/data() ) ge fn:number( $ref-to-verse/data() ) or fn:contains($ref-to-verse, "f") )      
      )
    ) 
    ]
    
     return <item>{($ref, $matches)}</item>     
   };
   
(:~
: Diese Funktion führt die oben beschriebene Funktion units:find für jedes "ref"
: aus der konvertierten Quellenschrift-XML aus und schreibt die daraus
: hervorgehenden "items" in eine Liste. Außerdem wird die Überschrift "edition"
: hinzugefügt.
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)
   
declare function units:listitems($doc, $equalunits)
{
  <list>
  <edition>{normalize-space($doc/edition/text())}</edition>
  {
  for $ref in $doc//ref 
  return units:find($ref, $equalunits) 
}</list>
};





declare function units:group($items)
{
  let $chapter-units := units:distinct-deep($items//unit[@from-chapter/data() lt @to-chapter/data()])
  let $verse-units := units:distinct-deep($items//unit[@from-chapter/data() eq @to-chapter/data()])
  return
  <list>        
    <VERSE-LEVEL>{
      for $u in $verse-units      
      let $u-refs := for $p in $items//ref[$u = ./following-sibling::*] (: Dies wie unten auf distinct-deep umstellen. Oder anders lösen.:)
        order by $p/@*[1], $p/@*[2], $p/@*[3]
        return $p
      let $u-refs-count := fn:count($u-refs)
      let $u-refs-count-rel := $u-refs-count div ($u/@to-verse - $u/@from-verse + 1)
      let $u-refs-count-xml := <abs n="{$u-refs-count}"/>  
      let $u-refs-count-rel-xml := <rel p="{$u-refs-count-rel}"/>    
      order by $u-refs-count descending
      return <item>{$u, $u-refs, $u-refs-count-xml, $u-refs-count-rel-xml}</item>
    }</VERSE-LEVEL>
    <CHAPTER-LEVEL>{
      for $u in $chapter-units
      let $u-refs := for $p in $items//ref[$u = ./following-sibling::*] order by $p/@*[1], $p/@*[2], $p/@*[3] return $p
      let $u-refs-count := fn:count($u-refs)
      let $u-refs-count-rel := $u-refs-count div number($u/@verses)
      let $u-refs-count-xml := <abs n="{$u-refs-count}"/>
      let $u-refs-count-rel-xml := <rel p="{$u-refs-count-rel}"/>
      order by $u-refs-count descending
      return <item>{$u, $u-refs, $u-refs-count-xml, $u-refs-count-rel-xml}</item>
    }</CHAPTER-LEVEL>
</list>
};


(:~
: Hauptfunktion! Gibt eine Tabelle aus mit den meistverwendeten Bibelstellen
: bzw. Sinneinheiten in einer Kollektion (zur "collection" vgl. query.xq).
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)

declare function units:compare($collection as node()*, $level)
{
  let $chapter-units := units:distinct-deep($collection//unit[@from-chapter/data() lt @to-chapter/data()])
  let $verse-units := units:distinct-deep($collection//unit[@from-chapter/data() eq @to-chapter/data()])
  let $lists := $collection//list
  let $editions := $collection//edition 
   
  return if ($level = "chapter") then
    <table>
      <tr>
        <td>"CHAPTER-LEVEL"</td>
        {for $e in $editions return <td>{normalize-space($e/text() )}</td>}
        <td>"Absolut"</td><td>"Relativ z. Versanzahl"</td>
      </tr>{
        for $u in $chapter-units 
        let $u-refs := $collection//ref/following-sibling::*[fn:count(units:distinct-deep((., $u))) = 1]
        let $u-refs-count := fn:count($u-refs)
        let $u-refs-count-rel := $u-refs-count div number($u/@verses)
        order by $u-refs-count descending
        return <tr>
          <td>{
           fn:concat(
             $u/@from-book/data(), " ", 
             $u/@from-chapter/data(), ",", 
             $u/@from-verse/data(), " – ", 
             $u/@to-book/data(), " ", 
             $u/@to-chapter/data(), ",", 
             $u/@to-verse/data(), ": ", 
             $u/text())
          }</td>
          {
            for $l in $lists
            let $u-refs := $l//ref[$u = ./following-sibling::*]
            let $u-refs-count := fn:count($u-refs)
            return <td>{$u-refs-count}</td>
          }
          <td>{            
            $u-refs-count
          }</td>
          <td>{            
            $u-refs-count-rel
          }</td>
          </tr>         
      }  
    </table>    
    
    else
    <table>
      <tr>
        <td>"VERSE-LEVEL"</td>
        {for $e in $editions return <td><td>{normalize-space($e/text())}</td></td>}
        <td>"Absolut"</td><td>"Relativ z. Versanzahl"</td>
      </tr>{
        for $u in $verse-units 
        let $u-refs := $collection//ref/following-sibling::*[fn:count(units:distinct-deep((., $u))) = 1]
        let $u-refs-count := fn:count($u-refs)
        let $u-refs-count-rel := $u-refs-count div ($u/@to-verse - $u/@from-verse + 1)
        order by $u-refs-count descending
        return <tr>
          <td>{
           fn:concat(
             $u/@from-book/data(), " ", 
             $u/@from-chapter/data(), ",", 
             $u/@from-verse/data(), "–", 
             $u/@to-verse/data(), ": ", 
             $u/text())
          }</td>
          {
            for $l in $lists
            let $u-refs := $l//ref[$u = ./following-sibling::*]
            let $u-refs-count := fn:count($u-refs)
            return <td><td>{$u-refs-count}</td></td> (: <td>{round-half-to-even(fn:count($u-refs) div fn:count($l//ref) * 100, 2), "%"}</td> :)
          }
          <td>{            
            $u-refs-count
          }</td>
          <td>{            
           $u-refs-count-rel
          }</td>
          </tr>         
      }  
    </table>  
};

(:~
: Hilfsfunktion für units:group! 
: Vgl. http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence-deep-equal.html
: Wurde im Modul-Namensraum deklariert, weil kein Modul in ein Modul importiert
: werden kann (oder doch? andere Lösung?)
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)

declare function units:is-node-in-sequence-deep-equal ( $node as node()? , $seq as node()* ) as xs:boolean {
   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
};


(:~
: Ebenfalls Hilfsfunktion für units:group! 
: Vgl. http://www.xqueryfunctions.com/xq/functx_distinct-deep.html
: Wurde im Modul-Namensraum deklariert, weil kein Modul in ein Modul importiert
: werden kann (oder doch? andere Lösung?)
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)

declare function units:distinct-deep ( $nodes as node()* )  as node()* {
    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(units:is-node-in-sequence-deep-equal(.,$nodes[position() < $seq]))]
};