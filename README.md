# gssh

Client side `ssh` wrapper script for auto port forwarding under ~77 SLOC. I couldn't find such a script online, so thought to put this together for using with Gitpod's ssh-gateway. Normally, `gssh` should work for any ssh host.

# Installation

Install via bashbox:

```bash
bashbox install https://github.com/axonasif/gssh
```

If you don't have bashbox installed, check [this](https://github.com/bashbox/bashbox#getting-started)

# Usage

You can pass a whole ssh command into `gssh`, normally this is helpful when you copy paste the ssh command from somewhere:

```bash
gssh ssh 'axonasif-dotfilessh-cemin9pjf2q@axonasif-dotfilessh-cemin9pjf2q.ssh.ws-us65.gitpod.io'
```

Or you can manually omit the `ssh` keyword if you like, to only pass the host address, you can pass any ssh arguments as well:

```
gssh -v 'axonasif-dotfilessh-cemin9pjf2q@axonasif-dotfilessh-cemin9pjf2q.ssh.ws-us65.gitpod.io' "uname -a"
```
