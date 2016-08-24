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

import atexit
import logging
from logging import handlers
import os
import random
import re
import shlex
import signal
import string
import socket
import subprocess
import threading
import time
import traceback
import web

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
 '/autonta/nta_list', 'NTAList',
 '/autonta/set_nta/([a-zA-Z0-9.-]+)', 'SetNTA',
 '/autonta/remove_nta/([a-zA-Z0-9.-]+)', 'RemoveNTA',
 '/autonta/ask_nta/([a-zA-Z0-9.-]+)', 'AskNTA',
 '/autonta', 'Index',
 '/', 'NTA',
 '/autonta/update_check', 'UpdateCheck',
 '/autonta/update_install', 'UpdateInstall',
 '/autonta/set_passwords', 'SetPasswords'
]
render = web.template.render('templates/', base='base')
index_render = web.template.render('templates/')

PIDFILE="/var/autonta.pid"
def store_pid():
    pid = os.getpid()
    with open(PIDFILE, 'w') as output:
        output.write("%d\n" % pid)
    logger.debug("Wrote pid %d to %s" % (pid, PIDFILE))

def remove_pidfile():
    try:
        os.unlink(PIDFILE)
        logger.debug("Removed pidfile %s" % PIDFILE)
    except Exception as exc:
        # n/m
        pass

def on_exit(signum, frame):
    remove_pidfile()
    os._exit(0)

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
# Code for DNSSEC error presentation
#
# Errors are of the form:
# validation failure \<<dname> <type> <class>\>: <message> for <type> <dname> while building chain of trust
# Groups:
# 1: target domain name
# 2: error message
# 3: auth server
# 4: failing type
# 5: failing domain name
class DNSSECFailData:
    valfail_regex = "validation failure <([a-zA-Z.-]+) [A-Z]+ [A-Z]+>: (.*) from (.*) for (.*) (.*) while building chain of trust"
    matcher = re.compile(valfail_regex)

    def __init__(self, inputline):
        self.m = DNSSECFailData.matcher.match(inputline)
        if self.m is not None:
            self.parse()

    def matched(self):
        return self.m is not None

    def parse(self):
        self.target_dname = self.m.group(1)
        self.err_msg = self.m.group(2)
        self.auth_server = self.m.group(3)
        self.fail_type = self.m.group(4)
        self.fail_dname = self.m.group(5)

    def as_message_list(self):
        return [
          "Validation failed for %s" % self.target_dname,
          "Because the server at %s returned a bad answer" % self.auth_server,
          "Error: %s" % self.err_msg,
          "For the %s record of %s" % (self.fail_type, self.fail_dname),
        ]

    def as_html(self):
        return \
          "<p>Validation failed for <b>%s</b></p>\n" % self.target_dname +\
          "<p>Because the server at <b>%s</b> returned a bad answer</p>\n" % self.auth_server +\
          "<p style=\"color:red\">Error: %s</p>\n" % self.err_msg +\
          "<p>For the %s record of %s</p>\n" % (self.fail_type, self.fail_dname)

def get_unbound_host_valfail(dname):
    cmd = "unbound-host -C /etc/unbound/unbound.conf %s" % dname
    #cmd = "unbound-host -D %s" % dname
    logger.debug(cmd)
    stdout = run_cmd(shlex.split(cmd))
    for fl in stdout:
        dfd = DNSSECFailData(fl)
        if dfd.matched():
            return dfd

#
# Language keys
#
BASE_LANGKEY_PATH = "/usr/lib/valibox/autonta_lang"

class LanguageKey:
    def __init__(self, keystr):
        self.keystr = keystr.strip()

    def __str__(self):
        return self.keystr

    def __call__(self, args):
        logger.debug("[LANG] Replacing values in language key '%s' with '%s'" % (self.keystr, str(args)))
        return self.keystr % args

