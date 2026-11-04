# alexa (Alexa skills)

Each directory is the source of truth for one Alexa skill in the developer account `regulad`:
its skill package, in the layout the Alexa Skills Kit CLI uses. The only skill is
`home-assistant`, the Smart Home skill behind Home Assistant's Alexa integration. Its Lambda,
role and trigger are in `tofu/aws`.

| Location | Configuration |
|---|---|
| `<skill>/skill-package/` | The skill package: `skill.json`, the manifest, and for a custom skill its interaction models and assets |
| `<skill>/ask-resources.json` | The ASK CLI project file: the skill's ID and where its package is |
| `<skill>/account-linking.sops.json` | The skill's account-linking settings, as `get-account-linking-info` returns them, encrypted |

No tool tracks state for a skill. CloudFormation's `Alexa::ASK::Skill` is marked
non-provisionable in its registry, so neither Cloud Control nor the `awscc` provider can manage
it. The one OpenTofu provider for skills has had no release beyond betas since 2022. So the
packages here are compared with the live skills by exporting them again, and changed by
deploying them.

## Running it

The ASK CLI (`ask`) comes from `regulad/dotfiles`; sign in once per machine with
`ask configure`, without linking an AWS account. From a skill's directory:

```bash
ask smapi export-package --skill-id "$(jq -r .profiles.default.skillId ask-resources.json)" --stage development
diff -r skill-package <exported>/skill-package           # drift, read-only
ask deploy --target skill-metadata                       # uploads skill-package/, a change
```

`export-package` writes a `skill-package` folder into the current directory, so run it in an
empty one. `ask deploy` keeps its state in `.ask/`, which is gitignored. The account-linking
settings are not part of the package: `ask smapi get-account-linking-info` reads them, and the
response never includes the client secret.

Discovery output stays local in `docs/snapshot/alexa/`. Every change to a skill needs Parker's
explicit approval.
