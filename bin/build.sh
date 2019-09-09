#!/bin/bash

mkdir -p ~/Library/texmf/tex/latex
ln -s "`realpath tex`" ~/Library/texmf/tex/latex/

pdflatex \
    -interaction=nonstopmode \
    -output-directory pdf \
    "`realpath "$1"`"
