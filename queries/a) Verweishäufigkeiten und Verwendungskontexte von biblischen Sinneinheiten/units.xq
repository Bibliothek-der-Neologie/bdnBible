(:~ 
Dieses Modul arbeitet mit einer modifizierten Version des „Zefanja XML bible modules“, hier in der Luther-Übersetzung von 1912 mit Apokryphen (abgelegt 
im TG-Lab als textgrid:3vqwx). Diese ist um die im Proposal beschriebenen Sinneinheiten erweitert worden (suche im XML-Code nach „unit“), 
z.B. Johannesprolog Joh 1,1-18. 
Das XQuery-Modul prüft nun mithilfe einer Funktion local:verse-unit-count-refs alle in der erweiterten Bibel-XML definierten Struktureinheiten „unit“ auf 
das Vorkommen entsprechender Verweise „citedRange“ im Rahmen der Editionsdaten (hier: Griesbach-Gesamtdatei, textgrid:3rj87.0) und gibt die Häufigkeiten 
als HTML-Tabelle aus. 
Die Variable $sum-u-refs im unteren Teil ergänzt mit der gleichen Funktion die Elemente „unit“, die das Attribut „ref“ (statt „name“) besitzen. Damit 
sollen kapitelübergeifende Sinneinheiten einbezogen werden (vgl. das „unit“-Element zur Bergpredigt). 
Todo: 
- Erweiterung der Bibel-XML um statistisch-relevante (langfristig: alle) Sinnheiten 
- Für DHd-Bewerbung: Ausschalten von $sum-u-refs und vorläufige Beschränkung des Moduls auf Sinnheiten auf Versebene (ggf. Bergpredigt I, II und III)
- Für DHd-Bewerbung: (Manuelle) Erarbeitung von Beispielen/Zwischenergebnissen (ggf. mithilfe des Printregisters oder der Oxygen-Suchfunktion)
- Überprüfung und Verbesserung der Funktion local:verse-unit-count-refs (insbesondere der  Auswertung @from / @to)
- Implementierung des Zefanja XML-Schemas ( http://bgfdb.de/zefaniaxml/bml ) in den XQuery-Prolog
- Beseitigung der Fehlermeldung in der Bibel-XML
- Fehlerkorrektur / Code-Verbesserung / Funktionenredundanz beheben
- Verbesserung der Tabellendarstellung
- Für Dhd-Vortrag: Häufigkeiten kapitel- oder gar buchübergreifender Sinneinheiten auf eigener Ebene auswerten (eigene Tabellenspalten), um Vergleichbarkeit herzustellen
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
    {
    let $bible := doc("textgrid:3vqhq.0")
    let $x := doc("textgrid:3rj87.0")
    return
        <p>
        {
        for $b in $bible//BIBLEBOOK[.//unit]
        let $units := $b//unit
        return 
            <details>
                <summary>{$b/@bsname/data()}</summary>
                <p>
                {
                for $u in $units[@name]
                let $u-refs := $units[@ref = $u/@name]
                let $count-u-refs := for $u in $u-refs return local:verse-unit-count-refs($u, $x)
                let $sum-u-s :=local:verse-unit-count-refs($u, $x)
                let $sum-u-refs := fn:sum($count-u-refs)
                let $sum := $sum-u-s + $sum-u-refs
                return 
                    <table>
                        <tr>
                            <td>{$u/@name/data()}</td>
                            <td>{if ($u/VERS) then $sum else "Chapter Unit! To do ..."}</td>
                        </tr>
                    </table>
                }
                </p>
            </details>
        }
        </p>
      
    }
    </body>
</html>
