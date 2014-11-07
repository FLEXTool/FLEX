#!/bin/sh
KEYWORDS="TODO:|VERIFY:|FIXME:|\?\?\?:|\!\!\!:"
find "${SRCROOT}" -not -path "${SRCROOT}/Pods/*" \( -name "*.h" -or -name "*.m" \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "($KEYWORDS).*\$" | perl -p -e "s/($KEYWORDS)/ warning: \$1/"