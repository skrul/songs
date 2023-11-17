\ProvidesClass{skrul-leadsheet}
\LoadClassWithOptions{scrartcl}

\usepackage{savesym}
\usepackage{gchords}
\savesymbol{chord}

\RequirePackage{leadsheets}

\RequirePackage{etoolbox}
\RequirePackage{translations}

\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}

\usepackage[sfdefault]{roboto}

\usepackage{geometry}
\geometry{
 letterpaper,
 margin=0.5in
}
\pagenumbering{gobble}

\usepackage[dvipsnames]{xcolor}

\definesongproperty{year}
\definesongproperty{meter}
\definesongproperty{note}

\definesongtitletemplate{leadsheet}{%
{\large \textbf{\songproperty{title}} - \songproperty{band}}
{\footnotesize
  \space\space // \space\space \songproperty{year}
  \space\space // \space\space key: \songproperty{key}
  \ifsongproperty{capo}{\space\space // \space\space\capo}{}
  \ifsongproperty{tempo}{\space\space // \space\space\songproperty{tempo} bpm}{}
  \ifsongproperty{meter}{\space\space // \space\space\songproperty{meter} time}{}
  \ifsongproperty{note}{\space\space // \space\space\songproperty{note}}{}
}

\vspace{-0.5\baselineskip}
\hrulefill
}

\ExplSyntaxOn

\char_set_catcode_other:N \#
\char_set_catcode_parameter:N \!

\prop_const_from_keyval:Nn \__skrul_enharmonic_map_prop
  {
    A/F##=A/G,
    Am/E#*=Am/F*,
    Am/F##=Am/G,
    Am/F##*=Am/G*,
    Ab#m=Am,
    A##m7=Bm7,
    Bm/G##=Bm/A,
    B#=C,
    B#9=C\textsuperscript{9},
    B#/B=C/B,
    B#/E=C/E,
    B#*=C*,
    B#m=Cm,
    B#add9=Cadd9,
    B#dim=Cdim,
    (B#)=(C),
    Bb#=B,
    Bb#m7=Bm7,
    B#maj7=Cmaj7,
    B#m6=Cm6,
    C##=D,
    C##5=D\textsuperscript{5},
    (C##5)=\textsuperscript{(D5)},
    C##m=Dm,
    C##*=D*,
    C##7=D\textsuperscript{7},
    C##7*=D7*,
    C##/F#=D/F#,
    C##/C#=D/C#,
    C##/C#*=D/C#*,
    C##/B=D/B,
    C##/B*=D/B*,
    Db#=D,
    D##m=Em,
    Ddim/E#=Ddim/F,
    D/Gb=D/F#,
    Eb#m=Em,
    Eb#m*=Em*,
    E#=F,
    E#*=F*,
    E#*=F*,
    E#/F##=F/G,
    E#m=Fm,
    F##=G,
    F##*=G*,
    F##7=G\textsuperscript{7},
    F##6=G6,
    F##maj7=G\textsuperscript{maj7},
    F##/A##*=G/B*,
    F##/B=G/B,
    F##/C##=G/D,
    F##/D=G/D,
    F##/E=G/E,
    F##/F#=G/F#,
    F##m/Bb=Gm/Bb,
    G##=A,
    G##/C#=A/C#,
    G##/E=A/E,
    G##/C##=A/D,
    G##*=A*,
    G##m=Am,
    G##m*=Am*,
    G##add9=A\textsuperscript{add9},
    G##maj7=A\textsuperscript{maj7},
    G##sus4=A\textsuperscript{sus4},
    G##7=A\textsuperscript{7},
    G##m7/C#=Am\textsuperscript{7}/D,
    G#b*=G*,
    G#b=G,
    G##m7=Am7,
    G##m7*=Am7*,
    Gb#=G,
    Eb#=E,
    Db#7/F#=D7/F#,
    A#=Bb,
    (F##)=(G),
    Cadd9=C\textsuperscript{add9},
    A7=A\textsuperscript{7},
    Am7=Am\textsuperscript{7},
    D7=D\textsuperscript{7},
    Bm7=Bm\textsuperscript{7},
    F##sus2=G\textsuperscript{sus2},
    B#maj7/F##=C\textsuperscript{maj7}/G,
    Dm/E#=Dm/F
  }

\cs_generate_variant:Nn \str_set:Nn {Nx}

\NewDocumentCommand \xchordname {m} {%
   \tl_if_head_eq_charcode:nNTF { !1 } .
    {
      \str_set:Nx \l_tmpa_str { \str_tail:n !1 }
      \prop_get:NVNTF \__skrul_enharmonic_map_prop \l_tmpa_str \__skrul_enharmonic_tl
        { \underline{\chordname{\__skrul_enharmonic_tl}}}
        { \underline{\chordname{\l_tmpa_str}}}
    }
    {
      \prop_get:NnNTF \__skrul_enharmonic_map_prop { !1 } \__skrul_enharmonic_tl
        { \chordname{\__skrul_enharmonic_tl}}
        { \chordname{!1}}
    }
}
\char_set_catcode_parameter:N \#
\char_set_catcode_other:N \!

\ExplSyntaxOff

\setleadsheets{
  title-template = leadsheet,
  align-chords=l,
  verse/numbered,
  chords/format = \color{black}\bfseries,
  chord-cs = \xchordname,
  verses-label-format = \itshape
}

\LeadsheetSurvive
\provideversetype{prechorus}[name=Prechorus]
\provideversetype*{prechorus*}[name=Prechorus]
\provideversetype{postchorus}[name=Postchorus]
\provideversetype*{postchorus*}[name=Postchorus]
\provideversetype{chorus1}[name=Chorus 1]
\provideversetype{chorus2}[name=Chorus 2]
\provideversetype{refrain}[name=Refrain]
\provideversetype{xbreak}[name=Break]

\providerobustcmd*\lsenparen[1]{%
  \expandcode{\noexpand\mklsenparen\mklsenparens{\unexpanded{#1}}}%
}
\providecommand*\mklsenparens{[]}
\providecommand*\mklsenparen[3]{\textup{#1}#3\textup{#2}}

\providerobustcmd*\instruction[1]{\lsenparen{\mkinstruction{#1}}}
\providecommand*\mkinstruction[1]{\emph{#1}}

\providerobustcmd*\choir[1]{\null\qquad\mkchoir{#1}}
\providecommand*\mkchoir[1]{\instruction{\leadsheetstranslate{choir}: #1}}
\LeadsheetEndSurvive
