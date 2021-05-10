xquery version "3.1";
module namespace freq = "http://bdn-edition.de/xquery/freq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~
:
: Erstellt eine HTML-Tabelle auf Basis des konvertierten XML-Dokuments: 
: Für jedes biblische Buch, das in der edierten Quellenschrift vorkommt, wird 
: die Häufigkeit der Bibelreferenz ausgegeben.
:
: Dies ist ein anderer Ansatz als der "Bibelstellenspannungsbogen"
: (s. unten freq:table), wo die Häufigkeiten ausgehend von den einzelnen Kapiteln
: der edierten Quellenschrift ermittelt werden.
:
: Überlegung (Hannah): Kombination mit "Spannungsbogen" als weitere Funktion
:
: Todo: 
: - Ergebnis in Datei schreiben (mit file:write ??)
: - Übersichtlichkeit verbessern
:
: @version 0.1 (2021-02-22)
: @author ..., Marco Stallmann
:
:)

declare function freq:table2($doc, $bible){
let $books := $bible//tei:bibl/@ana
let $max-chapters := max($bible//tei:bibl/@n)
return
 <html>
    <head>
        <title>Bibelstellenstatistik</title>
    </head>
    <body>
   <table>
  <tr>
    <td>Kap.</td>
    {
      for $book in $books
      where freq:test-book($book, $doc) = 1
      return <td>{$book/data()}</td>
    }
  </tr>  
    {
      for $n in (1 to 50)
      return 
       <tr>
       <td>{$n}</td>
        { 
          for $book in $books
          where freq:test-book($book, $doc) = 1
          return <td>{freq:bible-book-stats($book, $n, $doc)}</td>}
    </tr>}  
</table>
   </body>
</html>
};


(:~
: Counts Bible-references in XML-Document with "book" and "chapter".
:
: @version 0.1 (2021-02-22)
: @author Marco Stallmann
:
:)

declare function freq:bible-book-stats($book, $chapter, $doc)
{
  let $refs := $doc//ref[@*[1] = $book and @*[2] = $chapter]
  let $count := fn:count($refs)
  return $count
};


(:~
: Tests if (converted!) XML-Document has Bible-references with "book"
:
: @version 0.1 (2021-02-22)
: @author Marco Stallmann
:
:)

declare function freq:test-book($book, $doc)
{
  if ($doc//ref[@*[1] = $book])
  then 1
  else 0
};

(:~
: Counts the number of bible references per chapter and returns a map. 
:
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
: Diese Funktion läuft noch ohne Zwischenformat (bdn.xqm).
:
: Todo (evtl. hinfällig):
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



(: Zählt die absoluten und relativen Häufigkeiten der Bibelstellen mit Verwendung des Zwischenformats, 
Kapitelbezeichnungen müssen jedoch aus der unkonvertierten Gesamtdatei gewonnen werden und erstellt eine html-Tabelle :)

(:für Griesbach, Steinbart "chapter", für Teller "letter":)
declare function freq:table_all($doc, $bible) 
{
<html>
<body>
<table>
<tr>
<td>Kapitel</td><td>absolut</td><td>relativ</td></tr>

{
let $titles := $doc//div[@type = "chapter"]/@column-title 
let $chapters := $doc//div[@type = "chapter"]
let $nr := count($titles)
for $n in (1 to $nr)
return
<tr>
<td>{data($titles[$n])}</td>
<td>{count($chapters[$n]//ref)}</td>
<td>{count($chapters[$n]//ref) div freq:word-count($doc_unconverted//tei:div[@type= "chapter"][$n])}</td>
</tr>
}
</table>
</body>
</html>
};

(:speziell für Nösselt und Leß:)

declare function freq:count_sec ($doc_unconverted)
{
 
let $sections := $doc_unconverted//tei:div[@type = "section"]
let $count_sec := for $s in $sections return count(tokenize($s, '\W+')[. != ''])
return $count_sec 
};

(:für Leß "section", für Nösselt "part":)

declare function freq:table_all_less($doc, $bible) 
{
<html>
<body>
<table>
<tr>
<td>Kapitel</td><td>absolut</td><td>relativ</td></tr>

{
let $titles := $doc//div[@type = "section"]/@column-title 
let $chapters := $doc//div[@type = "section"]
let $nr := count($titles)
for $n in (1 to $nr)
return
<tr>
<td>{data($titles[$n])}</td>
<td>{count($chapters[$n]//ref)}</td>
<td>{count($chapters[$n]//ref) div (freq:count_sec($doc_unconverted)[$n])}</td>
</tr>
}
</table>
</body>
</html>
};


(: Zählt die absoluten und relativen (in Relation zu der Gesamtanzahl aller Bibelstellen in einem Kapitel) Häufigkeiten 
eines bestimmten Bibelbuchs und erstellt eine html-Tabelle :)

(:für Griesbach, Steinbart "chapter", für Teller "letter", für Leß "section", für Nösselt "part":)
declare function freq:table_spec($doc, $bible, $book)
{
<html>
<body>
<table>
<tr>
<td>Kapitel/{$book}</td><td>absolut</td><td>relativ</td></tr>
{
let $titles := $doc//div[@type ="letter"]/@column-title
let $chapters := $doc//div[@type ="letter"]
let $n_ref := for $c in $chapters return fn:count($c//ref)
let $nr := count($chapters)
for $n in (1 to $nr)
return
if ($n_ref[$n] = 0) then
<tr>
<td>{data($titles[$n])}</td>
<td>{count($chapters[$n]//ref[@*[1] = $book])}</td>
<td>{count($chapters[$n]//ref [@*[1] = $book]) div (count($chapters[$n]//ref)+ 1)}</td>
</tr>
else
<tr>
<td>{data($titles[$n])}</td>
<td>{count($chapters[$n]//ref[@*[1] = $book])}</td>
<td>{count($chapters[$n]//ref [@*[1] = $book]) div (count($chapters[$n]//ref))}</td>
</tr>
}
</table>
</body>
</html>};



(: Erstellt eine map, die als keys, die Kapitelüberschriften, die absoluten Häufigkeiten aller Bibelstellen eines Kapitels 
und die absoluten Häufigkeiten der Bibelstellen eines bestimmten Buchs innerhalb eines Kapitels enthält:)


(:für Griesbach, Steinbart "chapter", für Teller "letter", für Leß "section", für Nösselt "part":)
declare function freq:count_spec($book) {
let $chapters := $doc//div[@type ="section"]
let $titles := data($doc//div[@type ="section"]/@column-title)
let $count := 
for $c in $chapters return fn:count($c//ref)
let $count_spec := 
for $c in $chapters return fn:count($c//ref[@*[1] = $book])

return
map {
"items": array{$titles},
"chapters_count": array{$count},
"chapters_count_spec": array{$count_spec}
}
};
