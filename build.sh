#!/bin/sh

mkdir docs

unzip webHelpSS2-all.zip -d docs

git subtree push --prefix docs origin gh-pages