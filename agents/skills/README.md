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
- `acolver-voice` (Alan Colver's authentic voice, style, and tone)
- `enterprise-agent-generator`
- `merged` (post-merge PR, remote branch, and worktree cleanup)
- `agent-platform-migrate-from-ai-studio` from `google/skills`
- `google-cloud-recipe-auth` from `google/skills`
- `google-cloud-recipe-foundation-builder` from `google/skills`
- `google-cloud-solution-architecture` from `google/skills`
- `google-cloud-solution-multi-agent-security` from `google/skills`
- `google-cloud-solution-agentic-ai-borderless-data-lakehouse` from `google/skills`
- `google-cloud-storage-bucket-architect` from `google/skills`
- `secops-cases` from `google/skills`
- `google-cloud-scc-query` from `google/skills`
- `gcloud` from `google/skills`
- `retrieving-developer-knowledge` from `google/skills`

Superpowers is installed as a Pi package instead of vendored here:

```bash
pi install git:github.com/obra/superpowers
```

Do not vendor a separate global `writing-skills` skill here. Superpowers
provides `writing-skills`, and keeping an older copy in `~/.agents/skills`
creates a duplicate-skill warning in Pi.

`google-agents-cli` skills are installed globally via `bunx skills add google/agents-cli -g` into `~/.agents/skills` and mirrored across agent directories.
