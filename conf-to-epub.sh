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

pandoc \
    --split-level 1 \
    --toc --toc-depth 1 \
    -o "$dir/general-conference-$year-$month-$language.epub" \
    $build_files
