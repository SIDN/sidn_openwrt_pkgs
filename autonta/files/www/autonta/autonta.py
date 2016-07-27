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

import threading
import time

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
 '/autonta/update_check', 'UpdateCheck',
 '/autonta/update_install', 'UpdateInstall'
]
render = web.template.render('templates/', base='base')

logging.basicConfig()
logger = logging.getLogger('autonta')
logger.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler()
logger.addHandler(handler)

def store_pid():
    pid = os.getpid()
    with open("/var/autonta.pid", 'w') as output:
        output.write("%d\n" % pid)

#
# general utility
#
def run_cmd(arguments):
    logger.debug("Run command: " + " ".join(arguments))
    proc = subprocess.Popen(arguments,
                            stdout = subprocess.PIPE,
                            stderr = subprocess.PIPE)
    stdout, _ = proc.communicate()
    return stdout.split("\n")[:-1]

def read_file(filename):
    with open(filename, 'r') as inputfile:
        return inputfile.readlines()

def nocache():
    web.header('Cache-Control', 'no-store, no-cache, must-revalidate')
    web.header('Cache-Control', 'post-check=0, pre-check=0', False)
    web.header('Pragma', 'no-cache')

#
# Code for NTA management
#

def split_host(host):
    parts = host.split(':')
    if len(parts) > 1:
        return parts[0], parts[1]
    else:
        return host, None

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
    run_cmd([UNBOUND_CONTROL, "insecure_add", host])

def remove_nta(host):
    logger.info("Removing %s from NTA List" % host)
    run_cmd([UNBOUND_CONTROL, "insecure_remove", host])

def get_ntas():
    return run_cmd([UNBOUND_CONTROL, "list_insecure"])

class SetNTA:
    def GET(self, host):
        nocache()
        logger.debug("SetNTA called")
        # TODO: full URI.
        add_nta(host)
        return render.nta_set(host)

class RemoveNTA:
    def GET(self, host):
        nocache()
        logger.debug("RemoveNTA called")
        remove_nta(host)
        raise web.seeother("http://valibox./autonta")

class AskNTA:
    def GET(self, host):
        nocache()
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
        nocache()
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

#
# Code for update checks
# (Note: this could be separated into a whole new instance, but
# we do not want to run even more python instances)
#
UPDATE_CHECK_BASE='https://valibox.sidnlabs.nl/download/valibox/'
UPDATE_CHECK_BETA_BASE='https://valibox.sidnlabs.nl/download/valibox/beta'
WGET='/usr/bin/wget'

# The information file about updates should be at
# UPDATE_CHECK_BASE/versions.txt
# It should be of the following form:
# boardname current_version download_file info_file sha256sum
# Download file and info file are paths relative to UPDATE_CHECK_BASE
#
# Example:
# gl_ar150 0.1.5 gl_ar150/sidn_valibox_0.1.5.bin gl_ar150/0.1.5.info.txt <sha1sum>
# gl_ar150 0.1.5 gl_ar150/sidn_valibox_0.1.5.bin gl_ar150/0.1.5.info.txt <sha1sum>
#
# Note: for now, each board name can only have one version; it signals
# the 'current' version. There is no concept of 'newer/older' versions
# Also note that we should sign these probably :p
class FirmwareVersionInfo:
    def __init__(self):
        # Store as 'board'->(version, sha1sum ,firmware_url,update_url)
        self.versions = {}
    
    def fetch_version_info(self):
        # Retrieve it with curl?
        # Retrieve it through a call to wget; this python version
        # has some SSL issues
        # There is also very little checking on data for now
        try:
            tmpfile = "/tmp/versions.txt"
            for line in fetch_file(UPDATE_CHECK_BASE + "versions.txt", tmpfile):
                parts = line.strip().split(' ')
                self.versions[parts[0]] = parts[1:]
            return True
        except Exception as exc:
            logger.debug("Error in fetch: " + str(exc))
            #raise exc
            return False

    def get_version_for(self, board):
        if board in self.versions:
            return self.versions[board][0]

    def get_firmware_url_for(self, board):
        if board in self.versions:
            return UPDATE_CHECK_BASE + self.versions[board][1]

    def get_info_url_for(self, board):
        if board in self.versions:
            return UPDATE_CHECK_BASE + self.versions[board][2]

    def get_sha256sum_for(self, board):
        if board in self.versions:
            return self.versions[board][3]

def fetch_file(url, output_file, return_data=True):
    # If return_data is true, return the contents of the file
    # Otherwise, simply return True/False
    logger.debug("Fetch file from: " + url)
    logger.debug("Store in " + output_file)
    run_cmd([WGET,"-O", output_file, url])
    if os.path.exists(output_file):
        logger.debug("Success!")
        if return_data:
            return read_file(output_file)
        else:
            return True
    else:
        logger.debug("Failure. file not downloaded")
        # perhaps none?
        if return_data:
            return []
        else:
            return False
    
def get_board_name():
    """
    Read the board name of this device
    """
    lines = read_file("/tmp/sysinfo/board_name")
    if len(lines) > 0:
        return lines[0].strip()
    else:
        return None

def get_current_version():
    """
    Read the current version
    """
    lines = read_file("/etc/valibox.version")
    if len(lines) > 0:
        return lines[0].strip()
    else:
        return None

class UpdateCheck:
    def GET(self):
        nocache()
        logger.debug("UpdateCheck called")
        current_version = get_current_version()
        board_name = get_board_name()
        fvi = FirmwareVersionInfo()

        if not fvi.fetch_version_info():
            return render.update_check(True, False, current_version, None, None)
        update_version = fvi.get_version_for(board_name)
        if update_version is None or update_version == current_version:
            return render.update_check(False, False, current_version, None, None)
        else:
            # there is a new version
            # Fetch info
            lines = fetch_file(fvi.get_info_url_for(board_name), "/tmp/update_info.txt")
            info = "\n".join(lines)
            return render.update_check(False, True, current_version, update_version, info)
        return render.nta_set(host)

def install_update():
    # sleep a little while so the page can still render
    time.sleep(2)
    run_cmd(["/sbin/sysupgrade", "-n", "/tmp/firmware_update.bin"])

def check_sha256sum(filename, expected_sum):
    output = run_cmd(["/usr/bin/sha256sum", filename])
    expected_sum += "  " + filename
    if len(output) > 0:
        filesum = output[0].strip()
        logger.debug("sha256sum of file: " + filesum)
        logger.debug("Expected: " + expected_sum)
        return filesum == expected_sum
    logger.debug("sha256sum command failed")
    return False

class UpdateInstall:
    def GET(self):
        nocache()
        logger.debug("UpdateInstall called")
        current_version = get_current_version()
        board_name = get_board_name()
        # Note, we download it again (just in case it was an old link)
        fvi = FirmwareVersionInfo()

        if not fvi.fetch_version_info():
            return render.update_check(True, False, current_version, None, None)
        update_version = fvi.get_version_for(board_name)
        if update_version is None:# or update_version == current_version:
            return render.update_check(False, False, current_version, None, None)
        else:
            # there is a new version
            # Fetch info
            success = fetch_file(fvi.get_firmware_url_for(board_name), "/tmp/firmware_update.bin", False)
            if success and check_sha256sum("/tmp/firmware_update.bin", fvi.get_sha256sum_for(board_name)):
                threading.Thread(target=install_update).start()
                return render.update_install(True, update_version)
            else:
                return render.update_install(False, update_version)
        return render.nta_set(host)

if __name__ == "__main__":
    store_pid()
    app = web.application(urls, globals())
    app.run()
