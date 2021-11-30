# Shell script compatibility wrappers for /sbin/uci
#
# Copyright (C) 2008-2010  OpenWrt.org
# Copyright (C) 2008  Felix Fietkau <nbd@nbd.name>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
# shellcheck disable=SC3043

CONFIG_APPEND=
uci_load() {
	local PACKAGE="$1"
	local DATA
	local RET
	local VAR

	_C=0
	if [ -z "$CONFIG_APPEND" ]; then
		for VAR in $CONFIG_LIST_STATE; do
			export ${NO_EXPORT:+-n} "CONFIG_${VAR}="
			export ${NO_EXPORT:+-n} "CONFIG_${VAR}_LENGTH="
		done
		export ${NO_EXPORT:+-n} CONFIG_LIST_STATE=
		export ${NO_EXPORT:+-n} CONFIG_SECTIONS=
		export ${NO_EXPORT:+-n} CONFIG_NUM_SECTIONS=0
		export ${NO_EXPORT:+-n} CONFIG_SECTION=
	fi

	DATA="$(/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} ${LOAD_STATE:+-P /var/state} -S -n export "$PACKAGE" 2>/dev/null)"
	RET="$?"
	[ "$RET" != 0 ] || [ -z "$DATA" ] || eval "$DATA"
	unset DATA

	${CONFIG_SECTION:+config_cb}
	return "$RET"
}

uci_set_default() { # <PACKAGE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} -q show "$1" >/dev/null && return 0
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} import "$1"
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} commit "$1"
}

uci_revert_state() { # <PACKAGE> <CONFIG> <OPTION>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} -P /var/state revert "$1${2:+.$2}${3:+.$3}"
}

uci_set_state() { # <PACKAGE> <CONFIG> <OPTION> <VALUE>
	[ "$#" = 4 ] || return 0
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} -P /var/state set "$1.$2${3:+.$3}=$4"
}

uci_toggle_state() {
	uci_revert_state "$1" "$2" "$3"
	uci_set_state "$1" "$2" "$3" "$4"
}

uci_set() { # <PACKAGE> <CONFIG> <OPTION> <VALUE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} set "$1.$2.$3=$4"
}

uci_add_list() { # <PACKAGE> <CONFIG> <OPTION> <VALUE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add_list "$1.$2.$3=$4"
}

uci_get_state() { # <PACKAGE> <CONFIG> <OPTION> <DEFAULT>
	uci_get "$1" "$2" "$3" "$4" /var/state
}

uci_get() { # <PACKAGE> <CONFIG> <OPTION> <DEFAULT> <STATE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} ${5:+-P $5} -q get "$1${2:+.$2}${3:+.$3}"
	RET="$?"
	[ "$RET" -ne 0 ] && [ -n "$4" ] && echo "$4"
	return "$RET"
}

uci_add() { # <PACKAGE> <TYPE> <CONFIG>
	if [ -z "$3" ]; then
		CONFIG_SECTION="$(/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} add "$1" "$2")"
		export ${NO_EXPORT:+-n} CONFIG_SECTION
	else
		/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} set "$1.$3=$2"
		export ${NO_EXPORT:+-n} CONFIG_SECTION="$3"
	fi
}

uci_rename() { # <PACKAGE> <CONFIG> <OPTION> <VALUE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} rename "$1.$2${4:+.$3}=${4:-$3}"
}

uci_remove() { # <PACKAGE> <CONFIG> <OPTION>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} del "$1.$2${3:+.$3}"
}

uci_remove_list() { # <PACKAGE> <CONFIG> <OPTION> <VALUE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} del_list "$1.$2.$3=$4"
}

uci_revert() { # <PACKAGE> <CONFIG> <OPTION>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} revert "$1${2:+.$2}${3:+.$3}"
}

uci_commit() { # <PACKAGE>
	/sbin/uci ${UCI_CONFIG_DIR:+-c $UCI_CONFIG_DIR} commit $1
}
