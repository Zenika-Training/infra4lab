#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function
__metaclass__ = type

# Inspired from :
#   - https://github.com/ansible/ansible/tree/devel/lib/ansible/modules/cloud/amazon/*
#   - https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/notification/mail.py

DOCUMENTATION = r'''
---
author:
  - Alexandre Garnier (@zigarn)
module: aws_ses_mail
short_description: Send an email
description:
  - This module is useful for sending emails from playbooks using AWS SES.
options:
  from:
    description:
      - The email-address the mail is sent from. May contain address and phrase.
    type: str
    required: yes
    aliases: [ sender ]
  to:
    description:
      - The email-address(es) the mail is being sent to.
      - This is a list, which may contain address and phrase portions.
    type: list
    required: yes
    aliases: [ recipients ]
  cc:
    description:
      - The email-address(es) the mail is being copied to.
      - This is a list, which may contain address and phrase portions.
    type: list
  bcc:
    description:
      - The email-address(es) the mail is being 'blind' copied to.
      - This is a list, which may contain address and phrase portions.
    type: list
  subject:
    description:
      - The subject of the email being sent.
    required: yes
    type: str
    aliases: [ msg ]
  body:
    description:
      - The body of the email being sent.
    type: str
    default: $subject
  attach:
    description:
      - A list of pathnames of files to attach to the message.
      - Attached files will have their content-type set to C(application/octet-stream).
    type: list
    default: []
  headers:
    description:
      - A list of headers which should be added to the message.
      - Each individual header is specified as C(header=value) (see example below).
    type: list
    default: []
  charset:
    description:
      - The character set of email being sent.
    type: str
    default: utf-8
  subtype:
    description:
      - The minor mime type, can be either C(plain) or C(html).
      - The major type is always C(text).
    type: str
    choices: [ html, plain ]
    default: plain
requirements: [ 'botocore', 'boto3' ]
extends_documentation_fragment:
  - aws
  - ec2
'''

EXAMPLES = r'''
- name: Send e-mail to a bunch of users, attaching files
  mail:
    subject: Ansible-report
    body: Hello, this is an e-mail. I hope you like it ;-)
    from: jane@example.net (Jane Jolie)
    to:
      - John Doe <j.d@example.org>
      - Suzie Something <sue@example.com>
    cc: Charlie Root <root@localhost>
    attach:
      - /etc/group
      - /tmp/avatar2.png
    headers:
      - Reply-To=john@example.com
      - X-Special="Something or other"
    charset: us-ascii
  delegate_to: localhost
'''

from ansible.module_utils.aws.core import AnsibleAWSModule
from ansible.module_utils.ec2 import camel_dict_to_snake_dict, AWSRetry, get_aws_connection_info

try:
    from botocore.exceptions import BotoCoreError, ClientError
except ImportError:
    pass  # caught by imported HAS_BOTO3

import os
from email import encoders
from email.utils import parseaddr, formataddr, formatdate
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.header import Header

from ansible.module_utils._text import to_native


def main():

    module = AnsibleAWSModule(
        argument_spec=dict(
            sender=dict(type='str', required=True, aliases=['from']),
            to=dict(type='list', required=True, aliases=['recipients']),
            cc=dict(type='list', default=[]),
            bcc=dict(type='list', default=[]),
            subject=dict(type='str', required=True, aliases=['msg']),
            body=dict(type='str'),
            attach=dict(type='list', default=[]),
            headers=dict(type='list', default=[]),
            charset=dict(type='str', default='utf-8'),
            subtype=dict(type='str', default='plain', choices=['html', 'plain']),
        ),
    )

    sender = module.params.get('sender')
    recipients = module.params.get('to')
    copies = module.params.get('cc')
    blindcopies = module.params.get('bcc')
    subject = module.params.get('subject')
    body = module.params.get('body')
    attach_files = module.params.get('attach')
    headers = module.params.get('headers')
    charset = module.params.get('charset')
    subtype = module.params.get('subtype')

    sender_phrase, sender_addr = parseaddr(sender)

    if not body:
        body = subject

    msg = MIMEMultipart(_charset=charset)
    msg['From'] = formataddr((sender_phrase, sender_addr))
    msg['Date'] = formatdate(localtime=True)
    msg['Subject'] = Header(subject, charset)
    msg.preamble = "Multipart message"

    for header in headers:
        # NOTE: Backward compatible with old syntax using '|' as delimiter
        for hdr in [x.strip() for x in header.split('|')]:
            try:
                h_key, h_val = hdr.split('=')
                h_val = to_native(Header(h_val, charset))
                msg.add_header(h_key, h_val)
            except Exception:
                module.warn("Skipping header '%s', unable to parse" % hdr)

    if 'X-Mailer' not in msg:
        msg.add_header('X-Mailer', 'Ansible mail module')

    addr_list = []
    for addr in [x.strip() for x in blindcopies]:
        addr_list.append(parseaddr(addr)[1])    # address only, w/o phrase

    to_list = []
    for addr in [x.strip() for x in recipients]:
        to_list.append(formataddr(parseaddr(addr)))
        addr_list.append(parseaddr(addr)[1])    # address only, w/o phrase
    msg['To'] = ", ".join(to_list)

    cc_list = []
    for addr in [x.strip() for x in copies]:
        cc_list.append(formataddr(parseaddr(addr)))
        addr_list.append(parseaddr(addr)[1])    # address only, w/o phrase
    msg['Cc'] = ", ".join(cc_list)

    part = MIMEText(body + "\n\n", _subtype=subtype, _charset=charset)
    msg.attach(part)

    # NOTE: Backware compatibility with old syntax using space as delimiter is not retained
    #       This breaks files with spaces in it :-(
    for filename in attach_files:
        try:
            part = MIMEBase('application', 'octet-stream')
            with open(filename, 'rb') as fp:
                part.set_payload(fp.read())
            encoders.encode_base64(part)
            part.add_header('Content-disposition', 'attachment', filename=os.path.basename(filename))
            msg.attach(part)
        except Exception as e:
            module.fail_json(rc=1, msg="Failed to send mail: can't attach file %s: %s" %
                             (filename, to_native(e)), exception=traceback.format_exc())

    composed = msg.as_string()

    # SES APIs seem to have a much lower throttling threshold than most of the rest of the AWS APIs.
    # Docs say 1 call per second. This shouldn't actually be a big problem for normal usage, but
    # the ansible build runs multiple instances of the test in parallel that's caused throttling
    # failures so apply a jittered backoff to call SES calls.
    connection = module.client('ses', retry_decorator=AWSRetry.jittered_backoff())

    try:
        result = connection.send_raw_email(Source=msg['From'], RawMessage={'Data': msg.as_string()})
    except (BotoCoreError, ClientError) as e:
        module.fail_json_aws(e, msg="Failed to send mail to '%s': %s" % (", ".join(set(addr_list)), to_native(e)))

    module.exit_json(msg='Mail sent successfully', result=result)


if __name__ == '__main__':
    main()
