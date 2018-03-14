#!/bin/bash

test -f "$HOME/autobuild.pid" && exit 0
echo $$ >"$HOME/autobuild.pid" 2>/dev/null || exit 0

mkdir -p "$HOME/deb/result" "$HOME/build"

find "$HOME/deb" -type f -name '*_source.changes' |
  while read file; do
    test -f "$file.built" && continue
    test -f "$file.build-err" && continue
    name=`echo "$file" | sed 's%.*/%%' | sed 's%_source.changes$%%'`
    dist=`echo "$file" | sed 's%.*~%%' | sed 's%+.*%%'`
    orig=`echo "$name" | sed 's%-[0-9]*~[a-z]*+[0-9]*$%%'`
    pkg=`echo "$orig" | sed 's%_.*%%'`
    vers=`echo "$orig" | sed 's%.*_%%'`
    (
      rm -vf "$HOME/build/"*
      rm -vf "$HOME/pbuilder/"*"_result/"*
      cp -v "$HOME/deb/$orig.orig."* "$HOME/build/"
      cp -v "$HOME/deb/$name"* "$HOME/build/" &&
      ( cd "$HOME/build" && "$HOME/dist-tools/cowbuilder-dist" "${name}_source.changes" ) &&
      mkdir -p "$HOME/deb/result/$name-$vers" &&
      cp -nv "$HOME/pbuilder/"*"_result/"* \
        "$HOME/deb/result/$name-$vers/" &&
      touch "$file.built" ||
      touch "$file.build-err"
      cp -nv "$HOME/pbuilder/${dist}_result/"*.deb \
        "$HOME/pbuilder/local/$dist" &&
      ( cd "$HOME/pbuilder/local/$dist" && apt-ftparchive packages . >Packages )
    ) >"$HOME/deb/$name.log" 2>&1
  done

rm -f "$HOME/autobuild.pid"
