# ImageRefresh

Repository setup for the Windows installation-media servicing app and its shared PowerShell functionality.

App source has not yet been published. The current local candidate is `v0.47.0-reconstructed` in the MediaRefresh project; earlier deliveries remain local and immutable.

Future Codex changes use `review/<description>` branches, security review, checks, and pull requests. Nothing uploads on individual file saves. See [SECURITY.md](SECURITY.md) for the complete process and limitations.

Install the local hook in each working clone with `git config core.hooksPath .githooks`. Codex reviews and tests a completed change, commits the intended files, records the review for that exact commit, then invokes `Publish-ImageRefresh.ps1`. The helper never stages everything or pushes directly to main. New commits require a new review record.

GitHub Actions repeats source/file/credential checks without running the app's disk, image or power operations. No automatic merge or deployment is configured. Source license selection remains pending.
