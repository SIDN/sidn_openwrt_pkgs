#!/usr/bin/python

#
# 'Automatic' NTA management;
#
# Use in conjunction with a DNS resolver that returns the server
# address of this server when encountering a DNSSEC failure.
#
# If this server gets an http request for a domain name it doesn't
# know, it assumes that this was because of a DNSSEC failure.
# In that case, it will ask whether to set an NTA for that domain name.
#
# If the request is for an IP address or one of the known names,
# it will redirect to that.

import socket
import subprocess
import time
import web
import os
import logging
from logging import handlers

DEFAULT_REDIRECT_SUFFIX = "/"

UNBOUND_CONTROL = "/usr/sbin/unbound-control"

# Note that these should be fqdn's including the root dot
SELF_HOST = "valibox."
# queries wihtout host are always redirected
# otherwise this list is checked,
KNOWN_HOSTS = [
  SELF_HOST
]

urls = [
 '/autonta/set_nta/([a-zA-Z0-9.-]+)', 'SetNTA',
 '/autonta/remove_nta/([a-zA-Z0-9.-]+)', 'RemoveNTA',
 '/autonta/ask_nta/([a-zA-Z0-9.-]+)', 'AskNTA',
 '/autonta', 'NTA',
 '/', 'NTA',
]
render = web.template.render('templates/', base='base')

logging.basicConfig()
logger = logging.getLogger('autonta')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler()
logger.addHandler(handler)

def store_pid():
    pid = os.getpid()
    with open("/var/autonta.pid", 'w') as output:
        output.write("%d\n" % pid)

def split_host(host):
    parts = host.split(':')
    if len(parts) > 1:
        return parts[0], parts[1]
    else:
        return host, None

def run_cmd(arguments):
    proc = subprocess.Popen([UNBOUND_CONTROL] + arguments,
                            stdout = subprocess.PIPE,
                            stderr = subprocess.PIPE)
    stdout, _ = proc.communicate()
    return stdout.split("\n")[:-1]

def is_valid_ipv4_address(address):
    try:
        socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            socket.inet_aton(address)
        except socket.error:
            logger.debug("%s is not an IPv4 address" % address)
            return False
        return address.count('.') == 3
    except socket.error:  # not a valid address
        logger.debug("%s is not an IPv4 address" % address)
        return False

    logger.debug("%s is an IPv4 address" % address)
    return True

def is_valid_ipv6_address(address):
    try:
        socket.inet_pton(socket.AF_INET6, address)
    except socket.error:  # not a valid address
        logger.debug("%s is not an IPv6 address" % address)
        return False
    logger.debug("%s is an IPv6 address" % address)
    return True

def is_valid_ip_address(address):
    return is_valid_ipv4_address(address) or is_valid_ipv6_address(address)

def is_known_host(host):
    if not host.endswith('.'):
        host = host + '.'
    for known_host in KNOWN_HOSTS:
        logger.debug("Try for known host: %s" % known_host)
        if host.endswith(known_host):
            logger.debug("%s is a known host" % host)
            return True
    logger.debug("%s is not a known host" % host)
    return False

def add_nta(host):
    logger.info("Adding %s to NTA List" % host)
    run_cmd(["insecure_add", host])

def remove_nta(host):
    logger.info("Removing %s from NTA List" % host)
    run_cmd(["insecure_remove", host])

def get_ntas():
    return run_cmd(["list_insecure"])

class SetNTA:
    def GET(self, host):
        logger.debug("SetNTA called")
        # TODO: full URI.
        add_nta(host)
        return render.nta_set(host)

class RemoveNTA:
    def GET(self, host):
        logger.debug("RemoveNTA called")
        remove_nta(host)
        raise web.seeother("/")

class AskNTA:
    def GET(self, host):
        logger.debug("AskNTA called")
        # make a list of domains to possibly set an NTA for
        if host.endswith('.'):
            host = host[:-1]
        domains = []
        labels = host.split('.')
        lc = len(labels)
        for i in range(lc-1):
            domains.append(".".join(labels[i:lc]))
            
        
        return render.ask_nta(host, domains)

class NTA:
    def GET(self):
        logger.debug("Base NTA called")
        host = web.ctx.env.get('HTTP_HOST')
        (host, port) = split_host(host)
        logger.debug("Host: %s" % (host))
        if port is not None:
            logger.debug("Port: %d" % (port))
        if is_valid_ip_address(host) or is_known_host(host):
            # show NTA list?
            ntas = get_ntas()
            return render.nta_list(ntas)
        else:
            if host + "." in get_ntas():
                return render.nta_set(host)
            if port is not None:
                redirect = "http://%s:%s/autonta/ask_nta/%s" % (SELF_HOST, port, host)
            else:
                redirect = "http://%s/autonta/ask_nta/%s" % (SELF_HOST, host)
            logger.debug("Redirecting to %s" % redirect)
            raise web.seeother(redirect)

if __name__ == "__main__":
    store_pid()
    app = web.application(urls, globals())
    app.run()
