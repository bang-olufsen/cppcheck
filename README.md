# github-cppcheck

[![License](https://img.shields.io/badge/license-MIT_License-blue.svg?style=flat)](LICENSE)

Shell script for running the [Cppcheck](http://cppcheck.sourceforge.net) static code analysis tool for C/C++ source files. The script can either be executed from your build script or as part of GitHub pull requests with status updates (pending, success and failure). This makes it possible to add cppcheck as a required CI step on GitHub. Currently only [Shippable](http://www.shippable.com) CI and GitHub Actions is supported for knowing the repository, branch and linking to build logs.

Input can either be a directory (e.g. ".") or specific files. For pull requests the special "diff" command can be parsed as argument to check only the changed files.

When all files are checked (e.g. as part of nightly builds) the Cppcheck badge is updated for the particular repository and branch. The badge is afterwards uploaded to [Dropbox](http://www.dropbox.com). For displaying the badge on your README.md copy the Dropbox link to the image and replace www.dropbox.com with dl.dropboxusercontent.com. The color of the badge will be red in case of errors, yellow in case of only warnings and green if no bugs have been found.

False positives can be suppressed using the cppcheck.txt file which must be located in the directory from where the script is executed. You can run the shell script directly from GitHub using:

```bash
bash <(curl -s https://raw.githubusercontent.com/bang-olufsen/github-cppcheck/master/cppcheck.sh) .
```