class LanguageKeys:
    def __init__(self, language):
        self.keys = {}
        self.read_keys(language)

    def read_keys(self, language):
        filename = "%s/%s" % (BASE_LANGKEY_PATH, language)
        try:
            with open(filename, 'r') as inputfile:
                for line in inputfile:
                    if line.startswith("#"):
                        continue
                    parts = line.partition(':')
                    if len(parts) != 3:
                        continue
                    key = parts[0]
                    value = parts[2]
                    self.keys[parts[0]] = LanguageKey(parts[2])
        except Exception as exc:
            # log error (TODO)
            # just read the english one
            if language != 'en_US':
                self.read_keys('en_US')
            else:
                raise exc
        logger.debug("Read %d langkeys from %s" % (len(self.keys.keys()), filename))

    def __getattr__(self, key):
        if key in self.keys:
            return self.keys[key]
        else:
            logger.error("Error: missing language key: %s" % key)
            return LanguageKey("<MISSING_LANGUAGE_KEY: %s>" % key)


#
# General config
#
class AutoNTAConfig:
    def __init__(self, filename):
        self.config_values = {}
        self.filename = filename
        self.loadtime = 0.0

    def check_modified_time(self):
        try:
            s = os.stat(self.filename)
            return s.st_mtime
        except OSError as ose:
            return -1

    def check_reload(self):
        modified = self.check_modified_time()
        logger.debug("mtime of %s: %f" % (self.filename, modified))
        if modified > self.loadtime:
            logger.debug("file was updated")
            self.read_config()
            self.loadtime = modified
            return True
        logger.debug("file was not updated")
        return False

    def read_config(self):
        logger.info("Reading configuration from %s" % self.filename)
        self.config_values = {}
        with open(self.filename) as inputfile:
            for line in inputfile.readlines():
                parts = line.strip().split()
                if len(parts) > 2 and parts[0] == 'option':
                    pval = parts[2]
                    if pval == "'1'" or pval == "1":
                        pval = True
                    elif pval == "'0'" or pval == "0":
                        pval = False
                    else:
                        pval = pval[1:-1]
                    self.config_values[parts[1]] = pval

    def get(self, name, default = None):
        if name in self.config_values:
            return self.config_values[name]
        else:
            return default

config = AutoNTAConfig("/etc/config/valibox")
langkeys = None
logger = logging.getLogger('autonta')
if not logger.handlers:
    handler = logging.handlers.SysLogHandler(address='/dev/log')
    formatter = logging.Formatter('%(name): %(levelname)-8s %(message)s')
    logger.addHandler(handler)

def reload_config():
    global config
    global langkeys
    global logging
    if config.check_reload():
        langkeys = LanguageKeys(config.get('language', 'en_US'))
        logger.setLevel(config.get("loglevel", "INFO"))

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

def check_validity(host_regex, dst_cookie_val):
    # the referer must be the ask_nta page
    referer = web.ctx.env.get("HTTP_REFERER")
    if referer is None:
        logger.info("Invalid request: no referer")
        return False
    referer_match = re.match(host_regex, referer)
    if referer_match is None:
        logger.info("Invalid request: bad referer: %s does not match %s" % (referer, regex))
        return False

    # Check the DST
    dst1 = web.input().dst
    dst2 = dst_cookie_val
    if dst1 != dst2:
        logger.info("DST mismatch: %s != %s" % (dst1, dst2))
        return False
    return True

def page_exc(exc):
    if type(exc) is web.seeother:
        raise exc
    else:
        logger.error(traceback.format_exc())
        return render.error(langkeys, str(exc))


class SetNTA:
    def GET(self, host):
        try:
            reload_config()
            nocache()
            logger.info("SetNTA called")
            if config.get('disable_nta'):
                logger.info("Configuration set to not ask for NTA")
                raise web.seeother("http://valibox./autonta/ask_nta/%s" % host)

            host_regex = "https?://(valibox\.)|(192\.168\.53\.1)/autonta/ask_nta/%s" % host
            dst_cookie_val = web.cookies(valibox_nta="<null>").valibox_nta
            if check_validity(host_regex, dst_cookie_val):
                add_nta(host)
                # remove the dst cookie
                web.setcookie('valibox_nta', '', -1)
                return render.nta_set(langkeys, host)
            else:
                raise web.seeother("http://valibox./autonta/ask_nta/%s" % host)
        except Exception as exc:
            return page_exc(exc)

