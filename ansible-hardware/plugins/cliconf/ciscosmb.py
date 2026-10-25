# community.ciscosmb's cliconf, with two changes. A command ends with
# network_cli's own carriage return alone: the collection appends a newline as
# well, and the second Enter, arriving while an SG300 prints, stalls its output
# (seen with show running-config on switch070e26). And it can push
# configuration, which the collection's cannot: get_diff works out commands
# from show running-config text, and edit_config sends them in configure mode.
# Selected by ansible_network_os: ciscosmb.
from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = """
name: ciscosmb
short_description: community.ciscosmb's cliconf with a single end of line per command, and pushes
description:
  - Wraps community.ciscosmb's cliconf for the Cisco SG300s.
  - get_diff compares a whole configuration as show running-config prints it with the
    running one. diff_match=line gives the commands that add the candidate's missing
    lines; diff_match=exact gives the commands that remove the running lines the
    candidate lacks. Run the first, then the second against a fresh read, so a setting
    a changed line overrides is never negated.
"""

import json
import re
import time

from ansible.module_utils.common.text.converters import to_bytes, to_text
from ansible.plugins.cliconf import enable_mode
from ansible_collections.community.ciscosmb.plugins.cliconf.ciscosmb import Cliconf as _Cliconf

# Seconds between typed characters, as for the console pastes that worked.
_TYPING_DELAY = 0.06
# Lines that enter a configuration mode. An interface's lines are indented and
# end at "!"; the others end at "exit".
_ENTERS = re.compile(r"^(interface |vlan database$|crypto key pubkey-chain ssh$|user-key )")
# A user key is replaced whole: user-key replaces the user's existing key.
_ATOMIC = re.compile(r"^user-key ")


def _split(text):
    """The header, up to the first "!", and the body after it, as lists of lines."""
    lines = [line.rstrip() for line in to_text(text).replace("\r", "").split("\n")]
    if "!" not in lines:
        raise ValueError("no ! ends the configuration header")
    end = lines.index("!")
    return [line for line in lines[:end] if line], lines[end + 1:]


def _walk(body):
    """Each line in order, as (the tuple of lines entering its mode, the line); None on entering a mode."""
    stack = []
    for raw in body:
        line = raw.strip()
        if not line:
            continue
        if line == "!":
            if stack and stack[-1].startswith("interface "):
                stack.pop()
        elif line == "exit":
            if stack:
                stack.pop()
        elif _ENTERS.match(line):
            if line.startswith("interface ") and stack and stack[-1].startswith("interface "):
                stack.pop()
            stack.append(line)
            yield tuple(stack), None
        else:
            yield tuple(stack), line


def _contexts(body):
    """Each configuration mode, as the tuple of lines entering it, mapped to its lines in order."""
    contexts = {(): []}
    for context, line in _walk(body):
        lines = contexts.setdefault(context, [])
        if line is not None:
            lines.append(line)
    return contexts


def _negate(line):
    if line.startswith("no "):
        return line[3:]
    if _ATOMIC.match(line):
        return "no " + " ".join(line.split()[:2])
    return "no " + line


def _commands(groups):
    """Commands for (mode, lines) groups, each entering its mode and leaving it again."""
    commands = []
    for context, lines in groups:
        commands += list(context) + lines + ["exit"] * len(context)
    return commands


def _group(groups, context, line=None):
    if not groups or groups[-1][0] != context:
        groups.append((context, []))
    if line is not None:
        groups[-1][1].append(line)


def additions(candidate, running):
    """Commands adding the candidate's missing lines, in the candidate's order:
    a line can depend on one above it, such as a secure MAC address on its locked port."""
    candidate_header, candidate_body = _split(candidate)
    running_header, running_body = _split(running)
    if candidate_header != running_header:
        raise ValueError("the configuration header, up to the first !, differs and cannot be pushed")
    want, have = _contexts(candidate_body), _contexts(running_body)
    groups = []
    for context, line in _walk(candidate_body):
        if line is None:
            if context not in have:
                _group(groups, context)
        elif context and _ATOMIC.match(context[-1]):
            if have.get(context) != want[context]:
                _group(groups, context, line)
        elif context not in have or line not in have[context]:
            _group(groups, context, line)
    return _commands(groups)


