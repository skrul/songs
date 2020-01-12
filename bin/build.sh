#!/bin/bash

TEXML_HOME=$HOME/Library/texmf/tex/latex
PDF_JOINER="/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py"

function setup_pdflatex {
    if [ ! -d $TEXML_HOME ]; then
        mkdir -p $TEXML_HOME
    fi

    if [ ! -d $TEXML_HOME/tex ]; then
        ln -s "`realpath .`" $TEXML_HOME
    fi
}

function make_pdf {
    infile="`realpath "$1"`"
    indir=$(dirname "$1")
    pdf_outdir="`realpath "build/pdf"`/${indir#songs/}"
    #aux_outdir="`realpath "aux"`/${indir#songs/}"

    mkdir -p "$pdf_outdir"
    #mkdir -p "$aux_outdir"

    pdflatex \
        -interaction=nonstopmode \
        -output-directory="$pdf_outdir" \
        "$infile"
}

function make_packet {
    pdfs=""
    while read p; do
        make_pdf "songs/$p.tex"
    done < <(grep includepdf $1 | grep build/pdf | sed -E 's/.*{build\/pdf\/([^}]*)\.pdf}.*/\1/')

    mkdir -p "build/packets"
    pdflatex \
       -interaction=nonstopmode \
       -output-directory="build/packets" \
       "$1"
}

setup_pdflatex
#make_pdf "$1"

make_packet "packets/aircoustic202001.tex"
#make_packet "packets/pha201911.tex"
#make_packet "packets/aircoustic201912.tex"
#make_packet "packets/pha201912.tex"
