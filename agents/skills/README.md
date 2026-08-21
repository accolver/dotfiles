# Agent skills

Selected global agent skills managed by these dotfiles.

The install scripts symlink each directory under `agents/skills/` into
`~/.agents/skills/` so Pi and other agents that read the global skills
directory can use them without copying local state out of this repository.

Managed skills:

- `grill-me` from `mattpocock/skills`
- `domain-modeling` from `mattpocock/skills`
- `codebase-design` from `mattpocock/skills`
- `improve-codebase-architecture` from `mattpocock/skills`
- `unslop` from `backnotprop/pstack`

Superpowers is installed as a Pi package instead of vendored here:

```bash
pi install git:github.com/obra/superpowers
```

Do not vendor a separate global `writing-skills` skill here. Superpowers
provides `writing-skills`, and keeping an older copy in `~/.agents/skills`
creates a duplicate-skill warning in Pi.
