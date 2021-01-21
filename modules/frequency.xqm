xquery version "3.1";
module namespace freq = "http://bdn-edition.de/xquery/crit";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: Zählt die absoluten und relativen Häufigkeiten von Bibelreferenzen 
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
: - Verbesserung der HTML-Tabellendarstellung 
: - Hinzufügung einer graphischen Darstellung (ggf. Umwandlung in JSON / 
:   Ausgabe mithilfe der Open-Source-Datenvisualisierung Chart.js)
:
: @version 0.2 (2021-12-21)
: @author Marco Stallmann
:
:)

declare function freq:word-count
  ( $arg as xs:string? )  as xs:integer {
   count(tokenize($arg, '\W+')[. != ''])
 } ;
 
 
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