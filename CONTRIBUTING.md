# Contributing

**Overpass for Node.js** is open source software; contributions from the
community are encouraged. Please take a moment to read these guidelines before
submitting changes.

## Branching and pull requests

As a guideline, please follow this process:

1. [Fork the repository].
2. Create a topic branch for the change, branching from **develop**
(`git checkout -b branch-name develop`).
3. Make the relevant changes.
4. [Squash] commits if necessary (`git rebase -i develop`).
5. Submit a pull request to the **develop** branch.

[Fork the repository]: https://help.github.com/articles/fork-a-repo
[Squash]: http://git-scm.com/book/en/Git-Tools-Rewriting-History#Changing-Multiple-Commit-Messages

## Running the test suite

    npm test
