# LDS General Conference for e-readers

**[jasoncarloscox.com/creations/conf-to-epub](https://jasoncarloscox.com/creations/conf-to-epub/)**

A script to convert LDS General Conference to EPUB, as well as converted files for past conferences.

These are pretty basic EPUBs -- the footnotes are removed, images may not show up right, and links aren't guaranteed to work -- but if you just want a table of contents and the text of each talk, they should be good enough.

## Gimme the files

If you just want to download the files for your e-reader, check out the `conferences/` directory. Currently `.epub` files are provided (plus `.mobi` for some older conferences).

For recent conferences, there are two different EPUB files: the one created by pandoc, ending in `.epub`; and another created by converting that EPUB to AZW3 and back to EPUB, ending in `.converted.epub`. These converted EPUBs exist to work around issues with Amazon's import service (see [issue #2](https://github.com/jasonccox/conf-to-epub/issues/2)) -- try them out if the normal `.epub` files don't work for you.

If the format you need isn't there, try using a tool like [Calibre](https://calibre-ebook.com/) (desktop application that also ships with the `ebook-convert` CLI) or [Cloud Convert](https://cloudconvert.com/epub-converter) (online converter) to convert the `.epub` file to the format you need.

## I want to use the script

### Requirements

The Bash script depends on [curl](https://curl.sh), [htmlq](https://github.com/mgdm/htmlq) and [pandoc](https://pandoc.org). Optionally, if [ebook-convert](https://manual.calibre-ebook.com/generated/en/ebook-convert.html) is available, files will be converted to AZW3 and back to EPUB as well.

### Usage

`conf-to-epub.sh <year> <month> [<language>]`

- `<year>` is 4 digits
- `<month>` is one of `april`, `apr`, `4`, `04`, `october`, `oct`, `10` (case-insensitive)
- `<language>` (optional) is the argument to the `lang` query parameter on the `churchofjesuschrist.org` URLs and defaults to `eng`

## I need help / I want to contribute

Contributions are welcome! You can send questions, bug reports, patches, etc. by email to [~jcc/public-inbox@lists.sr.ht](https://lists.sr.ht/~jcc/public-inbox). (Don't know how to contribute via email? Check out the interactive tutorial at [git-send-email.io](https://git-send-email.io), or [email me](mailto:me@jasoncarloscox.com) for help.)

GitHub issues and pull requests are fine, too.
