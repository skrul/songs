#!/bin/bash

mkdir -p ~/Library/texmf/tex/latex
ln -s "`realpath tex`" ~/Library/texmf/tex/latex/

input_file="`realpath "$1"`"

output_file=$(\
  cat "$input_file" | \
  grep "\\\begin{song}" | \
  sed -E 's/.*title={([^}]*)}, band={([^}]*)}, year={([^}]*)}.*/\1 - \2 (\3)/' | \
  tr -d '\n' \
)

pdflatex \
    -interaction=nonstopmode \
    -output-directory pdf \
    -jobname="$output_file" \
    "$input_file"
