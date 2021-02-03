xquery version "3.1";
module namespace freq = "http://bdn-edition.de/xquery/crit";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: Counts the number of bible references per chapter and returns a map. 
: To do: JSON Output, XQuery-Application in JavaScript (e.g. XQIB)
:
: @version 0.3 (2021-02-03)
: @author Marco Stallmann
:
:)

declare function freq:count($converted as node()){
  let $edition := $converted//edition/text()
  let $chapters := $converted//div[@type = "chapter"]/head
  let $counts := 
    for $chapter in $converted//div[@type = "chapter"]
    return fn:count($chapter//ref)
  return
  map {
   "edition": $edition,
   "chapters": array{$chapters/data()},
   "counts": array{$counts}
   } 
};

(:~
: ALTE VERSION! Zählt die absoluten und relativen Häufigkeiten von Bibelreferenzen 
: tei:citedRange in einem gegebenen Dokument (hier: Griesbach-Gesamtdatei).
:
: Todo: 
: - Weitere Gliederungsebenen berücksichtigen
: - Für DHd-Bewerbung: (Manuelle) Erarbeitung von Beispielen/Zwischenergebnissen
:   (ggf. mithilfe des Printregisters oder der Oxygen-Suchfunktion)
: - Überprüfung und Präzisierung der Wortzählung (Berücksichtigung 
:   von „rdg“ / „choice“ / … ?)
: - Erarbeitung von Alternativlösungen für die Berechnung von relativen 
:   Häufigkeiten
: - Verbesserung der HTML-Tabellendarstellung / Elementkonstruktion
: - Hinzufügung einer graphischen Darstellung (ggf. Umwandlung in JSON / 
:   Ausgabe mithilfe der Open-Source-Datenvisualisierung Chart.js)
:
: @version 0.2 (2021-12-21)
: @author Marco Stallmann
:
:)

declare function freq:table($doc){
 <html>
    <head></head>
    <body>
    <p>
    <h1>Verweishäufigkeiten in den Hauptkapiteln</h1>
    <table>
    <tr>
            <td>Abschnitt:</td>
            <td>Absolute Häufigkeit von citedRange:</td>
            <td>Relativ zur Wortanzahl des Kapitels:</td>
        </tr>
    {
    let $chapters := $doc//tei:div[@type = "chapter"]
    for $c in $chapters
    return   
    <tr>
        <td>{$c/tei:head//tei:supplied[@reason="column-title"]/text()/fn:normalize-space(.)}</td>
        <td>{count($c//tei:citedRange)}</td>
        <td>{count($c//tei:citedRange) div freq:word-count($c)}</td>
    </tr>
    }
</table>
    </p>
        <h1>Verweishäufigkeiten in den Unterkapiteln</h1>
        <p>
<table>
    <tr>
            <td>Abschnitt:</td>
            <td>Absolute Häufigkeit von citedRange:</td>
            <td>Relativ zur Wortanzahl des Kapitels:</td>
        </tr>
    {
    let $section-groups := $doc//tei:div[@type = "section-group"]
    for $s in $section-groups
    return   
    <tr>
        <td>{$s/@xml:id/data()}</td>
        <td>{count($s//tei:citedRange)}</td>
        <td>{count($s//tei:citedRange) div freq:word-count($s)}</td>
    </tr>
    }
</table>
    </p>
</body>
</html>};

declare function freq:word-count
  ( $arg as xs:string? )  as xs:integer {
   count(tokenize($arg, '\W+')[. != ''])
 } ; 
