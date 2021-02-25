(:~
 : This module generates a single HTML page for xqDoc input.
 : @author Christian Grün, BaseX Team
 :)
module namespace xqdoc-to-html = 'http://basex.org/modules/xqdoc-to-html';

(:~ Supported tags. :)
declare variable $xqdoc-to-html:TAGS := ("description", "author", "version", "param",
  "error", "deprecated", "see", "since");

(:~
 : Creates html pages for the specified project.
 : @param  $input    directory with XQuery source files
 : @param  $output   html output directory
 : @param  $title    title of the documentation
 : @param  $modules  module paths and inspected modules
 : @param  $private  include private functions and variables
 :)
declare function xqdoc-to-html:create(
  $input    as xs:string,
  $output   as xs:string,
  $title    as xs:string,
  $private  as xs:boolean
) as empty-sequence() {
  (: delete old files :)
  if (file:exists($output)) then file:delete($output, true()) else (),
  file:create-dir($output),
  
  (: create new files :)
  let $files := file:list($input, true(), '*.xq*') ! replace(., '\\', '/')
  let $modules := map:merge(
    for $file in $files
    return map { $file: inspect:module($input || $file) }
  )
  return (
    xqdoc-to-html:create-doc($modules, $output, $title, $private),
    xqdoc-to-html:create-index($modules, $output, $title)
  )
};

(:~
 : Creates html pages for the specified modules.
 : @param  $modules  module paths and inspected modules
 : @param  $output   html output directory
 : @param  $title    title of the documentation
 : @param  $private  include private functions and variables
 :)
declare function xqdoc-to-html:create-doc(
  $modules  as map(*),
  $output   as xs:string,
  $title    as xs:string,
  $private  as xs:boolean
) as empty-sequence() {
  for $path in map:keys($modules)
  let $level := count(tokenize($path, '/')) - 1 return
  let $html := 
    <html>
      { xqdoc-to-html:head($title, $level) }
      <body>{
        xqdoc-to-html:logo($level),
        xqdoc-to-html:create-page($path, $modules($path), $private)
      }</body>
    </html>
  let $name := replace($path, '\.xqm?', '')
  return (
    file:create-dir(file:parent($output || $name)),
    xqdoc-to-html:write-html($output || $name || '.html', $html)
  )
};

(:~
 : Stores the documentation framework files.
 : @param $modules  module paths and inspected modules
 : @param  $output   html output directory
 : @param  $title    title of the documentation
 :)
