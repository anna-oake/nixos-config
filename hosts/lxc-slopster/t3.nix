{
  lib,
  pkgs,
  ...
}:
{
  services.t3-server = {
    enable = true;
    user = "slopster";
    group = "slopster";
    lan = true;
    browserExecutable = lib.getExe pkgs.chromium;
  };

  services.t3-flake-fixer = {
    enable = true;
    user = "slopster";
    buildbotUrl = "http://builder-buyan.me.ow";
    repositories = {
      "anna-oake/nixos-config" = "/storage-fast/slopster/Projects/nixos-config";
      "maeve-oake/nixos-config" = "/storage-fast/slopster/Projects/maeve-nixos-config";
    };
    prompt = ''
      The daily flake update job in {{repository}} caused build failures at revision {{revision}}.

      This is what failed:
      {{failed_steps}}

      Analyse the full logs of failed build/evaluation steps in {{bundle_path}}

      If this is a failure caused by CI issues (broken builder, no disk space, etc), report to me and stop.
      Otherwise, investigate what caused the failures.
      Often it is breaking changes in upstream flakes such as removed/renamed module options.
      Sometimes it can be conflicts caused by our previous temporary workarounds/fixes that are now fixed in upstream and must be removed.
      It could also be genuine new upstream fuckups, like a new version of a package or its dependency causing its build failure.
      Usually, in the latter case there would be an issue in upstream repo (such as nixpkgs) or even a PR that fixes the failure.

      Do your best to cleanly fix all the failures.
      If it is an upstream fuckup and you are adding some temporary workaround / override, prepend the block with a short and concise comment starting with "# TODO:", e.g. "# TODO: remove once merged/resolved <upstream PR/issue link>".

      If there is multiple separate unrelated issues causing different failures, fix each in a separate commit.
      If multiple build steps failed due to one shared issue, the fix goes into one commit.

      You are in a new worktree on its own fix branch. Before you start fixing anything, make sure your branch is matching the remote flake-update branch. Fetch origin/flake-update and compare its fresh head with {{revision}}.
      Nightly jobs force push it, so don't try pulling it, just hard reset your worktree to the remote flake-update.
      If {{revision}} is not the latest commit on flake-update, you are late to the party, abort and report to me.

      Don't waste time building hosts or packages here. You can evaluate the host attributes, which is enough. CI will do the actual building.

      Once your fixes are ready, commit, push and create a PR into flake-update as slopster.
      Watch the PR until checks pass or fail.

      If the build fails again, check the fresh Buildbot logs with http://builder-buyan.me.ow/api/v2/ and fix your shit.
      The resulting green PR should have one commit per original independent root cause, so squash your stuff if you need several iterations.

      If you don't know how to fix cleanly or what caused the issue, or if you spent 3 iterations on one failure, give up and report to me with your best findings.

      DO NOT "fix" by reverting the updates, downgrading inputs, disabling failing features/software.

      If you believe the fix belongs to oake/nix-things, abort and report to me.

      If the PR is green and you believe it's ready to go, report to me, and make sure to let me know if you consider any of the fixes dirty or temporary workarounds.

      Each line in the PR description bullet point should concisely cover one unique failure: it's reason and your fix. In the same order as commits.

      The entire final response should read like a short, nicely formatted Slack message from an engineer. Use a numbered list with one very concise item per independent root cause: what failed and why, and what you did about it. Briefly mention failed attempts or blockers if unresolved, and flag temporary workarounds. End with one final verdict: whether CI is green and the PR is ready to merge (with its link), or whether my intervention is needed and exactly what I need to do. Assume the reader hasn't seen this prompt but already knows the repository from the thread.
      Keep it brief, with no headings, long report, repository recap, or instruction/compliance commentary such as "no commits made", "no PR created", or "nothing merged". If no fix PR was needed or possible, just explain why (e.g. the builder ran out of disk space).

      NEVER merge anything yourself, do not attempt to connect to the hosts, do not touch (write) other projects and repositories.
      Your write work is limited to this worktree, the Buildbot API for fetching logs of your fix attempts, and making commits and PRs as slopster in this branch.
      Your read-only research is unlimited: feel free to inspect upstream flakes, search for issues, PRs and any other helpful information.

      Good luck ^_^
    '';
  };

  environment.systemPackages = with pkgs; [
    ripgrep
    gh
    go
    python3
    temurin-bin-25
    git
  ];
}
