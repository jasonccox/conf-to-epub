#!/bin/bash
#
# conf-to-epub.sh -- convert a session of LDS General Conference to an epub file

### PARSE ARGUMENTS ###

year="$1"
month="$2"
language="${3:-eng}"

if [ -z "$year" ] || [ -z "$month" ]; then
    echo USAGE: "$0 <year> <month> [<language>]"
    exit 1
fi

if [ "$(echo "$year" | grep -E -o '(19|20)[0-9][0-9]')" != "$year" ]; then
    echo Invalid year
    exit 1
fi

case "$month" in
    april|April|apr|Apr|4|04)
        month=04
        month_name=April
        ;;
    october|October|oct|Oct|10)
        month=10
        month_name=October
        ;;
    *)
        echo Invalid month
        exit 1
        ;;
esac

### SETUP VARIABLES ###

base_url="https://www.churchofjesuschrist.org"
conference_url="https://www.churchofjesuschrist.org/study/general-conference/$year/$month?lang=$language"
script_dir="$(cd "$(dirname "$0")" && pwd)"
build_dir="$(mktemp -d)"
metadata_file="$build_dir/title.txt"
build_files="$metadata_file"
trap "rm -rf '$build_dir'" EXIT

### LIST SESSIONS AND TALKS ###

echo Getting list of talks
talk_paths="$(
    curl --silent --location "$conference_url" | \
        htmlq --attribute href ".body nav a"
)"

if [ $? != 0 ]; then
    echo Failed to get a list of talks
    exit 1
fi

### DOWNLOAD COVER IMAGE ###

echo Getting cover image
listing_url="https://www.churchofjesuschrist.org/study/general-conference?lang=$language"
cover_img_url="$(
    curl --silent --location "$listing_url" | \
        htmlq "a[href*='/$year/$month'] img" --attribute src | \
        head -1 | \
        sed 's|/full/.*|/full/!1280,/0/default|'
)"

cover_file=""
if [ -n "$cover_img_url" ]; then
    cover_raw="$build_dir/cover-raw.jpg"
    cover_file="$build_dir/cover.jpg"
    curl --silent --location "$cover_img_url" > "$cover_raw"

    if command -v magick >/dev/null 2>&1; then
        echo Adding text overlay to cover

        magick "$cover_raw" \
            -gravity North \
            -font Helvetica-Bold \
            -pointsize 170 \
            -stroke white -strokewidth 24 -fill black \
            -annotate +0+30 "$month_name $year" \
            -stroke none -fill black \
            -annotate +0+30 "$month_name $year" \
            -pointsize 110 \
            -stroke white -strokewidth 18 -fill black \
            -annotate +0+220 "General Conference" \
            -stroke none -fill black \
            -annotate +0+220 "General Conference" \
            -gravity South \
            -font Helvetica \
            -pointsize 72 \
            -stroke white -strokewidth 15 -fill black \
            -annotate +0+40 "The Church of Jesus Christ\nof Latter-day Saints" \
            -stroke none -fill black \
            -annotate +0+40 "The Church of Jesus Christ\nof Latter-day Saints" \
            "$cover_file"
    else
        echo Skipping text overlay because magick command not found
        cover_file="$cover_raw"
    fi
else
    echo Failed to find cover image, skipping
fi

### OUTPUT METADATA ###

echo Creating metadata
cat >"$metadata_file" <<EOF
---
title: $month_name $year General Conference
author: The Church of Jesus Christ of Latter-day Saints
---
EOF

### GET SESSION AND TALK CONTENT ###

echo Getting sessions and talks
for talk_path in $talk_paths; do
    echo Getting "$talk_path"
    url="$base_url$talk_path"
    name="$(echo "$talk_path" | grep -E -o '[^/]+$')"
    html_file="$build_dir/$name-raw.html"
    stage_file="$build_dir/$name-stage.html"

    curl --silent --location "$url" > "$html_file"
    title="$(htmlq --filename "$html_file" --text ".body h1")"
    subtitle="$(htmlq --filename "$html_file" --text ".body .subtitle")"
    author="$(htmlq --filename "$html_file" --text ".body .byline p:first-of-type" | sed 's/By *//')"
    author_with_role="$(htmlq --filename "$html_file" --text ".body .byline")"
    summary="$(htmlq --filename "$html_file" --text ".body .kicker")"

    [ -n "$subtitle" ] && title="$title $subtitle"
    [ -z "$author" ] && author="$author_with_role"
    [ -n "$author" ] && title="$title ($author)"

    echo "<h1>$title</h1>" >"$stage_file"
    [ -n "$author_with_role" ] && echo "<p><em>$author_with_role</em></p>" >>"$stage_file"
    [ -n "$summary" ] && echo "<p><em>$summary</em><p>" >>"$stage_file"

    # only include body for talks, not sessions
    if [ "${name%-session}" = "$name" ]; then
        htmlq --filename "$html_file" ".body .body-block" >>"$stage_file"
    fi

    # building the epub from markdown works much better than HTML, so convert to
    # markdown, removing footnotes and adding the hostname to link URLs
    talk_file="$build_dir/$name.md"

    pandoc -f html -t commonmark --wrap none -o - "$stage_file" | \
        sed \
        -e 's#\[<sup>[0-9]\+</sup>\]([^)]*)##g' \
        -e 's#<a [^>]*><sup>[0-9]\+</sup></a>##g' \
        -e "s#\](/#]($base_url/#g" \
        -e "s#href=\"/#href=\"$base_url/#g" \
        >"$talk_file"
    build_files="$build_files $talk_file"
done

### CONVERT TO EPUB ###

echo Converting to epub

dir="conferences/$year/$month"
mkdir -p "$dir"
file_base="$dir/general-conference-$year-$month-$language"

cover_args=""
if [ -n "$cover_file" ] && [ -f "$cover_file" ]; then
    cover_args="--epub-cover-image=$cover_file"
fi

pandoc \
    --split-level 1 \
    --toc --toc-depth 1 \
    --css "$script_dir/style.css" \
    $cover_args \
    -o "$file_base.epub" \
    $build_files

### CONVERT TO AZW3 AND BACK ###

ebook_convert=""
if command -v ebook-convert >/dev/null 2>&1; then
    ebook_convert="ebook-convert"
elif [ -x /Applications/calibre.app/Contents/MacOS/ebook-convert ]; then
    ebook_convert="/Applications/calibre.app/Contents/MacOS/ebook-convert"
fi

if [ -n "$ebook_convert" ]; then
    echo Converting to azw3 and back
    "$ebook_convert" "$file_base.epub" "$file_base.azw3"
    "$ebook_convert" "$file_base.azw3" "$file_base.converted.epub"
    rm -f "$file_base.azw3"
else
    echo Skipping convertion to azw3 and back because ebook-convert command not found
fi