declare function xqdoc-to-html:create-index(
  $modules  as map(*),
  $output   as xs:string,
  $title    as xs:string
) as empty-sequence() {
  let $html := <html>
    { xqdoc-to-html:head($title, 0) }
    <frameset cols="320,*">
      <frame name="modules" src="modules.html"/>
      <frame name="text" src="text.html"/>
    </frameset>
  </html>
  return xqdoc-to-html:write-html($output || 'index.html', $html),

  let $html := <html>
    { xqdoc-to-html:head($title, 0) }
    <body>
      <h2><a href='text.html' target='text'>Index</a></h2>{
        for $path in map:keys($modules)
        order by $path
        let $name := replace($path, '\.xqm?', '')
        return <div><a target='text' href="{ $name }.html">{ $name }</a></div>
    }</body>
  </html>
  return xqdoc-to-html:write-html($output || 'modules.html', $html),

  let $html := <html>
    { xqdoc-to-html:head($title, 0) }
    <body>
      { xqdoc-to-html:logo(0) }
      <h1>{ $title }</h1>
      <h2>Module List</h2>
      <table>{
        for $path in map:keys($modules)
        order by $path
        let $name := replace($path, '\.xqm?', '')
        return <tr><td>{
          <a target='text' href="{ $name }.html">{ $name }</a>
        }</td><td>{
          (: Choose first sentence of description. :)
          let $text := string-join(($modules($path)/description//text()), ' ')
          return replace(normalize-space($text), '\..*', '.')
        }</td></tr>
      }</table>
    </body>
  </html>
  return xqdoc-to-html:write-html($output || 'text.html', $html),

  (: copy media files :)
  ('style.css', 'basex.svg') ! file:copy(file:base-dir() || ., $output || .)
};

(:~
 : Writes an HTML page to disk.
 : @param $path  target path
 : @param $html  HTML contents
 :)
declare function xqdoc-to-html:write-html(
  $path  as xs:string,
  $html  as element(html)
) as empty-sequence() {
  file:write($path, $html, map {
    'method': 'xhtml',
    'omit-xml-declaration': 'no',
    'doctype-public': '-//W3C//DTD XHTML 1.0 Transitional//EN',
    'doctype-system': 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'
  })
};

(:~
 : Creates a single HTML page for the specified module.
 : @param  $path     path to query module
 : @param  $inspect  inspected module
 : @param  $private  include private functions and variables
 : @return body elements
 :)
declare function xqdoc-to-html:create-page(
  $path     as xs:string,
  $inspect  as element(module),
  $private  as xs:boolean)
  as node()*
{
  <h2>{
    if ($inspect/@prefix) then 'Library' else 'Main',
    'Module:', replace($path, '^./', '')
  }</h2>,
  <table>{
    if (empty($inspect/@prefix)) then () else
    <tr>
      <td><b>URI:</b></td>
      <td><code>{ $inspect/@uri/string() }</code></td>
    </tr>,
    xqdoc-to-html:tags($inspect)
  }</table>,

  xqdoc-to-html:variables($inspect, $private),
  xqdoc-to-html:functions($inspect, $private)
  (:,<h2>Source Documentation</h2>,<pre>{ serialize($inspect) }</pre>:)
};

(:~
 : Creates a description of all variables.
 : @param  $inspect  information on the inspected module
 : @param  $private  include private functions and variables
 : @return description of variables
 :)
declare function xqdoc-to-html:variables(
  $inspect  as element(module),
  $private  as xs:boolean
) as element()* {
  let $variables := $inspect/variable[
    $private or not(annotation/@name = 'private')
  ]
  where $variables
  return (
    <h2>Variables</h2>,
    (:<ul>{
      for $v at $p in $variables
      let $n := $v/@name/string()
      order by $n
      return <li><a href="#{ $n }">{ $n }</a></li>
    }</ul>,:)

    for $v at $p in $variables
    let $n := replace($v/@name, '.*:', '')
    order by $n
    let $link := replace($v/@name, '.*:', '')
    return (
      <h3 name="{ $link }">${ $n }</h3>,
      <table>{
        for $t in $v/@type/string()
        return <tr>
          <td><b>Type:</b></td>
          <td><code>{ $t }</code></td>
        </tr>,
        xqdoc-to-html:tags($v)
      }</table>
    )
  )
};

(:~
 : Creates a description of all functions.
 : @param  $inspect  information on the inspected module
 : @param  $private  include private functions and variables
 : @return description of functions
 :)
declare function xqdoc-to-html:functions(
  $inspect  as element(module),
  $private  as xs:boolean)
  as element()*
{
  let $functions := $inspect/function[
    $private or not(annotation/@name = 'private')
  ]
  let $signatures := $functions !
    (replace(@name, '.*:', '') || '(' || string-join(
      argument ! ('$' || @name), ', '
    ) || ')')
  where $functions
  return (
    <h2>Functions</h2>,
    for $f at $p in $functions
    let $s := $signatures[$p]
    let $link := replace($f/@name, '.*:', '') || '#' || count($f/argument)
    order by $s
    return (
      <a name="{ $link }"><h3>{ $s }</h3></a>,
      <table>{
        let $args := $f/argument where $args return
        <tr>
          <td><b>Arguments:</b></td>
          <td>
            <table>{
              for $a in $args
              return <tr>
                <td><code>${ $a/@name/string() }</code></td>
                <td>{
                  let $t := $a/@type || $a/@occurrence
                  where $t
                  return <code>{ $t }</code>
                }</td>
                <td>{ $a/node() }</td>
              </tr>
            }</table>
          </td>
        </tr>,

        let $return := $f/return
        where $return[@type|node()]
        return <tr>
          <td><b>Returns:</b></td>
          <td><table><tr>{
            let $t := $return/@type || $return/@occurrence
            where $t
            return <td><code>{ $t }</code></td>,
            <td>{ $return/node() }</td>
          }</tr></table></td>
        </tr>,

        for $throws in $f/tag[@name = 'throws']
        return <tr>
          <td><b>Throws:</b></td>
          <td>{ $throws/node() }</td>
        </tr>,

        let $annotations := $f/annotation
        where $annotations
        return <tr>
          <td><b>Annotations:</b></td>
          <td><table>{
            for $a in $annotations return (
              <tr><td><code>%{
                $a/@name ||
               (let $l := $a/literal
                where $l
                return '(' || string-join(
                  $l ! (if (@type = 'xs:string') then 
                    ('"' || . || '"') else .), ', ') || ')'
              )}</code></td></tr>
            )
          }</table></td>
        </tr>,

        xqdoc-to-html:tags($f)
      }</table>
    )
  )
};

(:~
 : Lists all supported tags from the specified node.
 : @param $node  root node
 : @return       tags
 :)
declare function xqdoc-to-html:tags(
  $node as element())
  as element(tr)*
{
  for $key in $node/*
  let $name := name($key)
  where $name = $xqdoc-to-html:TAGS
  let $value := $key/node()
  where $value
  return <tr>
    <td><b>{ xqdoc-to-html:capitalize($name) }:</b></td>
    <td>{ $value }</td>
  </tr>
};

(:~
 : Creates a page header.
 : @param  $title  title of the documentation
 : @param  $level  level depth of target file
 : @return header
 :)
declare function xqdoc-to-html:head(
  $title  as xs:string,
  $level  as xs:integer
) {
  <head>
    <title>{ $title }</title>
    <link rel="stylesheet" type="text/css"
      href="{ string-join((1 to $level) ! '../') }style.css"/>
  </head>
};

(:~
 : Creates a page logo.
 : @param  $level  level depth of target file
 : @return div element
 :)
declare function xqdoc-to-html:logo($level as xs:integer) {
  <div class="right"><img width="104"
    src="{ string-join((1 to $level) ! '../')}basex.svg"/></div>
};

(:~
 : Capitalizes the specified string.
 : @param string  string to be capitalized
 : @return        resulting string
 :)
declare %private function xqdoc-to-html:capitalize($string) {
  upper-case(substring($string, 1, 1)) ||
  lower-case(substring($string, 2))
};