class RemoveNTA:
    def GET(self, host):
        try:
            reload_config()
            nocache()
            logger.info("RemoveNTA called")
            remove_nta(host)
            raise web.seeother("http://valibox./autonta")
        except Exception as exc:
            return page_exc(exc)

def create_dst():
    return ''.join(random.SystemRandom().choice(string.ascii_lowercase + string.digits) for _ in range(12))

class AskNTA:
    def GET(self, host):
        try:
            reload_config()
            nocache()
            if is_first_run():
                raise web.seeother("http://valibox./autonta/set_passwords")
            logger.info("AskNTA called")

            # create a double-submit token
            dst = create_dst()
            web.setcookie('valibox_nta', dst, expires=300)

            # Get the actual error
            err = get_unbound_host_valfail(host)
            if err is not None:
                err_html = err.as_html()
            else:
                err_html = "Unknown error! Not DNSSEC?"

            # ask_nta
            nta_disabled = config.get('disable_nta')

            # make a list of domains to possibly set an NTA for
            if host.endswith('.'):
                host = host[:-1]
            domains = []
            labels = host.split('.')
            lc = len(labels)
            for i in range(lc-1):
                domains.append(".".join(labels[i:lc]))

            return render.ask_nta(langkeys, dst, host, domains, err,  nta_disabled)
        except Exception as exc:
            return page_exc(exc)

class NTAList:
    def GET(self):
        try:
            reload_config()
            nocache()
            if is_first_run():
                raise web.seeother("http://valibox./autonta/set_passwords")
            logger.info("NTA List called")
            ntas = get_ntas()
            return render.nta_list(langkeys, ntas)
        except Exception as exc:
            return page_exc(exc)

class NTA:
    def GET(self):
        try:
            reload_config()
            nocache()
            if is_first_run():
                raise web.seeother("http://valibox./autonta/set_passwords")
            logger.info("Base NTA called")
            host = web.ctx.env.get('HTTP_HOST')
            (host, port) = split_host(host)
            logger.info("Host: %s" % (host))
            if port is not None:
                logger.debug("Port: %d" % (port))
            if is_valid_ip_address(host) or is_known_host(host):
                raise web.seeother("http://valibox./autonta")
            else:
                if host + "." in get_ntas():
                    return render.nta_set(langkeys, host)
                if port is not None:
                    redirect = "http://%s:%s/autonta/ask_nta/%s" % (SELF_HOST, port, host)
                else:
                    redirect = "http://%s/autonta/ask_nta/%s" % (SELF_HOST, host)
                logger.debug("Redirecting to %s" % redirect)
                raise web.seeother(redirect)
        except Exception as exc:
            return page_exc(exc)

