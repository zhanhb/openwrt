#!/bin/sh

awk -f - -- "$@" <<EOF
function bitcount(c) {
	c = and(rshift(c, 1), 0x55555555) + and(c, 0x55555555)
	c = and(rshift(c, 2), 0x33333333) + and(c, 0x33333333)
	c = and(rshift(c, 4) + c, 0x0f0f0f0f)
	c = rshift(c, 8) + c
	return and(rshift(c, 16) + c, 0x3f)
}

function ip2int(ip,    ret, n, a, x) {
	ret = 0
	n = split(ip, a, ".")
	for (x = 1; x <= n; x++) ret = or(lshift(ret, 8), a[x])
	return ret
}

function int2ip(ip,    ret, x) {
	for (ret = and(ip, 255); x < 3; x++) ret = and(255, ip = rshift(ip, 8)) "." ret
	return ret
}

function compl32(v) {
	return xor(v, 0xffffffff)
}

BEGIN {
	slpos = index(ARGV[1], "/")
	if (slpos == 0) {
		ipaddr = ip2int(ARGV[1])
		dotpos = index(ARGV[2], ".")
		if (dotpos == 0)
			netmask = compl32(2 ^ (32 - int(ARGV[2])) - 1)
		else
			netmask = ip2int(ARGV[2])
	} else {
		ipaddr = ip2int(substr(ARGV[1], 1, slpos - 1))
		netmask = compl32(2 ^ (32 - int(substr(ARGV[1], slpos + 1))) - 1)
		ARGV[4] = ARGV[3]
		ARGV[3] = ARGV[2]
		++ARGC
	}

	network = and(ipaddr, netmask)
	broadcast = or(network, compl32(netmask))

	start = or(network, and(ip2int(ARGV[3]), compl32(netmask)))
	limit = network + 1
	if (start < limit) start = limit

	limit = or(network, compl32(netmask)) - 1
	if (ARGC > 4) {
		end = start + ARGV[4]
		if (end > limit) end = limit
	} else {
		end = limit
	}

	print "IP=" int2ip(ipaddr)
	print "NETMASK=" int2ip(netmask)
	print "BROADCAST=" int2ip(broadcast)
	print "NETWORK=" int2ip(network)
	print "PREFIX=" 32 - bitcount(compl32(netmask))

	# range calculations:
	# ipcalc <ip> <netmask> [<start> [<num>]]
	# ipcalc <ip>/<prefixlen> [<start> [<num>]]

	if (ARGC > 3) {
		print "START=" int2ip(start)
		print "END=" int2ip(end)
	}
}
EOF
