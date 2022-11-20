# LDS General Conference for e-readers

**[jasoncarloscox.com/creations/conf-to-epub](https://jasoncarloscox.com/creations/conf-to-epub/)**

A script to convert LDS General Conference to EPUB, as well as converted files for past conferences.

These are pretty basic EPUBs -- the footnotes are removed, images may not show up right, and links aren't guaranteed to work -- but if you just want a table of contents and the text of each talk, they should be good enough.

## Gimme the files

If you just want to download the files for your e-reader, check out the `conferences/` directory. Currently `.epub` and `.mobi` files are provided, as those are what my wife and I need for our e-readers.

If the format you need isn't there, try using a tool like [Calibre](https://calibre-ebook.com/) (desktop application that also ships with the `ebook-convert` CLI) or [Cloud Convert](https://cloudconvert.com/epub-converter) (online converter) to convert the `.epub` file to the format you need.

## I want to use the script

### Requirements

The Bash script depends on [curl](https://curl.sh), [htmlq](https://github.com/mgdm/htmlq) and [pandoc](https://pandoc.org).

### Usage

`conf-to-epub.sh <year> <month> [<language>]`

- `<year>` is 4 digits
- `<month>` is one of `april`, `apr`, `4`, `04`, `october`, `oct`, `10` (case-insensitive)
- `<language>` (optional) is the argument to the `lang` query parameter on the `churchofjesuschrist.org` URLs and defaults to `eng`

## I want to get in touch

If you have questions, suggestions, etc., you can open a GitHub issue or contact me at [hi@jasoncarloscox.com](mailto:hi@jasoncarloscox.com).
