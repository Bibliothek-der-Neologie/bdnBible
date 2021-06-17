xquery version "3.1";
module namespace freq = "http://bdn-edition.de/xquery/freq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: Zählt die absoluten und relativen Häufigkeiten der Bibelstellen mit Verwendung des Zwischenformats, 
: Kapitelbezeichnungen müssen jedoch aus der unkonvertierten Gesamtdatei gewonnen werden und erstellt eine html-Tabelle 
: 
: für Griesbach, Steinbart, Sack "chapter", für Teller "letter", für Leß "section", für Nösselt "part"
:
: @version 1.2 (2021-05-19)
: @author Hannah Kreß
:
:)


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
let $words := $doc//div[@type = "chapter"]/@words
let $nr := count($titles)
for $n in (1 to $nr)
return
<tr>
<td>{data($titles[$n])}</td>
<td>{count($chapters[$n]//ref)}</td>
<td>{count($chapters[$n]//ref) div (data($words))[$n]}</td>
</tr>
}
</table>
</body>
</html>
};



(:~
: Zählt die absoluten und relativen (in Relation zu der Gesamtanzahl aller Bibelstellen in einem Kapitel) Häufigkeiten 
: eines bestimmten Bibelbuchs und erstellt eine html-Tabelle 
: 
: für Griesbach, Steinbart, Sack "chapter", für Teller "letter", für Leß "section", für Nösselt "part"
:
: @version 1.2 (2021-05-19)
: @author Hannah Kreß
:
:)
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



(:~
: Erstellt eine map, die als keys, die Kapitelüberschriften, die absoluten Häufigkeiten aller Bibelstellen eines Kapitels 
: und die absoluten Häufigkeiten der Bibelstellen eines bestimmten Buchs innerhalb eines Kapitels enthält
: 
: ToDo: gewünschte Visualisierung
:
: @version 1.1 (2021-04-21)
: @author Hannah Kreß
:)


(:für Griesbach, Steinbart, Sack "chapter", für Teller "letter", für Leß "section", für Nösselt "part":)
declare function freq:count_spec($doc, $book) {
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

declare function freq:table2($doc as item()){
let $bible := doc("../data/bible_structure.xml")
let $books := $bible//tei:bibl/@ana
let $max-chapters := max($bible//tei:bibl/@n)
let $filename := "output/freq_table2_"||fn:lower-case(substring($doc//edition, 1, 2))||".html"
return file:write( $filename , 
 <html>
    <head>
        <title>Bibelstellenstatistik</title>
    </head>
    <body>
      <div>
      <p>Bibelstellenstatistik: {$doc//edition/data()}</p>
</div>
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
          let $stats := freq:bible-book-stats($book, $n, $doc)
          let $color := "background-color: hsl(200, 80%, "||100 - $stats||"%);" 
          where freq:test-book($book, $doc) = 1 (: $stats > 0 :)
          return <td style="{$color}">{$stats}</td>}
    </tr>}  
</table>
   </body>
</html>
)};


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

declare function freq:word-count
  ( $arg as xs:string? )  as xs:integer {
   count(tokenize($arg, '\W+')[. != ''])
 } ; 


