(: 
Die Abfrage gibt alle Bibelstellen aus, die in einem gegebenen Abschnitt oder im Gesamtwerk (hier bisher nur: Griesbach § 13 [gr_section_13]) textkritisch relevant sind, die also vom Autor nicht in allen Auflagen referenziert werden und also mit tei:app korrespondieren.
Dazu wird zunächst für jede Auflage eine Liste aller vorkommenden Bibelstellen erstellt, indem sämtliche citedRange-Elemente ausgewertet (n-, from- oder to-Werte). Die Funktion fn:tokenize wird  benutzt, um 1) mehrere Bestandteile eines n-Werts (i.S. n=“Joh:1:1 Joh:1:3“) einzeln zu berücksichtigen und um 2) einen Einzelwert in seine Bestandteile „Buch“, „Kapitel“ und „Vers“ zu zerlegen. Im Falle from/to werden alle dazwischenliegenden Einzelverse berücksichtigt.
Im zweiten Schritt wird für jeden einzelnen Vers der Bibel-XML (textgrid:3vqwx, vgl. die Beschreibung in units.xqm) ein "Auflagen-Profil" in der Form [a, b, c, d] erstellt: Die vier Stellen in diesem Array zeigen an, ob der Bibelvers Teil der oben erstellten Bibelstellenliste ist, ob er also in Auflage a, b, c oder d vorkommt. Die Tabelle gibt schließlich alle Bibelstellen aus, die NICHT das Profil [0,0,0,0] oder [1,1,1,1] haben, also in keiner oder allen Auflagen vorkommen.
Todo: 
- Verbesserung der Abfragenperformance (z.B. Erstellung des Auflagenprofils nicht für jeden Einzelvers, sondern nur für die Vorkommenden)
- Für DHd-Bewerbung: (Manuelle) Erarbeitung von Beispielen/Zwischenergebnissen (ggf. mithilfe des Printregisters oder der Oxygen-Suchfunktion)
- Präzisierung der Auswertung @to = "ff" (aktuell $from-verse + 2; evtl. über "units" aus a)
- Ausweitung auf Gesamtdokument
- Einbeziehung von Stellen ohne Versangabe (z.B. n="Joh:1")
- Tabellengrupierung und -sortierung (z.B. über „tumbling window“, i.S. einer Zusammenfassung aller Bibelverse in der Tabelle, die nacheinander im selben Bibelkapitel stehen und das gleiche Auflagenprofil aufweisen)

:)

xquery version "3.1";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $gr := doc("textgrid:3rj87.0")//tei:div[@xml:id="gr_section_13"]; (: Aktuell nur Suche in einem Abschnitt :)
declare variable $bible := doc("textgrid:3vqwx.0");

declare function local:check($wit, $book, $chapter, $verse) as item()*
{
(: Erstellung einer Bibelstellenliste für $wit :)
let $refs := $gr//tei:citedRange[fn:not(./ancestor::tei:app) or fn:not(./ancestor::tei:app/tei:rdg[@wit = $wit (: change to fn:contains and test! :)  and @type ="om"]) or ./ancestor::tei:rdg[@wit = $wit and @type !="om"]]

let $n-tokens := for $x in $refs[@n] return fn:tokenize($x/@n/data(), " ")
let $n-arrays := for $t in $n-tokens
let $t-details := fn:tokenize($t, ":")
where count($t-details) = 3
return array {$t-details[1], $t-details[2], $t-details[3]}

let $from-arrays := 
    for $y in $refs[@from] 
    let $from-book := fn:tokenize($y/@from/data(), ":")[1]
    let $from-chapter := fn:tokenize($y/@from/data(), ":")[2]
    let $from-verse := xs:integer(fn:tokenize($y/@from/data(), ":")[3])
    let $to-verse := xs:integer(fn:tokenize($y/@to/data(), ":")[3])
    return 
        if ($y/@to = "ff") 
        then  
            for $n in ($from-verse to $from-verse + 2)
            return array {$from-book, $from-chapter, $n}
        else 
            if ($y/@to = "f") 
            then  
                for $n in ($from-verse to $from-verse + 1)
                return array {$from-book, $from-chapter, $n}
        else
        for $n in ($from-verse to $to-verse)
        return array {$from-book, $from-chapter, $n}

let $sum := ($n-arrays, $from-arrays)

(: Vergleich mit gegebener Bibelstelle :) 
let $cond := 
for $s in $sum 
let $s2 :=xs:integer($s(2))
let $s3 :=xs:integer($s(3))
return if ($book = $s(1) and xs:integer($chapter) = $s2 and xs:integer($verse) = $s3) then 1 else 0

return 
if ($cond = (1)) then 1
else 0

};

<table>
<tr><td>Stelle</td><td>#a</td><td>#b</td><td>#c</td><td>#d</td></tr>
{
for $x in $bible//VERS
let $x-book := $x/ancestor::BIBLEBOOK/@bsname
let $x-chapter := $x/ancestor::CHAPTER/@cnumber
let $x-verse := xs:integer($x/@vnumber)
let $x-profile := array {local:check("#a", $x-book, $x-chapter, $x-verse), local:check("#b", $x-book, $x-chapter, $x-verse), local:check("#c", $x-book, $x-chapter, $x-verse), local:check("#d", $x-book, $x-chapter, $x-verse)}
where $x-profile != [0,0,0,0] and $x-profile != [1,1,1,1] (: Diese zweite Bedingung ist optional. :)
return 

<tr><td>{$x-book || " " || $x-chapter || "," || $x-verse}</td><td>{$x-profile(1)}</td><td>{$x-profile(2)}</td><td>{$x-profile(3)}</td><td>{$x-profile(4)}</td></tr>
}
</table>