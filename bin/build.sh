#!/bin/zsh

set -x

export max_print_line=1000
export error_line=254
export half_error_line=238

TEXML_HOME=$HOME/Library/texmf/tex/latex
SONGS_HOME=`pwd`

function setup_pdflatex {
    if [ ! -d $TEXML_HOME ]; then
        mkdir -p $TEXML_HOME
    fi

    if [ ! -d $TEXML_HOME/tex ]; then
        ln -s $SONGS_HOME/tex $TEXML_HOME
    fi
}

function make_pdf {
    infile="$SONGS_HOME/$1"
    indir=$(dirname "$1")
    pdf_outdir="$SONGS_HOME/build/pdf/${indir#songs/}"
    #aux_outdir="`realpath "aux"`/${indir#songs/}"

    mkdir -p "$pdf_outdir"
    #mkdir -p "$aux_outdir"

    TEXINPUTS=$indir: pdflatex \
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
       -output-directory="build/packets" \
       "$1"
}

setup_pdflatex
#make_pdf "$1"

make_packet "packets/aircoustic202205.tex"
