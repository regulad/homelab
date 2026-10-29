"""Tree filters for host_files_trees, run on the controller.

host_files_tree_files: each file directly in each tree's directory under the
host's files directory, as an item carrying the tree's path on the host, its
mode, owner and group, and the units it restarts or reloads.

host_files_tree_extras: the files a find of each tree's directory on the host
turned up that the tree no longer holds, as items carrying the tree's units.
"""

import os

from ansible.errors import AnsibleFilterError


def _units(tree):
    return {'restarts': tree.get('restarts', []), 'reloads': tree.get('reloads', [])}


def host_files_tree_files(trees, files_dir):
    items = []
    for tree in trees:
        src_dir = files_dir + tree.get('src', tree['path'])
        if not os.path.isdir(src_dir):
            raise AnsibleFilterError(f"host_files_tree_files: {src_dir} is not a directory")
        for name in sorted(os.listdir(src_dir)):
            src = os.path.join(src_dir, name)
            if not os.path.isfile(src):
                continue
            items.append({
                'tree': tree['path'],
                'path': f"{tree['path']}/{name}",
                'src': src,
                'mode': tree['mode'],
                'owner': tree.get('owner', 'root'),
                'group': tree.get('group', 'root'),
                **_units(tree),
            })
    return items


def host_files_tree_extras(found, trees, items):
    declared = {item['path'] for item in items}
    extras = []
    for tree, result in zip(trees, found):
        for found_file in result.get('files', []):
            if found_file['path'] not in declared:
                extras.append({'tree': tree['path'], 'path': found_file['path'], **_units(tree)})
    return extras


class FilterModule:
    def filters(self):
        return {'host_files_tree_files': host_files_tree_files, 'host_files_tree_extras': host_files_tree_extras}
