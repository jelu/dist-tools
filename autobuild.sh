#!/bin/bash

if [ -z "$debdir" ]; then
  debdir="$HOME/deb"
fi

test -f "$HOME/autobuild.pid" && exit 0
echo $$ >"$HOME/autobuild.pid" 2>/dev/null || exit 0

mkdir -p "$debdir/result" "$HOME/build"

find "$debdir" -type f -name '*_source.changes' |
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
      cp -v "$debdir/$orig.orig."* "$HOME/build/"
      cp -v "$debdir/$name"* "$HOME/build/" &&
      ( cd "$HOME/build" && "$HOME/dist-tools/cowbuilder-dist" "${name}_source.changes" ) &&
      mkdir -p "$debdir/result/$pkg-$vers" &&
      cp -nv "$HOME/pbuilder/"*"_result/"* \
        "$debdir/result/$pkg-$vers/" &&
      touch "$file.built" ||
      touch "$file.build-err"
      cp -nv "$HOME/pbuilder/${dist}_result/"*.deb \
        "$HOME/pbuilder/local/$dist" &&
      ( cd "$HOME/pbuilder/local/$dist" && apt-ftparchive packages . >Packages )
    ) >"$debdir/$name.log" 2>&1
  done

rm -f "$HOME/autobuild.pid"
