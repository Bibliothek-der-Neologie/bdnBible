xquery version "3.1";
module namespace bdn = "http://bdn-edition.de/xquery/bdn";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : bdn:convert()
 : [description] 
 :
 : @return a set of nodes according to the conversion
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:convert($node) as item()* {
  typeswitch($node)
  case text() return ()
  case comment() return ()
  case element(tei:TEI) return bdn:data($node)
  case element(tei:title) return bdn:edition($node)
  case element(tei:listWit) return bdn:listWit($node)
  case element(tei:front) return ()
  case element(tei:div) return bdn:div($node)
  case element(tei:head) return bdn:head($node)
  case element(tei:bibl) return bdn:bibl($node)
  case element(tei:citedRange) return bdn:citedRange($node)
  default return bdn:passthru($node)
};


(:~
 : bdn:convert > bdn:passthru()
 : TEMPLATE: Default function of bdn:convert to return a node's children aka. ignore the node and work on it's children instead   
 :
 : @param $nodes a set of nodes
 : @return a set nodes (children of the input node)
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:passthru
  ($nodes as node()*) as item()* {
  for $node in $nodes/node() return bdn:convert($node)
};


(:~
 : bdn:convert > bdn:data() ( former: bdn:tei() )
 : TEMPLATE: Root node of bdn:convert to provide the conversion with root-node "data"   
 :
 : @param $nodes a set of nodes
 : @return a node data (no xmlns) providing the converted data
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:data
  ($node as node()*) as node() {
  <data>{ bdn:passthru($node) }</data>
};


(:~
 : bdn:convert > bdn:edition()
 : TEMPLATE: title node "edition" of bdn:convert   
 :
 : @param $nodes a set of nodes
 : @return a node edition (no xmlns) providing the title of the converted resource
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:edition
  ($node as node()*) as node()* {
  if ($node/tei:title/@type="column-title") then <edition>{$node/tei:title[@type="column-title"]/text()}</edition>
  else ()
};


(:~
 : bdn:convert > bdn:listWit()
 : TEMPLATE: node "listWit" of bdn:convert(). It provides all witness-IDs and identifies the base-text.   
 :
 : @param $node a set of nodes
 : @return a node listWit (no xmlns) providing all witnesses of the converted TEI resource
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note: Ich habe das witness element mal mit einem element constructor geschrieben, damit ihr seht, wie das aussieht. Das bietet sich bei der Konstruktion von komplexen XML strukturen an.
 :)
declare function bdn:listWit
  ( $node as element(tei:listWit) ) as element(listWit) {
  <listWit>
    {
      for $witness in $node/node() 
      let $id := $witness/@xml:id => data()
      let $n := $witness/@n => data()
      let $is-lem := if ($n = "base-text") then "true" else "false"
      return 
        (: <witness id="{$id}" lem="{$is-lem}"/> :)
        element {"witness"}{
          attribute {"id"}{ $id },
          attribute {"lem"}{ $is-lem }
        }
    }
  </listWit>
};


(:~
 : bdn:convert > bdn:div()
 : TEMPLATE: node "div" of bdn:convert(). It ignores all tei:div that don't include tei:bibl[@type ="biblical reference"].  
 :
 : @param $node a set of nodes
 : @return a node div (no xmlns) providing all biblical references of a tei:div of the converted TEI resource.
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note:
     (1) der ursprüngliche test "$node//tei:bibl/@type = "biblical-reference" ist nicht ganz korrekt. Damit testest du nicht, sondern holst dir gleich einen wert. Ein test würde so aussehen: $node//tei:bibl[@type = "biblical-reference"]
     (2) der passthru ist von der Konvertierungslogik unsauber. Besser du gibst die Kindknoten einfach an die ursprüngliche Konversion zurück, also bdn:convert( $node/node() )
 :)
declare function bdn:div
  ($node as node()*) as node()* {
  let $bibl-refs := $node//tei:bibl[@type = "biblical-reference"]   
  return 
    if ( $bibl-refs ) then (
      element {"div"}{
        attribute {"type"}{ data($node/@type) },
        attribute {"id"}{ data($node/@xml:id) },
        bdn:convert( $node/node() )
      }
    ) else ()
};


(:~
 : bdn:convert > bdn:head()
 : TEMPLATE: node "head" of bdn:convert(). 
 :
 : @param $node a set of nodes
 : @return a node head (no xmlns) providing the xml:id of a tei:head of a tei:div of the converted TEI resource.
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note: Die Funktion ergibt für mich keinen Sinn.
 :)
declare function bdn:head
  ($node as node()*) as element() {
  <head>{$node/@xml:id}</head>
  };


(:~
 : bdn:convert > bdn:app()
 : TEMPLATE: node "app" of bdn:convert(). 
 :
 : @param $node a set of nodes
 : @return a node app (no xmlns) providing the different apparatus entries and their bibel-refs
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note: ich habe die Konversion der apparats einträge in einem let zusammengefast, da wir hier ja das gleiche machen, daher brauchen wir eigentlich auch nur diesen einen aufruf. Ich habe auch hier nicht auf passthru sondern wieder direkt auf convert geleitet nach dem gleichen prinzip wie oben: "Für jeden Knoten beginne die Konversion im Haupttemplate". Dann ist der Konversionseinstieg standardisiert und immer eindeutig.
 :)
declare function bdn:app
  ($node as node()*) {  
  let $bibl-refs := $node//tei:bibl[@type = "biblical-reference"]   
  return
    if ( $bibl-refs ) then (
      element app {
        for $entry in $node/node()
        let $converted-entries := bdn:convert($entry/node())
        return
          if ( $entry/@wit ) then   
            <rdg wit="{ $entry/@wit }" type="{$entry/@type}">
            {
              $converted-entries
            }
            </rdg>    
          else
           <lem>
             {
               $converted-entries
             }
           </lem> 
      }
    ) else ()
};


(:~
 : bdn:convert > bdn:bibl()
 : TEMPLATE: node "bibl" of bdn:convert(). 
 :
 : @param $node a set of nodes
 : @return a node bibl (no xmlns) providing a bibl entry
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note: Hier verstehe ich nicht, warum die nochmal durch den passthru muss
 :)
declare function bdn:bibl
  ($node) as element(bibl) {
  element bibl {
    bdn:passthru($node), 
    bdn:profile($node)
  }
};


(:~
 : bdn:convert > bdn:profile()
 : TEMPLATE: node "profile" of bdn:convert(). The profile is ...
 :
 : @param $node a set of nodes
 : @return a node profile (no xmlns)
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:profile
  ($bibl) as element(profile) {
  element profile {
    (: for $w in $wits/tei:witness :)
    for $witness in $bibl/root()//tei:listWit/tei:witness
    return 
      <wit in="{$witness/@xml:id}" is="{bdn:is-in($bibl, $witness)}"/>
  }
};


(:~
 : bdn:is-in()
 : function to check whether a bibel-ref is of a specific witness [?] ...
 :
 : @param $bible-ref a tei:bibl element
 : @param $witness a tei:witness element
 : @return a xsd:boolean (??)
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann
 :)
declare function bdn:is-in($bible-ref, $w) (: GEHT! :)
{
  if ($bible-ref/ancestor::tei:app)
  then 
    if ($bible-ref/ancestor::tei:lem)
    then
      if ($bible-ref/ancestor::tei:app/tei:rdg[fn:contains(@wit, $w/@xml:id) and not(.//* = $bible-ref)])
      then "false1"
      else "true2"
    else 
      if ($bible-ref/ancestor::tei:rdg/@wit/contains(., $w/@xml:id))
      then "true3"   
      else "false4"
  else "true5"   
};


(:~
 : bdn:citedRange()
 : TEMPLATE: node "ref" of bdn:convert(). ...
 :
 : @param $node a tei:citedRange element
 : @param $witness a tei:witness element
 : @return a node ref (no xmlns) providing all necessary information about a bibel-ref
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann
 :)
declare function bdn:citedRange
  ( $node as element(tei:citedRange) ) {
  if ($node/@n)
  then
    let $values := fn:tokenize($node/@n/data(), " ")
    for $v in $values
      let $book := fn:tokenize($v, ":")[1]
      let $chapter := fn:tokenize($v, ":")[2]
      let $verse := fn:tokenize($v, ":")[3]
      return <ref book="{$book}" chapter="{$chapter}" verse="{$verse}"/>
  else
    let $from-book := fn:tokenize($node/@from, ":")[1]
    let $from-chapter := fn:tokenize($node/@from, ":")[2]
    let $from-verse := fn:tokenize($node/@from, ":")[3]
    let $to-book := if (fn:contains($node/@to/data(), "f")) then $from-book else fn:tokenize($node/@to, ":")[1]
    let $to-chapter := if (fn:contains($node/@to/data(), "f")) then $from-chapter else fn:tokenize($node/@to, ":")[2]
    let $to-verse :=if (fn:contains($node/@to/data(), "f")) then $node/@to/data() else fn:tokenize($node/@to, ":")[3]
    return <ref from-book="{$from-book}" from-chapter="{$from-chapter}" from-verse="{$from-verse}" to-book="{$to-book}" to-chapter="{$to-chapter}" to-verse="{$to-verse}"/>
};