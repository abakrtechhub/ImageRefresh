# Workflow validation

This pull request exercises the review-branch path without publishing application source.

Local synthetic checks verified that safe source is accepted, a credential in an intermediate commit is rejected even after removal, executable output is rejected, a direct main push without the restricted initial bootstrap review is rejected, and missing review records block pushes.

The setup files were reviewed for unintended publication, token permissions, untrusted command interpolation, remote/branch restrictions, commit binding, intermediate-history scanning, and accidental execution of privileged application operations. The GitHub job has a read-only token, pins checkout to a commit, and runs source parsing/pattern checks without executing app scripts or native operations.

Limitations: this is a workflow review, not an audit of the unpublished app. Secret patterns are incomplete; a recorded Codex review is an attestation, not an independent review. Clone hooks can be bypassed; remote branch rules are the merge control. Source publication and application baseline review remain pending. No automatic merge is authorized.
