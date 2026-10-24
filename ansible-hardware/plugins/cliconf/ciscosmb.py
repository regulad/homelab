# community.ciscosmb's cliconf, except that a command ends with network_cli's
# own carriage return alone: the collection appends a newline as well, and the
# second Enter, arriving while an SG300 prints, stalls its output (seen with
# show running-config on switch070e26). Selected by ansible_network_os: ciscosmb.
from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = """
name: ciscosmb
short_description: community.ciscosmb's cliconf with a single end of line per command
description:
  - Wraps community.ciscosmb's cliconf for the Cisco SG300s.
"""

from ansible_collections.community.ciscosmb.plugins.cliconf.ciscosmb import Cliconf as _Cliconf


class Cliconf(_Cliconf):
    def get(self, command, prompt=None, answer=None, sendonly=False, newline=True, check_all=False):
        return self.send_command(
            command=command,
            prompt=prompt,
            answer=answer,
            sendonly=sendonly,
            newline=newline,
            check_all=check_all,
        )
