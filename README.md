# MTProxy-alpine

Telegram Messenger MTProto zero-configuration proxy server.

The Telegram Messenger MTProto proxy is a zero-configuration container
that automatically sets up a proxy server that speaks Telegram's native MTProto.

## Quick reference

To start the proxy all you need to do is:

`docker run -d -p443:443 --name=mtproto-proxy --restart=always abogatikov/mtproxy:latest`

The container's log output (`docker logs mtproto-proxy`) will contain the links to paste into the Telegram app:

`####
 #### Telegram Proxy
 ####

 [+] No secret passed. Will generate 1 random ones.
 [+] Using the detected external IP: 1.2.3.4.
 [+] Using the detected internal IP: 4.3.2.1.
 [*] Final configuration:
 [*]   Secret 1: 91eeab7366ad6a9e60358c45aa3ad989
 [*]   tg:// link for secret 1 auto configuration: tg://proxy?server=1.2.3.4&port=445&secret=91eeab7366ad6a9e60358c45aa3ad989
 [*]   t.me link for secret 1: https://t.me/proxy?server=1.2.3.4&port=443&secret=91eeab7366ad6a9e60358c45aa3ad989
 [*]   Tag: no tag
 [*]   External IP: 1.2.3.4
 [*]   Make sure to fix the links in case you run the proxy on a different port.
`

The secret will persist across container upgrades in a volume.
It is a mandatory configuration parameter: if not provided, it will be generated automatically at container start.
You may change container's port:

`docker run -d -p445:445 -e HTTP_PORT=445 --name=mtproto-proxy --restart=always -v proxy-config:/data abogatikov/mtproxy:latest`

Please note that the proxy gets the Telegram core IP addresses at the start of the container.
We try to keep the changes to a minimum, but you should restart the container about once a day, just in case.

## Custom configuration

If you need to specify a custom secret (say, if you are deploying multiple proxies with DNS load-balancing), you may pass the SECRET environment variable as 16 bytes in lower-case hexidecimals.:

`docker run -d -p443:443 -v proxy-config:/data -e SECRET=00baadf00d15abad1deaa51sbaadcafe abogatikov/mtproxy:latest`

The proxy may be configured to accept up to 16 different secrets.
You may specify them explicitly as comma-separated hex strings in the
`SECRET` environment variable, or you may let the container generate
the secrets automatically using the `SECRET_COUNT` variable to limit
the number of generated secrets.

`docker run -d -p443:443 -v proxy-config:/data -e SECRET=935ddceb2f6bbbb78363b224099f75c8,2084c7e58d8213296a3206da70356c81 abogatikov/mtproxy:latest`
`docker run -d -p443:443 -v proxy-config:/data -e SECRET_COUNT=4 abogatikov/mtproxy:latest`

A custom advertisement tag may be provided using the TAG environment variable:
`docker run -d -p443:443 -v proxy-config:/data -e TAG=3f40462915a3e6026a4d790127b95ded abogatikov/mtproxy:latest.`
Please note that the tag is not persistent: you'll have to provide it as an environment variable every time you run an MTProto proxy container.

A single worker process is expected to handle tens of thousands of clients on a modern CPU.
For best performance we artificially limit the proxy to 60000 connections per core and run two workers by default.
If you have many clients, be sure to adjust the WORKERS variable:

`docker run -d -p443:443 -v proxy-config:/data -e WORKERS=16 abogatikov/mtproxy:latest`

## Monitoring

The MTProto proxy server exports internal statistics as tab-separated
values over the http://localhost:2398/stats endpoint. Please note that
this endpoint is available only from localhost: depending on your
configuration, you may need to collect the statistics with docker
exec mtproto-proxy curl http://localhost:2398/stats.

- `ready_targets`: number of Telegram core servers the proxy will try to connect to.
- `active_targets`: number of Telegram core servers the proxy is actually connected to.
  Should be equal to ready_targets.
- `total_special_connections`: number of inbound client connections
- `total_max_special_connections`: the upper limit on inbound connections.
  Is equal to 60000 multiplied by worker count.