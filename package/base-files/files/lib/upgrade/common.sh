# shellcheck disable=SC3043,SC3057,SC3060,SC3003
RAM_ROOT=/tmp/root

export BACKUP_FILE=sysupgrade.tgz	# file extracted by preinit

[ -x /usr/bin/ldd ] || ldd() { LD_TRACE_LOADED_OBJECTS=1 "$@"; }
libs() { ldd "$@" 2>/dev/null | sed 's#^[[:space:]]\(.* => \)\{0,1\}\(/.*\) ([^()]*)$#\2#p;d'; }

install_file() { # <file> [ <file> ... ]
	local file target dest dir
	for file in "$@"; do
		if [ -L "$file" ]; then
			target="$(readlink -f "$file")"
			dest="$RAM_ROOT/$file"
			[ -f "$dest" ] || {
				dir="$(dirname "$dest")"
				mkdir -p "$dir"
				ln -s "$target" "$dest"
			}
			file="$target"
		fi
		dest="$RAM_ROOT/$file"
		[ -f "$file" ] && [ ! -f "$dest" ] && {
			dir="$(dirname "$dest")"
			mkdir -p "$dir"
			cp "$file" "$dest"
		}
	done
}

install_bin() {
	local src="$1" file
	install_file "$src"
	if [ -x "$src" ]; then
		libs "$src" | while read -r file; do
			install_file "$file"
		done
	fi
}

run_hooks() {
	local arg="$1"; shift
	for func in "$@"; do
		eval "$func $arg"
	done
}

ask_bool() {
	local default="$1"; shift;
	local answer="$default"

	[ "$INTERACTIVE" -eq 1 ] && {
		case "$default" in
			0) printf "%s (y/N): " "$*";;
			*) printf "%s (Y/n): " "$*";;
		esac
		read -r answer
		case "$answer" in
			Y* | y*) answer=1;;
			N* | n*) answer=0;;
			*) answer="$default";;
		esac
	}
	[ "$answer" -gt 0 ]
}

_v() {
	[ -n "$VERBOSE" ] && [ "$VERBOSE" -ge 1 ] && echo "$*" >&2
}

v() {
	_v "$(date) upgrade: $*"
	logger -p info -t upgrade "$@"
}

json_string() {
	local v="$1"
	v="${v//\\/\\\\}"
	v="${v//\"/\\\"}"
	echo "\"$v\""
}

rootfs_type() {
	/bin/mount | awk '($3 ~ /^\/$/) && ($5 !~ /rootfs/) { print $5 }'
}

get_image() { # <source> [ <command> ]
	local from="$1"
	local cmd="$2"

	if [ -z "$cmd" ]; then
		case "$(hexdump -n 2 -e '1/1 "%02x"' "$from")" in
			1f8b) cmd="busybox zcat";;
			*) cmd="cat";;
		esac
	fi

	$cmd <"$from"
}

get_image_dd() {
	local from="$1"; shift

	(
		exec 3>&2
		( exec 3>&2; get_image "$from" 2>&1 1>&3 | grep -v -F ' Broken pipe'     ) 2>&1 1>&3 |
			( exec 3>&2; dd "$@" 2>&1 1>&3 | grep -v -E ' records (in|out)') 2>&1 1>&3
		exec 3>&-
	)
}

get_magic_word() {
	(get_image "$@" | hexdump -v -n 2 -e '1/1 "%02x"')
}

get_magic_long() {
	(get_image "$@" | hexdump -v -n 4 -e '1/1 "%02x"')
}

get_magic_gpt() {
	(get_image "$@" | dd bs=8 count=1 skip=64) 2>/dev/null
}

get_magic_vfat() {
	(get_image "$@" | dd bs=3 count=1 skip=18) 2>/dev/null
}

get_magic_fat32() {
	(get_image "$@" | dd bs=1 count=5 skip=82) 2>/dev/null
}

identify_magic_long() {
	local magic=$1
	case "$magic" in
		"55424923")
			echo "ubi"
			;;
		"31181006")
			echo "ubifs"
			;;
		"68737173")
			echo "squashfs"
			;;
		"d00dfeed")
			echo "fit"
			;;
		"4349"*)
			echo "combined"
			;;
		"1f8b"*)
			echo "gzip"
			;;
		*)
			echo "unknown $magic"
			;;
	esac
}

part_magic_efi() {
	[ "$(get_magic_gpt "$@")" = "EFI PART" ]
}

part_magic_fat() {
	[ "$(get_magic_vfat "$@")" = FAT ] || [ "$(get_magic_fat32 "$@")" = FAT32 ]
}

