#!/usr/bin/python
# Copyright: Parker Wahle
# GNU Affero General Public License v3.0 (see https://www.gnu.org/licenses/agpl-3.0.txt)
"""Replace whole parts of pfSense's config.xml that pfsensible.core has no module for."""

from __future__ import annotations

import copy
import xml.etree.ElementTree as ET

from ansible.module_utils.basic import AnsibleModule
from ansible_collections.pfsensible.core.plugins.module_utils.pfsense import PFSenseModule

DOCUMENTATION = r"""
module: pfsense_config_section
short_description: Replace parts of pfSense's config.xml and reload what changed
description:
  - Each section names a parent element and the child elements it owns. The
    owned children are replaced by the section's XML fragment when they differ,
    ignoring whitespace; everything else in config.xml is left alone.
  - Writes config.xml the way pfsensible.core does, then runs each changed
    section's PHP reload code in order.
options:
  sections:
    description: Sections to converge, applied in order.
    type: list
    elements: dict
    required: true
    suboptions:
      name:
        description: Label for diffs and the config.xml revision.
        type: str
        required: true
      parent:
        description: Path of the parent element below the root; empty for the root.
        type: str
        default: ""
      select:
        description: ElementTree paths of the parent's direct children this section owns.
        type: list
        elements: str
        required: true
      xml:
        description: The owned children as they should be, as an XML fragment.
        type: str
        required: true
      ignore:
        description:
          - Paths, relative to each owned element, that something on the host
            rewrites. They are left out of the comparison, and their live values
            are kept when the section is written.
        type: list
        elements: str
        default: []
      reload:
        description: PHP run after config.xml is written, when this section changed.
        type: str
        default: ""
"""

# Elements whose text never appears in diffs.
REDACTED = {
    "bcrypt-hash",
    "device_key",
    "encryption_password",
    "password",
    "presharedkey",
    "privatekey",
    "prv",
}


def _normalized(elt):
    """Copy of elt with insignificant whitespace removed, for comparison."""
    out = copy.deepcopy(elt)
    for x in out.iter():
        x.text = (x.text or "").strip() or None
        x.tail = None
    return out


def _signature(elts):
    return [ET.tostring(_normalized(e), encoding="unicode") for e in elts]


def _display(elts):
    """Readable, redacted rendering of elts for a diff."""
    lines = []
    for e in elts:
        shown = _normalized(e)
        for x in shown.iter():
            if x.tag in REDACTED and x.text:
                x.text = "<redacted>"
        ET.indent(shown, space="  ")
        lines.append(ET.tostring(shown, encoding="unicode"))
    return "\n".join(lines) + "\n" if lines else ""


def _without(elts, ignore):
    """Copies of elts with the ignored paths removed."""
    out = []
    for e in elts:
        e = copy.deepcopy(e)
        for path in ignore:
            branch, _, leaf = path.rpartition("/")
            for holder in (e.findall(branch) if branch else [e]):
                for x in holder.findall(leaf):
                    holder.remove(x)
        out.append(e)
    return out


def _keep_live(current, wanted, ignore):
    """Carry the live values of ignored paths into wanted."""
    for live, new in zip(current, wanted):
        if live.tag != new.tag:
            continue
        for path in ignore:
            for live_x, new_x in zip(live.findall(path), new.findall(path)):
                new_x.text = live_x.text


def _owned(parent, select):
    """Direct children of parent matched by any select path, in document order."""
    matched = set()
    for path in select:
        matched.update(id(x) for x in parent.findall(path))
    return [x for x in parent if id(x) in matched]


def _parent(root, path, create):
    elt = root
    for tag in [p for p in path.split("/") if p]:
        child = elt.find(tag)
        if child is None:
            if not create:
                return None
            child = ET.SubElement(elt, tag)
        elt = child
    return elt


def _depth(root, target):
    def walk(elt, depth):
        if elt is target:
            return depth
        for child in elt:
            found = walk(child, depth + 1)
            if found is not None:
                return found
        return None

    return walk(root, 0)


def main():
    module = AnsibleModule(
        argument_spec={
            "sections": {
                "type": "list",
                "elements": "dict",
                "required": True,
                "options": {
                    "name": {"type": "str", "required": True},
                    "parent": {"type": "str", "default": ""},
                    "select": {"type": "list", "elements": "str", "required": True},
                    "xml": {"type": "str", "required": True, "no_log": True},
                    "ignore": {"type": "list", "elements": "str", "default": []},
                    "reload": {"type": "str", "default": ""},
                },
            },
        },
        supports_check_mode=True,
    )
    pfsense = PFSenseModule(module)
    root = pfsense.root

    changed_sections = []
    before_text, after_text = "", ""
    for section in module.params["sections"]:
        try:
            wanted = list(ET.fromstring("<fragment>" + section["xml"] + "</fragment>"))
        except ET.ParseError as exc:
            module.fail_json(msg="section %s: invalid XML: %s" % (section["name"], exc))

        # Every wanted element must be owned, or the next run would not see it.
        probe = ET.Element("probe")
        probe.extend(copy.deepcopy(e) for e in wanted)
        if len(_owned(probe, section["select"])) != len(wanted):
            module.fail_json(msg="section %s: fragment has elements outside select" % section["name"])

        parent = _parent(root, section["parent"], create=bool(wanted))
        current = _owned(parent, section["select"]) if parent is not None else []
        ignore = section["ignore"]
        if _signature(_without(current, ignore)) == _signature(_without(wanted, ignore)):
            continue
        _keep_live(current, wanted, ignore)

        changed_sections.append(section)
        before_text += "## %s\n%s" % (section["name"], _display(current))
        after_text += "## %s\n%s" % (section["name"], _display(wanted))

        children = list(parent)
        position = children.index(current[0]) if current else len(children)
        for elt in current:
            parent.remove(elt)
        for offset, elt in enumerate(wanted):
            parent.insert(position + offset, elt)
        ET.indent(parent, space="\t", level=_depth(root, parent))

    result = {
        "changed": bool(changed_sections),
        "changed_sections": [s["name"] for s in changed_sections],
        "diff": {"before": before_text, "after": after_text},
    }
    if changed_sections and not module.check_mode:
        pfsense.write_config(descr="ansible pfsense_config_section: %s" % ", ".join(result["changed_sections"]))
        for section in changed_sections:
            if not section["reload"].strip():
                continue
            code = '<?php\nrequire_once("config.inc");\nrequire_once("functions.inc");\n%s\n' % section["reload"]
            rc, stdout, stderr = module.run_command("/usr/local/bin/php", data=code)
            if rc != 0:
                module.fail_json(msg="section %s: reload failed" % section["name"], rc=rc, stdout=stdout, stderr=stderr, **result)
    module.exit_json(**result)


if __name__ == "__main__":
    main()
