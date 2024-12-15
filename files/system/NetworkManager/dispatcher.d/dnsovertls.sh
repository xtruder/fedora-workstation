#!/usr/bin/env bash

COMMAND="$2"
DEVICE="$1"

# dns server to set
DNS="1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com"

if [[ "${COMMAND}" == "up" && ( "${DEVICE}" == wlp* || "${DEVICE}" == wifi* ) ]]; then
	# temporary set dnsovertls to oppurtunistic mode until we are actually connected
	until curl -sfI -m 5 https://1.1.1.1 -o /dev/null; do echo waiting for connection; done

	# enable dnsovertls and flush cache
	if [[ $(nmcli -g "ipv4.ignore-auto-dns" connection show "${CONNECTION_ID}") == "no" ]]; then
		resolvectl dns "${DEVICE}" "${DNS}"
		resolvectl dnsovertls "${DEVICE}" yes
		resolvectl flush-caches
	fi
fi

if [[ "${COMMAND}" == "down" && ( "${DEVICE}" == wlp* || "${DEVICE}" == wifi* ) ]]; then
	# revert any per device settings when going down
	resolvectl revert "${DEVICE}"
fi
