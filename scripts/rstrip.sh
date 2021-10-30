#!/usr/bin/env bash
#
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
SELF="${0##*/}"

[ -n "${STRIP:-}" ] || {
	echo "$SELF: strip command not defined (STRIP variable not set)"
	exit 1
}

[ $# -gt 0 ] || {
	echo "$SELF: no directories / files specified"
	echo "usage: $SELF [PATH...]"
	exit 1
}

find "$@" -type f -exec file {} \; |
	sed -n -e 's/^\(.*\):.*ELF.*\(executable\|relocatable\|shared object\).*,.*/\1:\2/p' |
(
	while IFS=: read -r F S; do
		echo "$SELF: $F: $S"
		if [ "$S" = relocatable ]; then
			[ "${F##*.}" = o ] || $STRIP_KMOD "$F"
		else
			b=$(stat -c %a "$F")
			[ -z "${PATCHELF:-}" ] || [ -z "${TOPDIR:-}" ] || {
				old_rpath="$($PATCHELF --print-rpath "$F")"
				new_rpath=
				oIFS="$IFS"
				IFS=:
				for path in $old_rpath; do
					case "$path" in
					/lib/[^/]* | /usr/lib/[^/]* | \$ORIGIN/* | \$ORIGIN) new_rpath="${new_rpath:+$new_rpath:}$path" ;;
					*) echo "$SELF: $F: removing rpath $path" ;;
					esac
				done
				IFS="$oIFS" # revert IFS, for variable STRIP may have space in it
				[ "$new_rpath" = "$old_rpath" ] || $PATCHELF --set-rpath "$new_rpath" "$F"
			}
			$STRIP "$F"
			a=$(stat -c %a "$F")
			[ "$a" = "$b" ] || chmod "$b" "$F"
		fi
	done
	true
)