#
# Code for update checks
# (Note: this could be separated into a whole new instance, but
# we do not want to run even more python instances)
#
UPDATE_CHECK_BASE='https://valibox.sidnlabs.nl/downloads/valibox/'
UPDATE_CHECK_BASE_BETA='https://valibox.sidnlabs.nl/downloads/valibox/beta/'
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
#
class FirmwareVersionInfo:
    def __init__(self, beta=False):
        # Store as 'board'->(version, sha1sum ,firmware_url,update_url)
        self.versions = {}
        if beta:
            self.base_url = UPDATE_CHECK_BASE_BETA
        else:
            self.base_url = UPDATE_CHECK_BASE

    def fetch_version_info(self):
        # Retrieve it with curl?
        # Retrieve it through a call to wget; this python version
        # has some SSL issues
        # There is also very little checking on data for now
        try:
            tmpfile = "/tmp/versions_release.txt"
            for line in fetch_file(self.base_url + "versions.txt", tmpfile):
                parts = line.strip().split(' ')
                self.versions[parts[0]] = parts[1:]
            return True
        except Exception as exc:
            logger.warning("Error in fetch: " + str(exc))
            #raise exc
            return False

    def get_version(self, board):
        if board in self.versions:
            return self.versions[board][0]

    def get_firmware_url(self, board):
        if board in self.versions:
            return self.base_url + self.versions[board][1]

    def get_info_url(self, board):
        if board in self.versions:
            return self.base_url + self.versions[board][2]

    def get_sha256sum(self, board):
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
        logger.warning("Failure. file not downloaded")
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
        try:
            reload_config()
            nocache()
            logger.info("UpdateCheck called")

            # create a double-submit token
            dst = create_dst()
            web.setcookie('valibox_update', dst, expires=300)

            current_version = get_current_version()
            currently_beta = "beta" in current_version
            board_name = get_board_name()
            fvi_release = FirmwareVersionInfo()
            fvi_beta = FirmwareVersionInfo(True)

            if not fvi_release.fetch_version_info() or not fvi_beta.fetch_version_info():
                return render.update_check(langkeys, dst, True, False, current_version, currently_beta, "", None, None)
            if not currently_beta:
                update_version = fvi_release.get_version(board_name)
                other_version = fvi_beta.get_version(board_name)
            else:
                update_version = fvi_beta.get_version(board_name)
                other_version = fvi_release.get_version(board_name)
            if update_version is None or update_version == current_version:
                return render.update_check(langkeys, dst, False, False, current_version, currently_beta, other_version, None, None)
            else:
                # there is a new version
                # Fetch info
                if currently_beta:
                    fvi = fvi_beta
                else:
                    fvi = fvi_release
                lines = fetch_file(fvi.get_info_url(board_name), "/tmp/update_info.txt")
                info = "\n".join(lines)
                return render.update_check(langkeys, dst, False, True, current_version, currently_beta, other_version, update_version, info)
        except Exception as exc:
            return page_exc(exc)

def install_update(keep_settings):
    # sleep a little while so the page can still render
    time.sleep(2)
    if keep_settings:
        run_cmd(["/sbin/sysupgrade", "/tmp/firmware_update.bin"])
    else:
        run_cmd(["/sbin/sysupgrade", "-n", "/tmp/firmware_update.bin"])

def check_sha256sum(filename, expected_sum):
    output = run_cmd(["/usr/bin/sha256sum", filename])
    expected_sum += "  " + filename
    if len(output) > 0:
        filesum = output[0].strip()
        logger.debug("sha256sum of file: " + filesum)
        logger.debug("Expected: " + expected_sum)
        return filesum == expected_sum
    logger.error("sha256sum command failed")
    return False

class UpdateInstall:
    def GET(self):
        try:
            reload_config()
            nocache()
            logger.info("UpdateInstall called")

            host_regex = "https?://(valibox\.)|(192\.168\.53\.1)/autonta/update_check"
            dst_cookie_val = web.cookies(valibox_update="<null>").valibox_update
            if not check_validity(host_regex, dst_cookie_val):
                raise web.seeother("http://valibox./autonta/update_check")
            # remove the dst cookie
            web.setcookie('valibox_update', '', -1)

            beta = web.input().version == "beta"
            keep_settings = web.input(keepsettings='off').keepsettings == 'on'

            current_version = get_current_version()
            board_name = get_board_name()
            # Note, we download it again (just in case it was an old link)
            fvi = FirmwareVersionInfo(beta)

            if not fvi.fetch_version_info():
                raise web.seeother("//valibox./update_check")
            update_version = fvi.get_version(board_name)
            if update_version is None:# or update_version == current_version:
                raise web.seeother("//valibox./update_check")
            else:
                # there is a new version
                # Fetch info
                success = fetch_file(fvi.get_firmware_url(board_name), "/tmp/firmware_update.bin", False)
                if success and check_sha256sum("/tmp/firmware_update.bin", fvi.get_sha256sum(board_name)):
                    threading.Thread(target=install_update, args=(keep_settings,)).start()
                    return render.update_install(langkeys, True, update_version)
                else:
                    return render.update_install(langkeys, False, update_version)
        except Exception as exc:
            return page_exc(exc)


