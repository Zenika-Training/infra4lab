#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


# Backported from Jinja2 2.11.2
def test_in(value, seq):
    """Check if value is in seq.
    .. versionadded:: 2.10
    """
    return value in seq


class TestModule(object):
    ''' Backported jinja2 tests '''

    def tests(self):
        return {
            'in': test_in
        }
