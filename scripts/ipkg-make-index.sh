#!/bin/sh
set -e

if [ -z "$1" ] || ! cd "$1" 2>/dev/null; then
	echo "Usage: ipkg-make-index <package_directory>" >&2
	exit 1
fi

find . -name '*.ipk' | sort | {
	empty=1
	while read -r pkg; do
		case "${pkg##*/}" in kernel_* | libc_*) continue ;; esac
		empty=
		echo "Generating index for package $pkg" >&2
		file_size=$(stat -L -c%s "$pkg")
		sha256sum=$($MKHASH sha256 "$pkg")
		sed_safe_pkg="$(printf '%s\n' "${pkg#./}" | sed 's@/@\\/@g')"
		tar -xzOf "$pkg" ./control.tar.gz | tar -xzOf - ./control | sed -e "s/^Description:/Filename: $sed_safe_pkg\\
Size: $file_size\\
SHA256sum: $sha256sum\\
Description:/"
		echo
	done
	[ -z "$empty" ] || echo
}
