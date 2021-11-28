#!/bin/sh

awk -f - $* <<EOF
function bitcount(c) {
	c=and(rshift(c, 1),0x55555555)+and(c,0x55555555)
	c=and(rshift(c, 2),0x33333333)+and(c,0x33333333)
	c=and(rshift(c, 4),0x0f0f0f0f)+and(c,0x0f0f0f0f)
	c=and(rshift(c, 8),0x00ff00ff)+and(c,0x00ff00ff)
	c=and(rshift(c,16),0x0000ffff)+and(c,0x0000ffff)
	return c
}

function ip2int(ip,    ret,n,a,x) {
	ret=0
	n=split(ip,a,".")
	for (x=1;x<=n;x++) ret=or(lshift(ret,8),a[x])
	return ret
}

function int2ip(ip,    ret,x) {
	for(ret=and(ip,255);x<3;x++)ret=and(255,ip=rshift(ip,8))"."ret
	return ret
}

function compl32(v) {
	return xor(v, 0xffffffff)
}

BEGIN {
	slpos=index(ARGV[1],"/")
	IND=1
	if (slpos == 0) {
		ipaddr=ip2int(ARGV[IND++])
		mask=ARGV[IND++]
		dotpos=index(mask,".")
		if (dotpos == 0)
			netmask=compl32(2**(32-int(mask))-1)
		else
			netmask=ip2int(mask)
	} else {
		ipaddr=ip2int(substr(ARGV[IND],1,slpos-1))
		netmask=compl32(2**(32-int(substr(ARGV[IND],slpos+1)))-1)
		IND++
	}

	network=and(ipaddr,netmask)
	broadcast=or(network,compl32(netmask))

	start=or(network,and(ip2int(ARGV[IND]),compl32(netmask)))
	limit=network+1
	if (start<limit) start=limit

	limit=or(network,compl32(netmask))-1
	count=int(ARGV[IND+1])
	if (count) {
		end = start+count
		if (end>limit) end=limit
	} else {
		end=limit
	}

	print "IP="int2ip(ipaddr)
	print "NETMASK="int2ip(netmask)
	print "BROADCAST="int2ip(broadcast)
	print "NETWORK="int2ip(network)
	print "PREFIX="32-bitcount(compl32(netmask))

	# range calculations:
	# ipcalc <ip> <netmask> [<start> [<num>]]
	# ipcalc <ip>/<prefixlen> [<start> [<num>]]

	if (ARGC > IND) {
		print "START="int2ip(start)
		print "END="int2ip(end)
	}
}
EOF
