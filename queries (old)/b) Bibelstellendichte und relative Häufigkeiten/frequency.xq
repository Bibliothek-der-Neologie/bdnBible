(:~
Das Modul zählt die absoluten und relativen Häufigkeiten von Bibelreferenzen tei:citedRange in einem gegebenen Dokument (hier: Griesbach-Gesamtdatei, textgrid:3rj87.0).
Todo: 
- Weitere Gliederungsebenen berücksichtigen
- Für DHd-Bewerbung: (Manuelle) Erarbeitung von Beispielen/Zwischenergebnissen (ggf. mithilfe des Printregisters oder der Oxygen-Suchfunktion)
- Überprüfung und Präzisierung der Wortzählung (Berücksichtigung von „rdg“ / „choice“ / … ?)
- Erarbeitung von Alternativlösungen für die Berechnung von relativen Häufigkeiten
- Verbesserung der HTML-Tabellendarstellung 
- Hinzufügung einer graphischen Darstellung (ggf. Umwandlung in JSON / Ausgabe mithilfe der Open-Source-Datenvisualisierung Chart.js)
:)

xquery version "3.1";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare option saxon:output "method=html";

declare function functx:word-count
  ( $arg as xs:string? )  as xs:integer {
   count(tokenize($arg, '\W+')[. != ''])
 } ;
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
    let $chapters := doc("textgrid:3rj87.0")//tei:div[@type = "chapter"]
    for $c in $chapters
    return   
    <tr>
        <td>{$c/tei:head//tei:supplied[@reason="column-title"]/text()/fn:normalize-space(.)}</td>
        <td>{count($c//tei:citedRange)}</td>
        <td>{count($c//tei:citedRange) div functx:word-count($c)}</td>
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
    let $section-groups := doc("textgrid:3rj87.0")//tei:div[@type = "section-group"]
    for $s in $section-groups
    return   
    <tr>
        <td>{$s/@xml:id/data()}</td>
        <td>{count($s//tei:citedRange)}</td>
        <td>{count($s//tei:citedRange) div functx:word-count($s)}</td>
    </tr>
    }
</table>
    </p>
</body>
</html>