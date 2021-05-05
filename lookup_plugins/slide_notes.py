#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = """
    lookup: notes
    author: Alexandre Garnier <zigarn@gmail.com>
    version_added: "0.9"
    short_description: Extract presentation notes
    description:
        - This lookup returns the list of presentation notes from a slides folder.
    options:
      _terms:
        description: path of folder to load slides from.
        required: True
"""

RETURN = """
  _list:
    description:
      - list of notes
"""

import json
import os
import re

from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleFileNotFound
from ansible.module_utils._text import to_text


SLIDE_SEP_RE = re.compile(r'\r?\n\r?\n\r?\n\r?\n')


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):

        ret = []
        for term in terms:

            slides_list_file = os.path.join(term, 'slides.json')
            if not os.path.exists(slides_list_file):
                raise AnsibleFileNotFound(file_name=slides_list_file)

            contents, _ = self._loader._get_file_contents(slides_list_file)
            slides_list = json.loads(contents)

            notes = []
            page = 1
            for slides in slides_list:
                slides_file = os.path.join(term, slides)
                if not os.path.exists(slides_file):
                    raise AnsibleFileNotFound(file_name=slides_file)

                b_contents, _ = self._loader._get_file_contents(slides_file)
                contents = to_text(b_contents, errors='surrogate_or_strict')
                for slide in SLIDE_SEP_RE.split(contents.strip()):
                    if 'Notes :' in slide:
                        notes.append(
                            {
                                'page': page,
                                'content': slide.split('Notes :')[1].strip()
                            }
                        )
                    page += 1
            ret.append(notes)

        return ret
