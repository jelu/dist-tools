#!/bin/bash

if [ -z "$debdir" ]; then
    debdir="$HOME/deb"
fi
if [ -z "$debdirs" ]; then
    debdirs="$debdir"
fi
if [ -z "$localdir" ]; then
    localdir="$HOME/pbuilder/local"
fi

test -f "$HOME/autobuild.pid" && exit 0
echo $$ >"$HOME/autobuild.pid" 2>/dev/null || exit 0

for debdir in $debdirs; do
    mkdir -p "$debdir/result" "$HOME/build" "$localdir"

    find "$debdir" -type f -name '*_source.changes' | while read file; do
        test -f "$file" || continue
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

            cat >~/pbuilder/hooks/D05local <<EOF
#!/bin/sh -e
echo "deb [trusted=yes] file:$localdir/$dist ./" | tee /etc/apt/sources.list.d/local.list
apt-get update -o Dir::Etc::sourcelist="sources.list.d/local.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
EOF
            chmod +x ~/pbuilder/hooks/D05local
            mkdir -p "$localdir/$dist"

            ( cd "$localdir/$dist" && apt-ftparchive packages . >Packages ) &&
            cp -v "$debdir/$name"* "$HOME/build/" &&
            ( cd "$HOME/build" && "$HOME/dist-tools/cowbuilder-dist" "${name}_source.changes" ) &&
            mkdir -p "$debdir/result/$pkg-$vers" &&
            cp -nv "$HOME/pbuilder/"*"_result/"* "$debdir/result/$pkg-$vers/" &&
            touch "$file.built" &&
            touch "$debdir/result/$pkg-$vers.$dist.done" ||
            touch "$file.build-err"

            ls -1 "$HOME/pbuilder/"*"_result/"*.deb 2>/dev/null | sed 's%.*/%%'| sed 's%_.*%%'| sort | uniq | while read deb; do
                rm -vf "$localdir/$dist/${deb}_"*
            done
            cp -nv "$HOME/pbuilder/"*"_result/"*.deb "$localdir/$dist"
        ) >"$debdir/$name.log" 2>&1
    done
done

rm -f "$HOME/autobuild.pid"