def getwifioption(name):
    matcher = re.compile("\s+option %s\s+'(.*)'" % name)
    with open("/etc/config/wireless") as inputfile:
        for line in inputfile.readlines():
            m = matcher.match(line)
            if m is not None:
                return m.group(1)
    return ""

def getwifiname():
    return getwifioption("ssid")

def getwifipass():
    return getwifioption("key")

def updatewifi(wifiname, wifipass):
    if wifiname is None:
        wifiname = getwifiname()
    if wifipass is None:
        wifipass = getwifipass()

    with open("/etc/config/wireless", "w") as outputfile:
        with open("/etc/config/wireless.in") as inputfile:
            for line in inputfile.readlines():
                if line.find("XHWADDRX") > 0:
                    outputfile.write("\toption encryption 'psk2'\n")
                    outputfile.write("\toption key '%s'\n" % wifipass)
                    outputfile.write("\toption ssid '%s'\n" % wifiname)
                else:
                    outputfile.write(line)

    cmd = "/etc/init.d/network restart"
    run_cmd(shlex.split(cmd))

def update_admin_pass(new):
    proc = subprocess.Popen(['/usr/bin/passwd'],
                            stdin = subprocess.PIPE)
    proc.stdin.write(new + "\n")
    proc.stdin.write(new + "\n")
    stdout, _ = proc.communicate()

def is_first_run():
    return not os.path.isfile("/etc/valibox_name_set")

def first_run_done():
    with open("/etc/valibox_name_set", "w") as outputfile:
        outputfile.write("1\n")

class SetPasswords:
    def GET(self):
        try:
            reload_config()
            nocache()
            logger.info("SetPasswords (GET) called")
            # this is only allowed the first time, later people can use the admin interface
            if not is_first_run():
                raise web.seeother("http://valibox.")
            dst = create_dst()
            web.setcookie('valibox_setpass', dst, expires=300)
            wifiname = getwifiname()
            return render.askpasswords(langkeys, dst, wifiname)
        except Exception as exc:
            return page_exc(exc)

    def POST(self):
        try:
        # check DST
            logger.info("SetPasswords (POST) called")
            host_regex = "https?://(valibox\.)|(192\.168\.53\.1)/autonta/set_passwords"
            dst_cookie_val = web.cookies(valibox_setpass="<null>").valibox_setpass
            if not check_validity(host_regex, dst_cookie_val):
                raise web.seeother("http://valibox./autonta/set_passwords")
            if not is_first_run():
                raise web.seeother("http://valibox.")

            new_wifiname = web.input().wifi_name
            new_wifipass = web.input().wifi_password
            new_adminpass = web.input().admin_password

            if new_wifiname != getwifiname() or new_wifipass != "":
                updatewifi(new_wifiname, new_wifipass)
            if new_adminpass != "":
                update_admin_pass(new_adminpass)

            cmd = "/usr/sbin/unbound-control local_zone_remove ."
            run_cmd(shlex.split(cmd))
            cmd = "/etc/init.d/unbound restart"
            run_cmd(shlex.split(cmd))

            first_run_done()
            return render.passwordsset(langkeys)
        except Exception as exc:
            return page_exc(exc)


class Index:
    def GET(self):
        try:
            reload_config()
            nocache()
            if is_first_run():
                raise web.seeother("http://valibox./autonta/set_passwords")
            logger.info("Index called")
            return index_render.index(langkeys, get_current_version())
        except Exception as exc:
            return page_exc(exc)


if __name__ == "__main__":
    store_pid()
    atexit.register(remove_pidfile)
    signal.signal(signal.SIGTERM, on_exit)
    reload_config()
    app = web.application(urls, globals())
    app.run()
