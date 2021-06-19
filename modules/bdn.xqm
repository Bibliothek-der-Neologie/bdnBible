xquery version "3.1";
module namespace bdn = "http://bdn-edition.de/xquery/bdn";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : bdn:convert()
 :
 : Converts TEI data into a div-structured set of elements "bibl". Each of these
 : represent a given tei:bibl[@type="biblical-reference"] in the TEI source.
 : It has two child elements: 1) "ref" contains Information about the biblical 
 : Metadata which is contained in tei:citedRange, 2) "profile" gives information
 : about the text versions, the biblical references do appear in (tei:app).
 : 
 : @version 0.3 (2021-12-21)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:convert($node as node()*) as item()* {
  typeswitch($node)
  case text() return ()
  case comment() return ()
  case element(tei:TEI) return bdn:data($node)
  case element(tei:title) return bdn:edition($node)
  case element(tei:listWit) return bdn:listWit($node)
  (: case element(tei:front) return () :)
  case element(tei:div) return bdn:div($node)  
  case element(tei:bibl) return bdn:bibl($node)
  (: case element(tei:citedRange) return bdn:citedRange($node) :)
  default return bdn:passthru($node)
};


(:~
 : bdn:convert > bdn:passthru()
 : TEMPLATE: Default function of bdn:convert to return a node's children aka.
 : ignore the node and work on it's children instead.   
 :
 : @param $nodes a set of nodes
 : @return a set nodes (children of the input node)
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note (MS): passthru auf Sicht und Kindknoten in der Konversion direkt 
 : ansteuern?
 :)
declare function bdn:passthru
  ($nodes as node()*) as item()* {
  for $node in $nodes/node() return bdn:convert($node)
};


