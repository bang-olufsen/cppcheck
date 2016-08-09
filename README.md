# cppcheck

[![License](https://img.shields.io/badge/license-MIT_License-blue.svg?style=flat)](LICENSE)

Shell script for running the [Cppcheck](http://cppcheck.sourceforge.net) static code analysis tool for C/C++ source files. The script can either be executed from your build script or as part of GitHub pull requests. Currently only [Shippable](http://www.shippable.com) CI is supported.

Input can either be a directory (e.g. ".") or specific files. For pull requests the special "diff" command can be parsed as argument to check only the changed files.

When all files are checked (e.g. as part of nightly builds) the Cppcheck badge is updated for the particular repository and branch. The badge is afterwards uploaded to [Dropbox](http://www.dropbox.com). For displaying the badge on e.g. your README.md copy the Dropbox link to the image and replace www.dropbox.com with dl.dropboxusercontent.com.