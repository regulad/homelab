"""Records each result as callbacks see it, for test_ansible: the task's name,
action, arguments, variables, delegation and check mode, and the result, a JSON line each
to the file $RECORDER_OUT names."""

import json
import os

from ansible.plugins.callback import CallbackBase


class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "aggregate"
    CALLBACK_NAME = "recorder"
    CALLBACK_NEEDS_ENABLED = True

    def _record(self, event, result):
        task = result.task
        record = {
            "event": event,
            "task": task.get_name(),
            "action": task.action,
            "args": dict(task.args),
            "vars": dict(task.vars or {}),
            "delegate_to": task.delegate_to,
            "check_mode": task.check_mode,
            "result": result.result,
        }
        with open(os.environ["RECORDER_OUT"], "a") as handle:
            handle.write(json.dumps(record, default=str) + "\n")

    def v2_runner_on_ok(self, result):
        self._record("ok", result)

    def v2_runner_item_on_ok(self, result):
        self._record("item_ok", result)

    def v2_runner_on_skipped(self, result):
        self._record("skipped", result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._record("failed", result)
