(:~ 
Hier handelt es sich um eine Modifikation der Abfrage units.xqm! Sie arbeitet ebenfalls mit der Funktion local:verse-unit-count-refs, gibt aber nun 
eine geordnete Rangliste der am meisten referenzierten Sinneinheiten im Bde.-Vergleich aus: aktuell Nösselt ($noe), Griesbach ($gr) und Steinbart ($st). 
Geordnet wird die Liste anhand der Gesamtsumme ($sum).
Was in der units-xqm die Variable $sum-u-refs bewerkstelligt, läuft hier über die inline-Funktion $include-parts. 
Todo:
- Präzisierung der from/to-Auswertung [Was heißt das? Genauer!]
- Implementierung des Teller-Wörterbuchs in die Abfrage und die Tabellendarstellung
- Für DHd-Bewerbung: (Manuelle) Erarbeitung von Beispielen/Zwischenergebnissen (ggf. mithilfe des Printregisters oder der Oxygen-Suchfunktion)
- Vereinheitlichung $sum-u-refs (units.xqm) und $include-parts (hier!); ggf. Löschung beider, wenn vorerst nur Sinneinheiten auf Versebene ausgewertet werden sollen
- Erstellung einer bdnBible-Funktionenbibliothek (u.a. für local:verse-unit-count-refs)
- Konzept für Verbesserung der Vergleichbarkeit von Nösselt, Griesbach usw. (evtl. relative Häufigkeiten? Vgl. die Wortanzahl-Funktion functx:word-count in der Abfrage frequency.xqm)
- Fehlerkorrektur / Code-Verbesserung / Funktionenredundanz beheben
- Verbesserung der Tabellendarstellung
:)

xquery version "3.1";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/html";

declare function local:verse-unit-count-refs($unit, $xml) as xs:integer
{

let $unit-book := $unit/ancestor::BIBLEBOOK/@bsname
let $unit-chapter := fn:number($unit/ancestor::CHAPTER/@cnumber/data())
let $unit-verse-min := fn:number($unit/VERS[1]/@vnumber/data())
let $unit-verse-max := fn:number($unit/VERS[last()]/@vnumber/data())

(: citedRange mit n :)
let $xml-n-refs := $xml//tei:citedRange/@n/data(fn:tokenize(., " "))

return 
count($xml-n-refs
[fn:tokenize(., ":")[1] eq $unit-book and
fn:number(fn:tokenize(., ":")[2]) eq $unit-chapter and
fn:number(fn:tokenize(., ":")[3]) ge $unit-verse-min and
fn:number(fn:tokenize(., ":")[3]) le $unit-verse-max
]) 
+ 
count($xml//tei:citedRange[
./@from/fn:tokenize(., ":")[1] eq $unit-book and
./@to/fn:tokenize(., ":")[1] eq $unit-book and

./@from/fn:number(fn:tokenize(., ":")[2]) eq $unit-chapter and
./@to/fn:number(fn:tokenize(., ":")[2]) eq $unit-chapter and

./@from/fn:number(fn:tokenize(., ":")[3]) ge $unit-verse-min and (: "oder"! :)
./@to/fn:number(fn:tokenize(., ":")[3]) le $unit-verse-max
])
};


<html>
    <head></head>
    <body>  
        <table>
        <tr><td>Rang</td><td>Sinneinheit</td><td>H_noe</td><td>H_gr</td><td>H_st</td><td>Summe</td></tr>
        {
        let $bible := doc("textgrid:3vqhq.0")
        let $noe := doc("textgrid:3rj88.0")
        let $gr := doc("textgrid:3rj87.0")    
        let $st := doc("textgrid:3r960.0")
    
        let $include-parts := function($u, $x) as xs:integer 
        { fn:sum(for $u in $bible//unit[@ref = $u/@name] return local:verse-unit-count-refs($u, $x)) }
        let $sum := function($u) as xs:integer
        {local:verse-unit-count-refs($u, $noe) +$include-parts($u, $noe) 
        + local:verse-unit-count-refs($u, $gr) +$include-parts($u, $gr)
        + local:verse-unit-count-refs($u, $st) +$include-parts($u, $st)}
        
        for $unit in $bible//unit[@name]
        order by $sum($unit) descending
        count $n
        
        return           
            
            <tr>
                <td>{$n}</td>
                <td> {$unit/@name/data()}</td>
                <td>{local:verse-unit-count-refs($unit, $noe) +$include-parts($unit, $noe)}</td>
                <td>{local:verse-unit-count-refs($unit, $gr) +$include-parts($unit, $gr)}</td>
                <td>{local:verse-unit-count-refs($unit, $st) +$include-parts($unit, $st)}</td>
                <td>{$sum($unit)}</td>
            </tr>
        }
        </table>      
    </body>
</html>
