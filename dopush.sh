#!/bin/sh

if [[ -f "./ssmmon.exe" ]]; then
	rm ./ssmmon.exe
fi
if [[ -f "./ssmmon" ]]; then
	rm ./ssmmon
fi
if [[ -d "./dynamicgeneration" ]]; then
	rm -rf ./dynamicgeneration
fi

git add .
git commit -m "$1"
git push
