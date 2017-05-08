#!/bin/bash

projects=$1
all=0

if [ "$projects" = "" ] ; then
    projects=projects/*.json
    all=1
fi

mkdir -p results

rm -f results/*-openreviews*
rm -f results/*-openapproved*

if [ -n "${GERRIT_USER}" ] ; then
    EXTRA_ARGS="-u ${GERRIT_USER}"
fi

if [ -n "${GERRIT_KEY}" ]; then
    EXTRA_ARGS="${EXTRA_ARGS} -k ${GERRIT_KEY}"
fi

if [ -n "${GERRIT_SERVER}" ]; then
    EXTRA_ARGS="${EXTRA_ARGS} --server ${GERRIT_SERVER}"
fi

metadata() {
    date -u
    echo -n "reviewstats HEAD: "
    git rev-parse HEAD
    echo
}

for project in ${projects} ; do
    project_base=$(basename $(echo ${project} | cut -f1 -d'.'))
    (metadata > results/${project_base}-openreviews.txt && openreviews -p ${project} -l 15 ${EXTRA_ARGS} -o results/${project_base}-openreviews.txt)
    openreviews -p ${project} --html -l 15 ${EXTRA_ARGS} -o results/${project_base}-openreviews.html
    (metadata && openapproved -p ${project} ${EXTRA_ARGS}) > results/${project_base}-openapproved.txt
done

if [ "${all}" = "1" ] ; then
    (metadata && openreviews -a ${EXTRA_ARGS}) > results/all-openreviews.txt.tmp
    for f in results/*-openreviews.txt ; do
        (echo && cat $f) >> results/all-openreviews.txt.tmp
    done
    mv results/all-openreviews.txt.tmp results/all-openreviews.txt
    openreviews -a --html ${EXTRA_ARGS} | grep -v '</html>' > results/all-openreviews.html.tmp
    for f in results/*-openreviews.html ; do
        cat $f | grep -v 'html>' | grep -v 'head>' >> results/all-openreviews.html.tmp
    done
    echo "</html>" >> results/all-openreviews.html.tmp
    mv results/all-openreviews.html.tmp results/all-openreviews.html

    (metadata && openapproved -a ${EXTRA_ARGS}) > results/all-openapproved.txt
fi
