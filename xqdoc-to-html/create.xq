import module namespace xqdoc-to-html = 'http://basex.org/modules/xqdoc-to-html';

xqdoc-to-html:create(
  file:base-dir() || 'src/',
  file:base-dir() || 'html/',
  'Documentation',
  false()
)

