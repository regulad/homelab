#!/bin/sh
# Export the SSH client configuration and host keys of both Ansible stages'
# exported groups to regulad/dotfiles, which deploys them (its
# docs/homelab-exports.md). Each stage renders ansible-common/exports/'s
# templates from its own inventory; the two are joined, compared with the
# plaintext of the files on dotfiles' master, and, on apply, age-encrypted to
# dotfiles' key and committed to its master in one commit as regubot, through
# GraphQL's createCommitOnBranch, which GitHub signs and which refuses a master
# that moved since it was read. AGENTS.md § Tasks.
#
#   tasks/exports.sh plan    exit 0: dotfiles has them; 2: they differ (shown)
#   tasks/exports.sh apply   commit them where they differ
set -eu
mode=$1
top=$(git rev-parse --show-toplevel)
# regulad/dotfiles, by its ID, which a rename keeps; its paths, under the
# source state's home/ (dotfiles' .chezmoiroot); and the recipient in its
# home/.chezmoi.toml.tmpl, whose identity is ~/key.txt on Parker's machines.
repository=1114033008
config_path=home/dot_ssh/config.d/encrypted_private_98-homelab.age
hosts_path=home/dot_ssh/known_hosts.d/encrypted_private_homelab.age
recipient=age14e7wj4lltcvva2jy9vzzul8y7yuj5xk9vtqfxt9erzz58xqwmpjqurdhep
identity=$HOME/key.txt
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# One stage's two files, rendered on the controller alone by an ad hoc run
# against localhost: no host is contacted, and alock wraps only
# ansible-playbook. The generated stage's inventory reads OpenTofu state.
render() {
    stage=$1
    for file in ssh_config known_hosts; do
        if ! (cd "$top/$stage" && sops exec-env ../tofu/shared/backend.sops.env \
            "PATH=\"\$PWD/bin:\$PATH\" ANSIBLE_DEPRECATION_WARNINGS=0 ansible localhost -o -e exports_known_hosts=$top/$stage/known_hosts -m ansible.builtin.template -a 'src=../ansible-common/exports/$file.j2 dest=$work/$stage.$file mode=0600'") \
            >"$work/$stage.$file.log" 2>&1; then
            cat "$work/$stage.$file.log" >&2
            exit 1
        fi
    done
}
render ansible-hardware
render ansible-generated
{
    echo "# regulad/homelab's hosts, generated from its inventories: edit them there."
    cat "$work/ansible-hardware.ssh_config" "$work/ansible-generated.ssh_config"
} >"$work/ssh_config"
cat "$work/ansible-hardware.known_hosts" "$work/ansible-generated.known_hosts" >"$work/known_hosts"

# What dotfiles' master holds, decrypted; nothing where a file is absent.
api=https://api.github.com/repositories/$repository
fetch() {
    status=$(curl -sS -o "$work/$2.age" -w '%{http_code}' -H 'Accept: application/vnd.github.raw+json' "$api/contents/$1?ref=master")
    case $status in
    200) age -d -i "$identity" "$work/$2.age" >"$work/$2.current" ;;
    404) : >"$work/$2.current" ;;
    *) echo "exports: GitHub answered $status for $1" >&2; exit 1 ;;
    esac
}
fetch "$config_path" ssh_config
fetch "$hosts_path" known_hosts

changed=false
for file in ssh_config known_hosts; do
    if ! cmp -s "$work/$file.current" "$work/$file"; then
        changed=true
        diff -u --label "dotfiles/$file" --label "homelab/$file" "$work/$file.current" "$work/$file" || true
    fi
done
if ! $changed; then
    echo "exports: dotfiles' master has both files as homelab renders them."
    exit 0
fi
[ "$mode" = apply ] || exit 2

# Encrypted afresh, as age output differs on every run; armoured, so the
# commit is text. The token is regubot's terraform-exports--dotfiles, read
# into this process alone and handed to curl on its stdin.
age -a -r "$recipient" -o "$work/ssh_config.new.age" "$work/ssh_config"
age -a -r "$recipient" -o "$work/known_hosts.new.age" "$work/known_hosts"
token=$(sops decrypt --extract '["pat"]["terraform-exports--dotfiles"]' "$top/tofu/github-user/bot.sops.yaml")
if [ -z "$token" ]; then
    echo "exports: tofu/github-user/bot.sops.yaml's pat.terraform-exports--dotfiles is empty: fill it with sops edit." >&2
    exit 1
fi
name=$(curl -fsS "$api" | jq -r .full_name)
jq -n --arg owner "${name%/*}" --arg name "${name#*/}" \
    '{query: "query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) { ref(qualifiedName: \"refs/heads/master\") { target { oid } } } }", variables: {owner: $owner, name: $name}}' >"$work/head.json"
head=$(printf 'header = "Authorization: bearer %s"\n' "$token" |
    curl -sS --config - -X POST -H 'Content-Type: application/json' --data-binary "@$work/head.json" https://api.github.com/graphql |
    jq -r '.data.repository.ref.target.oid')
commit=$(git -C "$top" rev-parse --short=12 HEAD)
jq -n --arg repo "$name" --arg head "$head" \
    --arg headline "[no ci] ssh: homelab's hosts, from regulad/homelab@$commit" \
    --arg config_path "$config_path" --arg config "$(base64 -w 0 "$work/ssh_config.new.age")" \
    --arg hosts_path "$hosts_path" --arg hosts "$(base64 -w 0 "$work/known_hosts.new.age")" \
    '{query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid url } } }",
      variables: {input: {branch: {repositoryNameWithOwner: $repo, branchName: "master"}, expectedHeadOid: $head,
        message: {headline: $headline},
        fileChanges: {additions: [{path: $config_path, contents: $config}, {path: $hosts_path, contents: $hosts}]}}}}' >"$work/commit.json"
result=$(printf 'header = "Authorization: bearer %s"\n' "$token" |
    curl -sS --config - -X POST -H 'Content-Type: application/json' --data-binary "@$work/commit.json" https://api.github.com/graphql)
unset token
url=$(printf '%s' "$result" | jq -r '.data.createCommitOnBranch.commit.url // empty')
if [ -z "$url" ]; then
    printf '%s\n' "$result" | jq -c '.errors' >&2
    exit 1
fi
echo "exports: committed $url"