export_bootdevice() {
	local uuid blockdev uevent line class
	local MAJOR MINOR DEVNAME
	local rootpart="$(cmdline_get_var root)"

	case "$rootpart" in
		PARTUUID=[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]-[a-f0-9][a-f0-9])
			uuid="${rootpart#PARTUUID=}"
			uuid="${uuid%-[a-f0-9][a-f0-9]}"
			for blockdev in $(find /dev -type b); do
				set -- $(hexdump -v -s 440 -n 4 -e '4/1 "%02x "' "$blockdev")
				if [ "$4$3$2$1" = "$uuid" ]; then
					uevent="/sys/class/block/${blockdev##*/}/uevent"
					break
				fi
			done
		;;
		PARTUUID=????????-????-????-????-??????????0?/PARTNROFF=1 | \
		PARTUUID=????????-????-????-????-??????????02)
			uuid="${rootpart#PARTUUID=}"
			uuid="${uuid%/PARTNROFF=1}"
			uuid="${uuid%0?}00"
			for disk in $(find /dev -type b); do
				set -- $(hexdump -v -s 568 -n 16 -e '8/1 "%02x "" "2/1 "%02x""-"6/1 "%02x"' "$disk")
				if [ "$4$3$2$1-$6$5-$8$7-$9" = "$uuid" ]; then
					uevent="/sys/class/block/${disk##*/}/uevent"
					break
				fi
			done
		;;
		/dev/*)
			uevent="/sys/class/block/${rootpart##*/}/../uevent"
		;;
		0x[a-f0-9][a-f0-9][a-f0-9] | 0x[a-f0-9][a-f0-9][a-f0-9][a-f0-9] | \
		[a-f0-9][a-f0-9][a-f0-9] | [a-f0-9][a-f0-9][a-f0-9][a-f0-9])
			rootpart="0x${rootpart#0x}"
			for class in /sys/class/block/*; do
				while read -r line; do
					export -n "$line"
				done < "$class/uevent"
				if [ $((rootpart/256)) = "$MAJOR" ] && [ $((rootpart%256)) = "$MINOR" ]; then
					uevent="$class/../uevent"
				fi
			done
		;;
	esac

	if [ -e "$uevent" ]; then
		while read -r line; do
			export -n "$line"
		done < "$uevent"
		export "BOOTDEV_MAJOR=$MAJOR"
		export "BOOTDEV_MINOR=$MINOR"
		return 0
	fi

	return 1
}

export_partdevice() {
	local var="$1" offset="$2"
	local uevent line MAJOR MINOR DEVNAME

	for uevent in /sys/class/block/*/uevent; do
		while read -r line; do
			export -n "$line"
		done < "$uevent"
		if [ "$BOOTDEV_MAJOR" = "$MAJOR" ] && [ "$((BOOTDEV_MINOR + offset))" = "$MINOR" ] && [ -b "/dev/$DEVNAME" ]; then
			export "$var=$DEVNAME"
			return 0
		fi
	done

	return 1
}

get_partitions() { # <device> <filename>
	local disk="$1"
	local filename="$2"

	if [ -b "$disk" ] || [ -f "$disk" ]; then
		v "Reading partition table from $filename..."

		[ "$(hexdump -v -s 510 -n 2 -e '1/1 "%02x"' "$disk")" = 55aa ] || {
			v "Invalid partition table on $disk"
			exit
		}

		rm -f "/tmp/partmap.$filename"

		local part
		if part_magic_efi "$disk"; then
			#export_partdevice will fail when partition number is greater than 15, as
			#the partition major device number is not equal to the disk major device number
			for part in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
				set -- $(hexdump -v -n 48 -s "$((0x380 + part * 0x80))" -e '4/4 "%08x"" "4/4 "%08x"" "16/1 " %02x"' "$disk")

				local type="$1"
				local lba="$(( 0x${10}$9$8$7$6$5$4$3 ))"
				local end="$(( 0x${18}${17}${16}${15}${14}${13}${12}${11} ))"
				local num="$(( end - lba + 1 ))"

				[ "$type" = 00000000000000000000000000000000 ] || printf "%2d %5d %7d\n" "$part" "$lba" "$num" >> "/tmp/partmap.$filename"
			done
		else
			for part in 1 2 3 4; do
				set -- $(hexdump -v -n 12 -s "$((0x1B2 + part * 16))" -e '12/1 "%02x "' "$disk")

				local type="$(( 0x$1 ))"
				local lba="$(( 0x$8$7$6$5 ))"
				local num="$(( 0x${12}${11}${10}$9 ))"

				[ $type -gt 0 ] || continue

				printf "%2d %5d %7d\n" "$part" "$lba" "$num" >> "/tmp/partmap.$filename"
			done
		fi
	fi
}

indicate_upgrade() {
	. /etc/diag.sh
	set_state upgrade
}

# Flash firmware to MTD partition
#
# $(1): path to image
# $(2): (optional) pipe command to extract firmware, e.g. dd bs=n skip=m
default_do_upgrade() {
	sync
	echo 3 > /proc/sys/vm/drop_caches
	if [ -n "$UPGRADE_BACKUP" ]; then
		get_image "$1" "$2" | mtd $MTD_ARGS $MTD_CONFIG_ARGS -j "$UPGRADE_BACKUP" write - "${PART_NAME:-image}"
	else
		get_image "$1" "$2" | mtd $MTD_ARGS write - "${PART_NAME:-image}"
	fi || exit 1
	false
}