def removals(candidate, running):
    """Commands removing the running lines the candidate lacks, last first."""
    want, have = _contexts(_split(candidate)[1]), _contexts(_split(running)[1])
    groups = []
    for context, line in reversed(list(_walk(_split(running)[1]))):
        if context not in want:
            if line is None and context[:-1] in want:
                _group(groups, context[:-1], _negate(context[-1]))
        elif line is not None and not (context and _ATOMIC.match(context[-1])) and line not in want[context]:
            _group(groups, context, _negate(line))
    return _commands(groups)


class Cliconf(_Cliconf):
    def send_command(self, command=None, prompt=None, answer=None, sendonly=False, newline=True, prompt_retry_check=False, check_all=False):
        # Typed a character at a time: an SG300 drops the rest of a line that
        # arrives at once, and the session stalls (seen on switch45f304 after
        # show running-config had just printed). All but the last character go
        # straight to the shell, because network_cli ends every send with a
        # carriage return; the line runs only once it is complete.
        command = to_text(command)
        if not self._connection._connected:
            self._connection._connect()
        for character in command[:-1]:
            self._connection._ssh_shell.sendall(to_bytes(character))
            time.sleep(_TYPING_DELAY)
        response = super().send_command(
            command=command[-1:],
            prompt=prompt,
            answer=answer,
            sendonly=sendonly,
            newline=newline,
            prompt_retry_check=prompt_retry_check,
            check_all=check_all,
        )
        if sendonly:
            return response
        # network_cli strips the echo of the command it sent last, which here
        # was its last character only, and then surrounding whitespace.
        lines = to_text(response).split("\n")
        if lines and lines[0].strip() == command.strip():
            lines = lines[1:]
        return "\n".join(lines).strip()

    def get(self, command, prompt=None, answer=None, sendonly=False, newline=True, check_all=False):
        return self.send_command(
            command=command,
            prompt=prompt,
            answer=answer,
            sendonly=sendonly,
            newline=newline,
            check_all=check_all,
        )

    def get_device_operations(self):
        return {
            "supports_diff_replace": False,
            "supports_commit": False,
            "supports_rollback": False,
            "supports_defaults": False,
            "supports_onbox_diff": False,
            "supports_commit_comment": False,
            "supports_multiline_delimiter": False,
            "supports_diff_match": True,
            "supports_diff_ignore_lines": False,
            "supports_generate_diff": True,
            "supports_replace": False,
        }

    def get_option_values(self):
        return {
            "format": ["text"],
            "diff_match": ["line", "exact"],
            "diff_replace": [],
            "output": [],
        }

    def get_capabilities(self):
        result = json.loads(super().get_capabilities())
        result["rpc"] += ["get_diff", "edit_config"]
        result["device_operations"] = self.get_device_operations()
        result.update(self.get_option_values())
        return json.dumps(result)

    def get_diff(self, candidate=None, running=None, diff_match="line", diff_ignore_lines=None, path=None, diff_replace=None):
        if diff_match not in ("line", "exact"):
            raise ValueError("diff_match must be line or exact, not %s" % diff_match)
        commands = (additions if diff_match == "line" else removals)(candidate, running)
        return {"config_diff": "\n".join(commands)}

    @enable_mode
    def edit_config(self, candidate=None, commit=True, replace=None, comment=None):
        self.check_edit_config_capability(self.get_device_operations(), candidate, commit, replace, comment)
        responses = []
        self.send_command("configure terminal")
        for command in candidate:
            responses.append(self.send_command(command))
        self.send_command("end")
        return {"request": list(candidate), "response": responses}
