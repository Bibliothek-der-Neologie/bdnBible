xquery version "3.1";
module namespace units = "http://bdn-edition.de/xquery/units";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~
: Auflistung aller Entsprechungen zu allen Sinneinheiten in einem Band
: oder mehreren Bänden (Vers-Evbene)
:
: @param $xx_conv Editionsdaten im Zwischenformat
:
: @version 1.0 (2021)
: @author Marco Stallmann
:
:)
declare function units:collect_verse( $xx_conv )
{
  let $equalunits := doc("../data/units_equal.xml")    
  return element {"units"} {
    for $unit in $equalunits//unit 
    where ($unit/@from-chapter eq $unit/@to-chapter) 
      return 
      element {"unit"} {
        element {"ref"} { 
          fn:concat( 
            $unit/@from-book, " ", 
            $unit/@from-chapter, ",", 
            $unit/@from-verse, " – ", 
            $unit/@to-verse)},    
        element {"name"} { $unit/text() },    
        for $xx_conv_einzel in $xx_conv/data return
        element {"matches"} {
          attribute {"edition"} {$xx_conv_einzel/edition/data() => fn:normalize-space()}, 
          units:matches($unit, $xx_conv_einzel)}
        }
  }  
};

(:~
: Auflistung aller Entsprechungen zu allen Sinneinheiten in einem Band
: oder mehreren Bänden (Kapitelebene)
:
: @param $xx_conv Editionsdaten im Zwischenformat
:
: @version 1.0 (2021)
: @author Marco Stallmann
:
:)
declare function units:collect_chapter( $xx_conv ) 
{
  let $equalunits := doc("../data/units_equal.xml")  
  return element {"units"} {
    for $unit in $equalunits//unit 
    where ($unit/@from-chapter lt $unit/@to-chapter)  
    return 
      element {"unit"} {
        element {"ref"} { 
          fn:concat( 
            $unit/@from-book, " ", 
            $unit/@from-chapter, ",", 
            $unit/@from-verse, " – ", 
            $unit/@to-book, " ", 
            $unit/@to-chapter, ",", 
            $unit/@to-verse)},
        element {"name"} { $unit/text() },
        for $xx_conv_einzel in $xx_conv/data return
        element {"matches"} {
          attribute {"edition"} {$xx_conv_einzel/edition/data() => fn:normalize-space()}, 
          units:matches($unit, $xx_conv_einzel)}
      }
  }  
};

(:~
: Sucht zu einer gegebenen Sinneinheit alle Entsprechungen im Zwischenformat $xx_conf
:
: @param $unit Sinneinheit 
: @param $xx_conv Editionsdaten im Zwischenformat
:
: @version 1.0 (2021)
: @author Marco Stallmann
:
:)
declare function units:matches( $unit, $xx_conv ) {
  let $unit-from-book := $unit/@from-book
  let $unit-from-chapter := $unit/@from-chapter
  let $unit-from-verse := $unit/@from-verse
  let $unit-to-book := $unit/@to-book
  let $unit-to-chapter := $unit/@to-chapter
  let $unit-to-verse := $unit/@to-verse
  
  let $matches := $xx_conv//ref[
    ( @to-book eq $unit/@to-book )
    
    and     
    
    (
      (
        fn:number( $unit/@from-chapter ) lt fn:number( (@from-chapter, @to-chapter)[1] )  and
        fn:number( $unit/@to-chapter ) gt fn:number( @to-chapter ) 
      )  
    
      or
    
      (
        fn:number( $unit/@from-chapter ) eq fn:number( (@from-chapter, @to-chapter)[1] ) and
        fn:number( $unit/@to-chapter ) gt fn:number( @to-chapter ) and
        fn:number( $unit/@from-verse ) lt fn:number( (@from-verse, @to-verse)[1] )      
      )
    
      or
    
      (
        fn:number( $unit/@from-chapter ) eq fn:number( (@from-chapter, @to-chapter)[1] ) and
        fn:number( $unit/@to-chapter ) eq fn:number( @to-chapter ) and
        fn:number( $unit/@from-verse ) le fn:number( (@from-verse, @to-verse)[1] ) and
        ( fn:number( $unit/@to-verse ) ge fn:number( @to-verse ) or fn:contains( @to-verse, "f") )     
      )
    
      or
    
      (
        fn:number( $unit/@from-chapter ) lt fn:number( (@from-chapter, @to-chapter)[1] ) and
        fn:number( $unit/@to-chapter ) eq fn:number( @to-chapter ) and
        ( fn:number( $unit/@to-verse ) ge fn:number( @to-verse ) or fn:contains(@to-verse, "f") )      
      )
    )
]
return $matches  
};

(:~
: Stellt die Ergebnisse von units:collect_verse bzw. units:collect_chapter als
: HTML-Tabelle dar.
:
: @param $xx_conv Editionsdaten im Zwischenformat
: @param $level Vergleichsebene: Kapitel (chapter), Vers (verse) oder Gesamt (all)
:
: @version 1.0 (2021)
: @author Marco Stallmann
:
:)
declare function units:compare($xx_conv as item()+ , $level) {  
  let $filename := 
    "../output/units_table_" || 
    fn:string-join(for $data in $xx_conv/data return fn:lower-case(substring($data/edition, 1, 2) 
    || "_")) ||".html" 
  let $collection := 
  if ($level = "verse")
  then units:collect_verse($xx_conv)
  else 
    if ($level = "chapter") 
    then units:collect_chapter($xx_conv)
    else (units:collect_verse($xx_conv), units:collect_chapter($xx_conv))   
  
  return file:write($filename, 
 <html>  
  <head>
    <script src="https://www.j-berkemeier.de/TableSort.js">""</script>
      </head>
  <body>   
  <table class="sortierbar">
  <thead>
    <tr>
      <th class="vorsortiert">Sinneinheit</th>
      { for $xx_conv_einzel in $xx_conv/data return <th class="sortierbar">{$xx_conv_einzel/edition/data()}</th>}      
      <th class="sortierbar">"Gesamt"</th>
    </tr>
    </thead>
    <tbody>
    { for $unit in $collection/unit
      let $unit_matches_count := fn:count($unit/matches/ref)
      order by $unit_matches_count descending
    return 
    <tr>
      <td>{$unit/ref/data(), ":", $unit/name/data()}</td>
      {for $matches in $unit/matches return
      <td>{$matches/ref => fn:count()}</td>}
      <td>{$unit_matches_count}</td>    
    </tr>    
  }
  </tbody>  
  </table>  
  </body>
</html>
)
};

(:~
: Wandelt die Sinneinheiten-Datei (units.xml) in eine Liste von gleichartigen
: Elementen "unit" um, die vergleichbar sind. Diese Liste kann in der
: Funktion units:find zugrundegelegt werden (vgl. dort die Variable "equalunits").
:
: @param $units Gegebene Sinneinheiten-XML
: @param $bible Gegebene Bibel-XML (notwendig für Verszählung)
:
:
: @version 0.1 (2020)
: @author ..., Marco Stallmann
:
:)
declare function units:equalunits( $units, $bible )
{
  file:write('../data/units_equal.xml',
  element {"units"} {
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
    return 
      <unit from-book="{$from-book}" from-chapter="{$from-chapter}" from-verse="{$from-verse}" 
              to-book="{$to-book}" to-chapter="{$to-chapter}" to-verse="{$to-verse}"
              verses="{$verse-count}">{$u/data()}</unit>
  })
};