(:~
 : TEMPLATE: Root node of bdn:convert to provide the conversion with root-node 
 : "data"   
 :
 : @version 0.3 (2021-06-18)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:data ($node as node()*) as node() {
  element {"data"} { bdn:convert($node/node()) }
};


(:~
 : bdn:convert > bdn:edition()
 : TEMPLATE: title node "edition" of bdn:convert   
 :
 : @param $nodes a set of nodes
 : @return a node edition (no xmlns) providing the title of the converted 
 : resource
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:edition ($node as node()*) as node()* {
  if ($node//@type="column-title") 
  then element {"edition"} {$node/descendant-or-self::tei:title[@type="column-title"]/text()}
  else ()
};


(:~
 : bdn:convert > bdn:listWit()
 : TEMPLATE: node "listWit" of bdn:convert(). It provides all witness-IDs and 
 : identifies the base-text.   
 :
 : @param $node a set of nodes
 : @return a node listWit (no xmlns) providing all witnesses of the converted 
 : TEI resource
 : 
 : @version 0.2 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 : @note (US): Ich habe das witness element mal mit einem element constructor
 : geschrieben, damit ihr seht, wie das aussieht. Das bietet sich bei der 
 : Konstruktion von komplexen XML strukturen an.
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
        element {"witness"}{
          attribute {"id"}{ $id },
          attribute {"lem"}{ $is-lem }
        }
    }
  </listWit>
};


(:~
 : Konversion tei:div
 : 
 : @version 0.3 (2021-06-18)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:div ($node as node()*) as node()* {
    let $column-title := $node/tei:head//tei:choice/tei:supplied[@reason = "column-title"]
    return   
      element {"div"}
      {
        attribute {"type"}{ data($node/@type) },
        attribute {"id"}{ data($node/@xml:id) },     
        attribute {"words"}{ bdn:word-count($node) },       
         
        if ( $column-title ) 
        then attribute {"column-title"}{ $column-title/data() => fn:normalize-space() } 
        else (),                       
      
        bdn:passthru( $node )
      }
};

(:~
 : Zählt die Wörter in einem vorgegebenem Knoten. Bisher noch sehr einfach gehalten!
 : 
 : @version 0.1 (2021-05-01)
 : @author Marco Stallmann
 :)
declare function bdn:word-count ( $node as xs:string? )  as xs:integer {
   tokenize( $node, '\W+' )[. != ''] => fn:count()
 } ; 

(:~
 : Konvertiert tei:bibl und startet bdn:citedRange und bdn:profile
 :
 : @version 0.3 (2021-06-18)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:bibl ( $node ) {
 if ($node/@type = "biblical-reference")
 then
   if ($node/tei:citedRange/@n)
   then
    let $n-values := fn:tokenize($node/tei:citedRange/@n/data(), " ")
    for $n in $n-values     
    return 
      element bibl {
      bdn:citedRange_n( $n ) , 
      bdn:profile($node)  
        }  
   else 
    element bibl {
      bdn:citedRange_ft( $node/tei:citedRange ) , 
      bdn:profile($node)
    }
  else element bibl {"No attribute!"}
};


(:~
 : Erstellt ein textkritisches Profil für ein tei:bibl
 :
 : 
 : @version 0.3 (2020-12-01)
 : @author Marco Stallmann, Uwe Sikora
 :)
declare function bdn:profile( $bibl ) as element( profile ) {
  let $listWit := $bibl/root()//tei:listWit
  return
  element {"profile"} {    
    if ( $listWit/tei:witness/@n = "base-text" )
    then for $witness in $listWit/tei:witness
      return element {"wit"} {
        attribute {"in"} { $witness/@xml:id },
        attribute {"is"} { bdn:is-in( $bibl, $witness ) }
        }
    else "Kein Leittext definiert!" 
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
 : @note (MS): bdn:is-in funktioniert für alle Bände außer Bahrdt/Semler (keine Varianten / Leitauflage)
 :)
declare function bdn:is-in($bible-ref, $w) 
{
  if ($bible-ref/ancestor::tei:app)
  then 
    if ($bible-ref/ancestor::tei:lem)
    then
      if ($bible-ref/ancestor::tei:app/tei:rdg[fn:contains(@wit, $w/@xml:id) and not(.//* = $bible-ref)])
      then "false"
      else "true"
    else 
      if ($bible-ref/ancestor::tei:rdg/@wit/contains(., $w/@xml:id))
      then "true"   
      else "false"
  else "true"   
};



(:~
 : Konvertiert n-Wert eines tei:citedRange in ein Element ref
 : 
 : @version 0.3 (2021-06-18)
 : @author Marco Stallmann
 :)
declare function bdn:citedRange_n ( $n ) {
 element {"ref"} {
   attribute {"book"} { fn:tokenize($n, ":")[1] },
   attribute {"chapter"} { fn:tokenize($n, ":")[2] },
   attribute {"verse"} { fn:tokenize($n, ":")[3] }
   }
 };
 
 
 (:~
 : Konvertiert from/to-Werte eines tei:citedRange in ein Element ref
 : 
 : @version 0.3 (2021-06-18)
 : @author Marco Stallmann
 :)
declare function bdn:citedRange_ft ( $node  ) {
  let $from-book := fn:tokenize($node/@from, ":")[1]
  let $from-chapter := fn:tokenize($node/@from, ":")[2]
  let $from-verse := fn:tokenize($node/@from, ":")[3]
  let $to-book := if ( fn:contains($node/@to/data(), "f") ) then $from-book else fn:tokenize($node/@to, ":")[1]
  let $to-chapter := if ( fn:contains($node/@to/data(), "f") ) then $from-chapter else fn:tokenize($node/@to, ":")[2]
  let $to-verse := if ( fn:contains($node/@to/data(), "f") ) then $node/@to/data() else fn:tokenize($node/@to, ":")[3]
  return element {"ref"} {
    attribute {"from-book"} {$from-book},
    attribute {"from-chapter"} {$from-chapter},
    attribute {"from-verse"} {$from-verse},
    attribute {"to-book"} {$to-book},
    attribute {"to-chapter"} {$to-chapter},
    attribute {"to-verse"} {$to-verse}
  }
};