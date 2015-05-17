## Dragon Nest Tools
Here is where I make some tools I plan to be using for the Dragon Nest Skill Simulator.

## Current Tools
DNT to SQL Converter

Pak Extracter

## How To Extract Template - Basis
See ResourceUnpacker.bms

See http://aluigi.altervista.org/papers/quickbms.txt

## DDS Image Converter
http://www.imagemagick.org/

## Relevent File Locations
| info            | path                        |
| ----------------|---------------------------- |
| icons           | \resource\ui\mainbar        |
| skill-req icons | \resource\ui\skill          |
| more icons      | \resource\uitemplatetexture |
| description db  | \resource\uistring          |
| skill dnt       | \resource\ext               |
| skill videos    | \resource\movie             |

## Extra Notes
### File Compression
Files are compressed using ZLIB.
Refer to: https://docs.oracle.com/javase/7/docs/api/java/util/zip/Inflater.html

### Skill Image Grid
As a note to self:
The 20 x 10 equally spaced skill icon grid is referenced by an index.
Index 0 refers to the first icon, 1 refers to to the one to the right of it, etc.
Index 10 refers to the second row, first item. Index 11 refers to the one to the right of it, etc.

### Simplest way to import all .sql files
Windows:
`copy /b *.sql dnss.sql`

Unix:
`cat *.sql > dnss.sql`

Then import dnss.sql

### If you can't import messages.sql (from DNT2SQL), run this command on it:
`iconv -f utf-8 -t utf-8 -c messages.sql > clean_messages.sql`

And import that instead.

### Installing nokogiri gem
`apt-cyg install ruby-nokogiri`

### Installing pg gem (do not use cygwin's ruby-pg) 
`apt-cyg install postgresql postgresql-devel libpq-devel make gcc-core`

`gem install pg`