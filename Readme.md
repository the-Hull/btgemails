# btgemails

## Background

Extract names of current members of the German parliament and construct their email addresses based on a set of rules (with some exceptions). The information was derived from [https://www.bundestag.de/abgeordnete/biografien/]() See [R/01_scrape_bta.R]() for the procedure.

The final data set is found in [data/kontaktae_bundestagsabgeordnete.xlsx]().

The data set has eight columns:

| Column          | Content                                                                    |
|----------------|-------------------------------------------------------|
| titel           | academic title(s)                                                          |
| nachname_prefix | other title(s)                                                             |
| nachname        | last name (unmodified)                                                     |
| vorname         | first name (unmodified)                                                    |
| email_nachname  | last name, modified (removed special characters, e.g., ü, é)               |
| email_vorname   | first name, modified (removed special characters, e.g., ü, é)              |
| email           | email address, generated as \`email_vorname.email_nachname\@bundestag.de\` |
| partei          | current party membership                                                   |

: Data description

------------------------------------------------------------------------

## License

MIT License

Copyright (c) 2022 Alexander Hurley

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
