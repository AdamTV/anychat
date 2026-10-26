# GitHub CLI

The devcontainer installs the official GitHub CLI feature. After rebuilding the
container, verify the installation:

```sh
gh --version
```

Authenticate interactively with the company Git host using HTTPS:

```sh
gh auth login --hostname git.alphatechnology.ca --git-protocol https --web
gh auth status --hostname git.alphatechnology.ca
```

Credentials are user-managed. Do not commit them or forward them through
repository configuration.
