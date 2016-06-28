#!/bin/bash

test -f "$HOME/autobuild.pid" && exit 0
echo $$ >"$HOME/autobuild.pid" 2>/dev/null || exit 0

mkdir -p "$HOME/deb" "$HOME/build"

find "$HOME/deb" -type f -name '*_source.changes' |
  while read file; do
    test -f "$file.built" && continue
    test -f "$file.build-err" && continue
    name=`echo "$file" | sed 's%.*/%%' | sed 's%_source.changes$%%'`
    orig=`echo "$name" | sed 's%-[0-9]*~[a-z]*+[0-9]*$%%'`
    pkg=`echo "$orig" | sed 's%_.*%%'`
    vers=`echo "$orig" | sed 's%.*_%%'`
    (
      cp -v "$HOME/deb/$orig.orig."* "$HOME/build"
      cp -v "$HOME/deb/$name"* "$HOME/build" &&
      ( cd "$HOME/build" && "$HOME/dist-tools/cowbuilder-dist" "${name}_source.changes" ) &&
      mkdir -p "$HOME/deb/result" &&
      cp -nv "$HOME/pbuilder/"*"_result/$name"* \
        "$HOME/deb/result/" &&
      touch "$file.built" ||
      touch "$file.build-err"
      cp -nv "$HOME/pbuilder/"*"_result/$pkg-dbgsym_$vers-"* \
        "$HOME/deb/result/"
    ) >"$HOME/deb/$name.log" 2>&1
  done

rm -f "$HOME/autobuild.pid"
