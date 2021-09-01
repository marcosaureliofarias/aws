#!/usr/bin/env python
#
# Create/Remove dns record via amazon aws api
# -------------------------------------------
# require python2 but it's compatible with python3
# for comunication with aws require modul boto
#
#
# Install:
#    pip install boto
#
# example:
#    awsdns.py --domain easyredminetrial.com --alias nova-domena.easyredminetrial.com --forward-to bra1.easyredminetrial.com --action create/remove
#

import boto.route53
import argparse

def log_err(message):
        print("ERR: ", message)


def is_ipv4(address):
    try:
        if int(address.split('.')[1]): return True
    except ValueError:
        return False
    except AttributeError:
        log_err("is_ipv4 - address not set")
        return False


def manage_alias(alias, forward_to, domain, action):
    """ create or remove alias in zone via AWS

    >>> manage_alias(alias='pokus.newdomain.com', forward_to='pokus.another-domain.com', domain="baddomain.com", action="create")
    ValueError: domain must be part of new_alias
    """
    try:
        if domain in alias:
            try:
                aws = boto.route53.connect_to_region(REGION, aws_access_key_id=AWS_ID, aws_secret_access_key=AWS_SECRET)
            except:
                log_err('authenticate to aws at first')
                exit(1)
            try:
                zone = aws.get_zone(domain)
                if forward_to is None and action == "create":
                    log_err("create_lias - forward_to is not defined")
                    exit(1)
                if is_ipv4(forward_to):
                    if action == 'create': zone.add_a(name=alias, value=forward_to)
                    elif action == 'remove': zone.delete_a(name=alias)
                    else: log_err("Unknown action variable")
                else:
                    if action == "create": zone.add_cname(name=alias, value=forward_to)
                    elif action == "remove": zone.delete_cname(name=alias)
                    else: log_err("Unknown action variable")
            except KeyError:
                print("Vyjimka")
            finally:
                aws.close()

        else:
            log_err("domain must be part of new_alias")
            return 2

    except TypeError:
        log_err("domain is undefined")
    except boto.route53.exception.DNSServerError:
        log_err('alias already exists')

if __name__ == '__main__':
    from optparse import OptionParser
    import sys

    # Zpracovani argumentu
    p = OptionParser()
    p.usage = "awsdns.py --aws_region us-west-2 --aws_id KMLCDLCLDC545DC --aws_secret DCcd4dcd54cd54cd54cd4c4c44c7c7 --domain easyredminetrial.com --alias nova-domena.easyredminetrial.com --cname bra1.easyredminetrial.com --action create/remove"
    p.add_option("--aws_region", dest="aws_region", default=None,
                help="AWS region")
    p.add_option("--aws_id", dest="aws_id", default=None,
                help="AWS id")
    p.add_option("--aws_secret", dest="aws_secret", default=None,
                help="AWS secret")
    p.add_option("--domain", dest="domain", default=None,
                help="Specifi domain to manage")
    p.add_option("--action", dest="action", default=None,
                help="What action would you like to do (create/remove)")
    p.add_option("--alias", dest="alias", default=None,
                help="FQDN alias you would like to create/remove")
    p.add_option("--cname", dest="forward_to", default=None,
                help="FQDN destination you would like to set as a destination of alias")
    (OPT, ARGS) = p.parse_args(sys.argv[1:])

    REGION = OPT.aws_region
    AWS_ID = OPT.aws_id
    AWS_SECRET = OPT.aws_secret

    try:
        if OPT.action in ['create','remove']:
            manage_alias(domain=OPT.domain, alias=OPT.alias, forward_to=OPT.forward_to, action=OPT.action),
        else:
            p.print_help()
    except IOError:
        p.print_help()
