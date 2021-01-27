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

\definesongtitletemplate{leadsheet}{%
{\large \textbf{\songproperty{title}} - \songproperty{band}}
{\footnotesize
  \space\space // \space\space \songproperty{year}
  \space\space // \space\space key: \songproperty{key}
  \ifsongproperty{capo}{// \space\space\capo}{}
  \ifsongproperty{meter}{// \space\space\songproperty{meter} time}{}
}

\vspace{-0.5\baselineskip}
\hrulefill
}

\ExplSyntaxOn

\char_set_catcode_other:N \#
\char_set_catcode_parameter:N \!

\prop_const_from_keyval:Nn \__skrul_enharmonic_map_prop
  {
    B#=C,
    B#maj7=Cmaj7,
    B#m6=Cm6,
    Eb#m=Em,
    Eb#m*=Em*,
    E#=F,
    F##=G,
    F##/B=G/B,
    Am/F##=Am/G,
    Ab#m=Am,
    G#b*=G*,
    G#b=G,
    Eb#=E,
    Db#7/F#=D7/F#,
    A#=Bb
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
