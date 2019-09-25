\ProvidesClass{skrul-leadsheet}
\LoadClassWithOptions{scrartcl}

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

\setleadsheets{
  title-template = leadsheet,
  align-chords=l,
  verse/numbered,
  chords/format = \bfseries,
  verses-label-format = \itshape
}

\LeadsheetSurvive
\provideversetype{prechorus}[name=Prechorus]
\provideversetype*{prechorus*}[name=Prechorus]

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
