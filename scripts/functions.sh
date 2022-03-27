#!/bin/sh

get_magic_word() {
	hexdump -v -n 4 -e '4/1 "%02x" "\n"' "$1"
}

get_post_padding_word() {
	local rootfs_length="$(stat -c%s "$1")"
	# the JFFS2 end marker must be on a 4K boundary (often 64K or 256K)
	[ $((rootfs_length%4096)) -eq 4 ] || return

	# skip rootfs data except the potential EOF marker
	hexdump -v -s "$((rootfs_length - 4))" -n 4 -e '4/1 "%02x" "\n"' "$1"
}

get_fs_type() {
	case "$(get_magic_word "$1")" in
	3118*) echo ubifs ;;
	68737173)
		if [ "$(get_post_padding_word "$1")" = deadc0de ]; then
			echo squashfs-jffs2
		else
			echo squashfs
		fi
		;;
	*) echo unknown ;;
	esac
}

round_up() {
	echo "$(((($1 + ($2 - 1))/ $2) * $2))"
}
