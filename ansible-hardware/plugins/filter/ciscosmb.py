# ciscosmb_normalize: an SG300 configuration as text to compare, without
# carriage returns, trailing spaces on lines, or blank lines at the end.
from __future__ import absolute_import, division, print_function

__metaclass__ = type


def ciscosmb_normalize(text):
    lines = [line.rstrip() for line in text.replace("\r", "").split("\n")]
    while lines and not lines[-1]:
        lines.pop()
    return "\n".join(lines) + "\n"


class FilterModule(object):
    def filters(self):
        return {"ciscosmb_normalize": ciscosmb_normalize}
