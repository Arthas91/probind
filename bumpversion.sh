#!/usr/bin/env bash
#
# Copyright (c) 2016 Paco Orozco <paco@pacoorozco.info>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# ----------------------------------------------------------------------
# This is a utility script for bumping the version on the ProBIND
# application. It uses `sed` to update the version variable in the
# version file(s).
#
# NOTE: see the usage text for additional information regarding version
# numbers.
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# DO NOT MODIFY BEYOND THIS LINE
# ----------------------------------------------------------------------
# Program name and version
PN=$(basename "$0")
VER='0.1'

# ----------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------
usage()
{
	cat <<-EndUsage
	Bump the version of ProBIND!

	usage: ${PN} [-h|--help] part

    Arguments:

    part (required)

    The part of the version to increase, e.g. minor.

    Given a version number MAJOR.MINOR.PATCH, increment the:

    MAJOR version when you make incompatible API changes,
    MINOR version when you add functionality in a backwards-compatible manner, and
    PATCH version when you make backwards-compatible bug fixes.

    The new VERSION will be updated in two files:

	    config/app.php
	    CHANGELOG.md

    Options:

    -h, --help   Prints usage and help.

	EndUsage
}

print_finish_release_note()
{
    #
    # Get the current branch name
    #
    local _current_branch=`git rev-parse --abbrev-ref HEAD`

    #
    # Get last commit messages
    #
    local _last_commits=`git log --pretty=short v${current_version}.. | git shortlog | cat`

    cat <<-EndFinishReleaseNote
    Remember to:

        1. Update CHANGELOG.md

        ${_last_commits}

        2. Commit changes:

        $ git commit -s -m "Bump version ${current_version} -> ${new_version}" config/app.php CHANGELOG.md

        3. Merge to master branch:

        $ git checkout master
        $ git merge --no-ff ${_current_branch}

        4. Tag the tree:

        $ git tag -s -m "Version ${new_version}" v${new_version}

        5. Merge to develop branch:

        $ git checkout develop
        $ git merge --no-ff ${_current_branch}
	EndFinishReleaseNote
}

get_new_version_number()
{
    #
    # Set new version
    #
    case $1 in
        major) new_version=`echo ${current_version} | awk -F. '{ printf ("%d.%d.%d\n", $1 + 1, 0, 0); }'` ;;
        minor) new_version=`echo ${current_version} | awk -F. '{ printf ("%d.%d.%d\n", $1, $2 + 1, 0); }'` ;;
        patch) new_version=`echo ${current_version} | awk -F. '{ printf ("%d.%d.%d\n", $1, $2, $3 + 1); }'` ;;
    esac
}

get_current_version_number()
{
    #
    # Get current version from config/app.php
    #
    current_version=`grep "'version' => '\(.*\)'" config/app.php |
    	head -1 |
    	awk '{ print $3 }' | sed "s/[',]//g"`
}

bump_version()
{
    #
    # Format the current date for the README header
    #
    local date=`date '+%Y-%m-%d'`

    echo -e "Bump version: ${current_version} -> ${new_version}\n"

    # Update version number on config/app.php
    sed -i config/app.php -e "s/'version' => '\(.*\)'/'version' => '${new_version}'/g"

	# Create a new section on CHANGELOG
	sed -i CHANGELOG.md -e "s/^## Unreleased/## Unreleased\n\n## ${new_version} - ${date}\n/g"
}

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

get_current_version_number

if [ "x${current_version}" == "x" ]; then
    echo "ERROR: Can't determine the current version."
    exit 1
fi

case $1 in
    -h|--help)
        usage
        ;;
	major|minor|patch)
    	if [ "x`git status -s -uno`" != "x" ]; then
        	echo 'ERROR: Uncommited changes in repository. Commit before bump version' 1>&2
	        exit 1
        fi
	    get_new_version_number $1
	    bump_version
	    print_finish_release_note
	    ;;
	*)
	    echo "ERROR: You have failed to specify what to do correctly. Use '${PN} --help' for more information."
	    exit 1
	    ;;
esac

exit 0
