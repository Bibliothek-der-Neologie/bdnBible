xquery version "3.1";
module namespace main = "http://bdn-edition.de/xquery/main";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/html";



declare function main:bibel-stellen 
    ( $edition as node() ) as node()* {
    $edition//*:bibl[@type = 'biblical-reference']
};


declare function main:sort
    ( $refs as node()*, $order-sequence ) as node()* {
    for $item in $order-sequence
    return
        for $ref in $refs[@book = $item] 
        order by xs:int($ref/@chapter) and xs:int(if (not(data($ref/@verse) = "")) then (data($ref/@verse)) else (1) )
        return $ref
};

declare function main:bibel-stellen 
    ( $edition as node(), $order-sequence ) as node()* {
    let $stellen := main:bibel-stellen($edition)
    let $parsed := main:parse-bibel-refs($stellen)
    for $item in $order-sequence
    return ( 
        for $item in $parsed//ref[@book = $item] 
        order by xs:int($item/@chapter) and xs:int(if (not(data($item/@verse) = "")) then (data($item/@verse)) else (1) )
        return $item
    )
};


declare function main:parse-bibel-refs
    ( $refs as node()* ) as item()* {
    for $ref in $refs
    let $citedRange := $ref/*:citedRange
    return 
        if ($citedRange[@n]) then (
            let $refs := main:parse-ref-string( $citedRange/@n )
            return 
                if( count($refs) > 1 ) then (
                    <point type="multiple" n="{$citedRange/@n}">
                        { $refs }
                    </point>
                ) else (
                    <point n="{$citedRange/@n}">
                        { $refs }
                    </point>
                )
        ) 
        
        else if($citedRange[@from]) then (
            let $from := main:parse-ref-string( $citedRange/@from )
            let $to := main:parse-ref-string( $citedRange/@to )
            return 
                <range from="{$citedRange/@from}" to="{$citedRange/@to}">
                    <point type="from">{$from}</point>
                    <point type="to">{$to}</point>
                </range>
        )
        
        else ()
};


declare function main:parse-ref-string
    ( $ref-string as xs:string ) as item()* {
    let $split := main:separate-refs( $ref-string )
    for $ref in $split
    return 
        main:ref-components( $ref )
};


declare function main:separate-refs
    ( $ref-string as xs:string ) as item()* {
    tokenize( $ref-string, " " )
};


declare function main:ref-components
    ( $ref as xs:string ) as item()* {
    let $components := tokenize( $ref, ":" )
    return <ref book="{$components[1]}" chapter="{$components[2]}" verse="{$components[3]}"/>
};


declare function main:chapter-refs
    ( $edition as node() ) as node()* {
    for $chapter in $edition//*:div[@type = 'chapter']
    let $bibel-stellen := main:bibel-stellen( $chapter ) 
    let $word-count := count( tokenize(string-join($chapter//text()) , " "))
    return 
        <chapter bibel-refs="{count($bibel-stellen)}" words="{$word-count}">
        {
        $bibel-stellen
        }
        </chapter>
};


declare function main:ref2luther
    ( $ref as xs:string, $luther-xml as node(), $index ) as item()* {
    let $components := main:ref-components( $ref )
    let $book := $index//*:bibl[@ana = $components/@book]
    let $book-nr := count($book/preceding::*:bibl[@ana]) + 1
    let $luther-book := $luther-xml//BIBLEBOOK[@bsname = $components/@book]
    let $luther-chapter := $luther-book/CHAPTER[@cnumber = $components/@chapter]
    let $luther-verse := $luther-chapter/VERS[@vnumber = $components/@verse]
    return 
        <luther>
            {$components}
            <text>
            {
                if ( count($luther-verse) > 0 ) then (
                    <vers>{normalize-space($luther-verse/text())}</vers>
                ) 
                else if( count($luther-chapter) > 0 ) then (
                    for $vers in $luther-chapter/VERS
                    return 
                        <vers n="{$vers/@vnumber}">{normalize-space($vers/text())}</vers>
                )
                else (
                    for $chapter in $luther-book/CHAPTER
                    return 
                        <chapter n="{$chapter/@cnumber}">
                            {
                            for $vers in $chapter/VERS
                            return 
                                <vers n="{$vers/@vnumber}">{$vers/text()}</vers>
                            }
                        </chapter> 
                )
            }
            </text>
        </luther>
};



declare function main:link-ref-to-index
    ( $ref as xs:string, $index as node() ) as item()* {
    let $components := main:ref-components( $ref )
    let $index-entry := $index//*:bibl[@ana = $components/@book]
    let $chapter-entry := $index-entry//*:biblScope[@n = $components/@chapter]
    return 
        <book n="{$index-entry/@ana}" 
            title="{$index-entry/*:title}">
            <chapter n="{$components/@chapter}" verses="{$chapter-entry/@to}"/>
        </book>
};



declare function main:book2index
    ( $bibel-book as xs:string, $index as node() ) as item()* {
    $index//*:bibl[@ana = $bibel-book]
};


declare function main:index-book-stats
    ( $bibel-book as xs:string, $index as node() ) as item()* {
    let $index-entry := main:book2index( $bibel-book, $index )
    return 
        <book 
            title="{$index-entry/*:title}" 
            chapters="{count($index-entry/*:biblScope)}" 
            verses="{sum($index-entry/*:biblScope/@to)}">
            {$index-entry}
        </book>
};




declare function main:index-order
    ( $index as node() ) as item()* {
    data($index//*:bibl/@ana)
};
