# Derived from ansible/plugins/connection/ssh.py (c) 2012, Michael DeHaan <michael.dehaan@gmail.com>
# Copyright (c) 2024 Nils Stein (@mietzen) <github.nstein@mailbox.org>
# Copyright (c) 2024 Ansible Project
# GNU General Public License v3.0+ (see LICENSES/GPL-3.0-or-later.txt or https://www.gnu.org/licenses/gpl-3.0.txt)
# SPDX-License-Identifier: GPL-3.0-or-later
#
# From burgerga's drop-in proxmox_pct_remote, gist a6d784ebf04ae6aa451c99a0daf07227
# at revision 5ef0fec7 (2026-10-30), offered in
# ansible-collections/community.proxmox#550: community.proxmox's plugin over
# OpenSSH instead of paramiko, so that every container on a node shares one
# multiplexed connection to it. Renamed pct_ssh, as ansible-generated's own.

from __future__ import annotations

DOCUMENTATION = r"""
    author: Nils Stein (@mietzen) <github.nstein@mailbox.org>
    name: pct_ssh
    short_description: Run tasks in Proxmox LXC container instances using pct CLI via SSH
    requirements:
      - OpenSSH client on the controller
      - C(sshpass) on the controller when using password authentication
    description:
      - Run commands or put/fetch files to an existing Proxmox LXC container using pct CLI via SSH.
      - Uses the OpenSSH client (like the P(ansible.builtin.ssh#connection) connection plugin) to connect to the Proxmox host.
    extends_documentation_fragment:
      - connection_pipelining
    notes:
      - >
        When the SSH user on Proxmox is not root (checked with C(id -u) on the host unless O(remote_user) is V(root)), you need to have a become mechanism,
        e.g. C(sudo), installed on Proxmox and setup so we can run it without prompting for the password.
        Inside the container, we need a shell, for example C(sh) and the C(cat) command to be available in the C(PATH) for this plugin to work.
      - Files are transferred by piping them through C(pct exec ... cat), so the SCP/SFTP options of P(ansible.builtin.ssh#connection) are not available.
    options:
      host:
          description: Hostname/IP to connect to.
          default: inventory_hostname
          type: string
          vars:
               - name: inventory_hostname
               - name: ansible_host
               - name: ansible_ssh_host
      host_key_checking:
          description: Determines if SSH should reject or not a connection after checking host keys.
          default: True
          type: boolean
          ini:
              - section: defaults
                key: 'host_key_checking'
              - section: ssh_connection
                key: 'host_key_checking'
          env:
              - name: ANSIBLE_HOST_KEY_CHECKING
              - name: ANSIBLE_SSH_HOST_KEY_CHECKING
          vars:
              - name: ansible_host_key_checking
              - name: ansible_ssh_host_key_checking
      password:
          description: Authentication password for the O(remote_user). Can be supplied as CLI option.
          type: string
          vars:
              - name: ansible_password
              - name: ansible_ssh_pass
              - name: ansible_ssh_password
      password_mechanism:
          description: Mechanism to use for handling ssh password prompt
          type: string
          default: ssh_askpass
          choices:
              - ssh_askpass
              - sshpass
              - disable
          env:
              - name: ANSIBLE_SSH_PASSWORD_MECHANISM
          ini:
              - {key: password_mechanism, section: ssh_connection}
          vars:
              - name: ansible_ssh_password_mechanism
      sshpass_prompt:
          description:
              - Password prompt that C(sshpass)/C(SSH_ASKPASS) should search for.
              - Supported by sshpass 1.06 and up when O(password_mechanism) set to V(sshpass).
              - Defaults to C(Enter PIN for) when pkcs11_provider is set.
              - Defaults to C(assword) when O(password_mechanism) set to V(ssh_askpass).
          default: ''
          type: string
          ini:
              - section: 'ssh_connection'
                key: 'sshpass_prompt'
          env:
              - name: ANSIBLE_SSHPASS_PROMPT
          vars:
              - name: ansible_sshpass_prompt
      ssh_args:
          description: Arguments to pass to all SSH CLI tools.
          default: '-C -o ControlMaster=auto -o ControlPersist=60s'
          type: string
          ini:
              - section: 'ssh_connection'
                key: 'ssh_args'
          env:
              - name: ANSIBLE_SSH_ARGS
          vars:
              - name: ansible_ssh_args
      ssh_common_args:
          description: Common extra args for all SSH CLI tools.
          type: string
          ini:
              - section: 'ssh_connection'
                key: 'ssh_common_args'
          env:
              - name: ANSIBLE_SSH_COMMON_ARGS
          vars:
              - name: ansible_ssh_common_args
          cli:
              - name: ssh_common_args
          default: ''
      ssh_executable:
          default: ssh
          description:
            - This defines the location of the SSH binary. It defaults to V(ssh) which will use the first SSH binary available in $PATH.
            - This option is usually not required, it might be useful when access to system SSH is restricted,
              or when using SSH wrappers to connect to remote hosts.
          type: string
          env: [{name: ANSIBLE_SSH_EXECUTABLE}]
          ini:
          - {key: ssh_executable, section: ssh_connection}
          #const: ANSIBLE_SSH_EXECUTABLE
          vars:
              - name: ansible_ssh_executable
      ssh_extra_args:
          description: Extra exclusive to the SSH CLI.
          type: string
          vars:
              - name: ansible_ssh_extra_args
          env:
            - name: ANSIBLE_SSH_EXTRA_ARGS
          ini:
            - key: ssh_extra_args
              section: ssh_connection
          cli:
            - name: ssh_extra_args
          default: ''
      reconnection_retries:
          description:
            - Number of attempts to connect.
            - Ansible retries connections only if it gets an SSH error with a return code of 255.
            - Any errors with return codes other than 255 indicate an issue with program execution.
          default: 0
          type: integer
          env:
            - name: ANSIBLE_SSH_RETRIES
          ini:
            - section: connection
              key: retries
            - section: ssh_connection
              key: retries
          vars:
            - name: ansible_ssh_retries
      port:
          description: Remote port to connect to.
          type: int
          ini:
            - section: defaults
              key: remote_port
          env:
            - name: ANSIBLE_REMOTE_PORT
          vars:
            - name: ansible_port
            - name: ansible_ssh_port
          keyword:
            - name: port
      remote_user:
          description:
              - User name with which to login to the remote server, normally set by the remote_user keyword.
              - If no user is supplied, Ansible will let the SSH client binary choose the user as it normally.
          type: string
          ini:
            - section: defaults
              key: remote_user
          env:
            - name: ANSIBLE_REMOTE_USER
          vars:
            - name: ansible_user
            - name: ansible_ssh_user
          cli:
            - name: user
          keyword:
            - name: remote_user
      pipelining:
          env:
            - name: ANSIBLE_PIPELINING
            - name: ANSIBLE_SSH_PIPELINING
          ini:
            - section: defaults
              key: pipelining
            - section: connection
              key: pipelining
            - section: ssh_connection
              key: pipelining
          vars:
            - name: ansible_pipelining
            - name: ansible_ssh_pipelining
      private_key_file:
          description:
              - Path to private key file to use for authentication.
          type: string
          ini:
            - section: defaults
              key: private_key_file
          env:
            - name: ANSIBLE_PRIVATE_KEY_FILE
          vars:
            - name: ansible_private_key_file
            - name: ansible_ssh_private_key_file
          cli:
            - name: private_key_file
              option: '--private-key'
      private_key:
          description:
            - Private key contents in PEM format. Requires the C(SSH_AGENT) configuration to be enabled.
          type: string
          env:
            - name: ANSIBLE_PRIVATE_KEY
          vars:
            - name: ansible_private_key
            - name: ansible_ssh_private_key
      private_key_passphrase:
          description:
            - Private key passphrase, dependent on O(private_key).
            - This does NOT have any effect when used with O(private_key_file).
          type: string
          env:
            - name: ANSIBLE_PRIVATE_KEY_PASSPHRASE
          vars:
            - name: ansible_private_key_passphrase
            - name: ansible_ssh_private_key_passphrase
      control_path:
        description:
          - This is the location to save SSH's ControlPath sockets, it uses SSH's variable substitution.
          - Since 2.3, if null (default), ansible will generate a unique hash. Use ``%(directory)s`` to indicate where to use the control dir path setting.
          - Before 2.3 it defaulted to ``control_path=%(directory)s/ansible-ssh-%%h-%%p-%%r``.
          - Be aware that this setting is ignored if C(-o ControlPath) is set in ssh args.
        type: string
        env:
          - name: ANSIBLE_SSH_CONTROL_PATH
        ini:
          - key: control_path
            section: ssh_connection
        vars:
          - name: ansible_control_path
      control_path_dir:
        default: ~/.ansible/cp
        description:
          - This sets the directory to use for ssh control path if the control path setting is null.
          - Also, provides the ``%(directory)s`` variable for the control path setting.
        type: string
        env:
          - name: ANSIBLE_SSH_CONTROL_PATH_DIR
        ini:
          - section: ssh_connection
            key: control_path_dir
        vars:
          - name: ansible_control_path_dir
      use_tty:
        default: true
        description: add -tt to ssh commands to force tty allocation.
        env: [{name: ANSIBLE_SSH_USETTY}]
        ini:
        - {key: usetty, section: ssh_connection}
        type: bool
        vars:
          - name: ansible_ssh_use_tty
      timeout:
        default: 10
        description:
            - This is the default amount of time we will wait while establishing an SSH connection.
            - It also controls how long we can wait to access reading the connection once established (select on the socket).
        env:
            - name: ANSIBLE_TIMEOUT
            - name: ANSIBLE_SSH_TIMEOUT
        ini:
            - key: timeout
              section: defaults
            - key: timeout
              section: ssh_connection
        vars:
          - name: ansible_ssh_timeout
        cli:
          - name: timeout
        type: integer
      pkcs11_provider:
        default: ""
        type: string
        description:
          - "PKCS11 SmartCard provider such as opensc, example: /usr/local/lib/opensc-pkcs11.so"
        env: [{name: ANSIBLE_PKCS11_PROVIDER}]
        ini:
          - {key: pkcs11_provider, section: ssh_connection}
        vars:
          - name: ansible_ssh_pkcs11_provider
      verbosity:
        default: 0
        type: int
        description:
          - Requested verbosity level for the SSH CLI.
        env: [{name: ANSIBLE_SSH_VERBOSITY}]
        ini:
          - {key: verbosity, section: ssh_connection}
        vars:
          - name: ansible_ssh_verbosity
      vmid:
        description:
          - LXC Container ID
        type: int
        vars:
          - name: proxmox_vmid
      proxmox_become_method:
        description:
          - Become command used in proxmox
        type: str
        default: sudo
        vars:
          - name: proxmox_become_method
"""

