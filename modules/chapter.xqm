xquery version "3.1";
module namespace chapter = "http://bdn-edition.de/xquery/chapter";

import module namespace main = "http://bdn-edition.de/xquery/main" at "main.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare function chapter:chapters
    ( $edition as node()* ) as item()* {
    ( $edition//*:div[@type = 'chapter'] )
};

declare function chapter:original-chapter
    ( $chapter as node()*, $version ) as item()* {
    chapter:convert($chapter, $version)
};

declare function chapter:word-count
    ( $node as node() ) as item()* {
    let $textnodes := $node//text()
    let $tokens := for $text in $textnodes return tokenize( $text, " ")
    return count($tokens)
};


declare function chapter:edition-stats
    ( $edition as node(), $version ) as item()* {
    
    let $chapters := chapter:chapters($edition)
    return 
        <stats chapters="{count($chapters)}">
        {
            for $chapter in $chapters
            let $original-chapter :=  chapter:original-chapter($chapter, $version)
            return chapter:chapter-stats($original-chapter)
        }
        </stats>
};


declare function chapter:chapter-stats
    ( $chapters as node()* ) as item()* {
    for $chapter in $chapters
    let $word-count := chapter:word-count($chapter)
    let $bibel-refs := main:parse-bibel-refs($chapter//*:bibl[@type='biblical-reference'])
    let $bibel-ref-count := count($bibel-refs//*:ref)
    let $sections := $chapter//*:div[@type='section']
    return 
        <chapter title="{normalize-space(data($chapter/*:head))}" xml:id="{$chapter/@xml:id}" words="{$word-count}" sections="{count($sections)}" bibelRefs="{$bibel-ref-count}">
            {
                for $section in $sections
                let $word-count-section := chapter:word-count($section)
                let $bibel-refs-section := main:parse-bibel-refs($section//*:bibl[@type='biblical-reference'])
                let $bibel-ref-count-section := count($bibel-refs-section//*:ref)
                return 
                    <section n="{data($section/@n)}" xml:id="{$section/@xml:id}" words="{$word-count-section}" bibelRefs="{$bibel-ref-count-section}">
                        {
                            (:for $ref in $bibel-refs-section
                            return $ref:)
                            $bibel-refs-section//*:ref
                        }
                    </section>
            }
        </chapter>
};


declare function chapter:get-nodes-by-ids
    ( $ids as xs:string*, $xml ) as item()* {
    for $id in $ids
    let $normalize := replace( $id, "#", '')
    return $xml//node()[@xml:id = $normalize]
};


(: CONVERSION FUNCTIONS:)
declare function chapter:convert
    ( $nodes as node()*, $version ) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return normalize-space(concat(" ", $node, " "))
            
            case comment() return $node
            
            case element(tei:app) return (
                (:if ( $node[not(@type)]) then (
                    chapter:textkritik( $node, $version )
                ) 
                else (
                    chapter:copy( $node, (), $version )
                ):)
                chapter:textkritik( $node, $version )
            )
            
            case element(tei:choice) return (
                if ($node[tei:abbr]) then (
                    chapter:convert( $node/tei:abbr/node(), $version )
                ) 
                else if ($node[tei:sic]) then (
                    chapter:convert( $node/tei:sic/node(), $version )
                ) 
                else (
                    chapter:copy( $node, (), $version ) 
                )
            )
            
            case element(tei:div) return (
                if ( $node[@type = 'section-group']) then (
                    chapter:convert( $node/node(), $version )
                ) 
                else (
                    chapter:copy( $node, (), $version )
                )
            )
            
            case element(tei:head) return (
                chapter:copy( $node, $node//tei:orig/node(), $version )
            )
            
            case element(tei:index) return ()
            
            case element(tei:join) return (
                chapter:join( $node, $version )
            )
            
            case element(tei:milestone) return ()
            
            case element(tei:note) return (
                if ( $node[@type = 'editorial-commentary']) then () 
                else (
                    chapter:copy( $node, (), $version )
                )
            )
            
            case element(tei:ptr) return ()
            
            case element(tei:pb) return ()
            
            case element(tei:cb) return ()
            
            default return chapter:copy( $node, (), $version ) 
};


declare function chapter:textkritik
    ( $app as node(), $version as xs:string? ) as item()* {
    let $default := $app/tei:lem
    let $target-version := $app/tei:rdg[@wit = concat('#',$version)]
    return
        if ( $target-version ) then (
            chapter:convert( $target-version/node(), $version ) 
        ) else (
            chapter:convert( $default/node(), $version ) 
        )
        (:if ( $target-version ) then (
             chapter:copy($target-version, (), $version) 
        ) else (
            chapter:copy($default, (), $version) 
        ):)
};


declare function chapter:copy
    ( $node as node(), $children as node()*, $version ) as item() {
    let $target-children := if (count($children) > 0) then (
            $children
        )
        else if ($node[@copyOf]) then (
            chapter:get-nodes-by-ids($node/@copyOf, $node/root())/node()
        )
        else (
            $node/node()
        )

    return element{ $node/name() }{ 
        $node/@* , chapter:convert( $target-children, $version ) 
    }
};


declare function chapter:join
    ( $node as node(), $version ) as item() {
    let $target-ids := tokenize($node/@target, " ")
    let $name := if ($node/@result) then( data($node/@result) ) else ("join")
    let $scope := $node/@scope
    let $targets := chapter:get-nodes-by-ids( $target-ids, $node/root() )
    return 
        
        element{ $name }{ 
            if ( $scope = "branches" ) then (
                for $target in $targets
                return chapter:convert( $target/node(), $version )
            ) else (
                $node
            )
        }

        
};