EXAMPLES = r"""
# Inventory (hosts.yml)
# all:
#   children:
#     lxc:
#       hosts:
#         container-1:
#           ansible_host: 10.0.0.10
#           proxmox_vmid: 100
#           ansible_connection: pct_ssh
#           ansible_user: ansible
---
- hosts: lxc
  tasks:
    - name: Ping LXC container
      ansible.builtin.ping:
"""

import os

from ansible.errors import AnsibleError, AnsibleFileNotFound
from ansible.module_utils.common.text.converters import to_bytes, to_text
from ansible.plugins.connection.ssh import Connection as SSHConnection
from ansible.utils.display import Display

display = Display()


class Connection(SSHConnection):
    """SSH based connections (OpenSSH) to Proxmox pct"""

    transport = "pct_ssh"

    def _build_pct_command(self, cmd: str) -> str:
        pct_cmd = " ".join(["/usr/sbin/pct", "exec", str(self.get_option("vmid")), "--", cmd])
        if self.get_option("remote_user") == "root":
            return pct_cmd
        # The effective user may come from ~/.ssh/config, so decide on the Proxmox host
        # whether pct needs the become method.
        become_method = self.get_option("proxmox_become_method")
        display.vvv(
            f"INFO Remote user is not explicitly root, running pct with become method {become_method} unless uid is 0",
            host=self.get_option("host"),
        )
        return f'[ "$(id -u)" = 0 ] || set -- {become_method}; "$@" {pct_cmd}'

    def _container_shell_command(self, cmd: str) -> str:
        return " ".join([self._shell.executable, "-c", self._shell.quote(cmd)])

    def exec_command(self, cmd: str, in_data: bytes | None = None, sudoable: bool = True) -> tuple[int, bytes, bytes]:
        """run a command inside the LXC container"""

        returncode, stdout, stderr = super().exec_command(
            self._build_pct_command(cmd), in_data=in_data, sudoable=sudoable
        )
        if returncode == 127 and b"/usr/sbin/pct" in stderr:
            raise AnsibleError(f"pct not found on host: {to_text(self.get_option('host'))}")
        return returncode, stdout, stderr

    def _raise_transfer_error(self, stdout: bytes, stderr: bytes) -> None:
        if b"cat: not found" in stderr:
            raise AnsibleError(f"cat not found in path of container: {to_text(self.get_option('vmid'))}")
        raise AnsibleError(f"{to_text(stdout)}\n{to_text(stderr)}")

    def put_file(self, in_path: str, out_path: str) -> None:
        """transfer a file from local to remote"""

        display.vvv(f"PUT {in_path} TO {out_path}", host=self.get_option("host"))
        if not os.path.exists(to_bytes(in_path, errors="surrogate_or_strict")):
            raise AnsibleFileNotFound(f"file or module does not exist: {in_path}")

        with open(in_path, "rb") as f:
            data = f.read()

        # ssh only closes stdin when there is data to send, so empty files are truncated instead
        redirect = "cat >" if data else ": >"
        returncode, stdout, stderr = self.exec_command(
            self._container_shell_command(f"{redirect} {self._shell.quote(out_path)}"),
            in_data=data or None,
            sudoable=False,
        )
        if returncode != 0:
            self._raise_transfer_error(stdout, stderr)

    def fetch_file(self, in_path: str, out_path: str) -> None:
        """save a remote file to the specified path"""

        display.vvv(f"FETCH {in_path} TO {out_path}", host=self.get_option("host"))
        returncode, stdout, stderr = self.exec_command(
            self._container_shell_command(f"cat {self._shell.quote(in_path)}"), sudoable=False
        )
        if returncode != 0:
            self._raise_transfer_error(stdout, stderr)
        with open(out_path, "wb") as f:
            f.write(stdout)
