\ProvidesClass{skrul-leadsheet}
\LoadClassWithOptions{scrartcl}

\RequirePackage{leadsheets}

\RequirePackage{etoolbox}
\RequirePackage{translations}
\RequirePackage{xstring}

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

\bool_new:N \l__skrul_underline_boo
\tl_new:N \l__skrul_stripped_tl
\str_new:N \l__skrul_stripped_str

\NewDocumentCommand \xchordname {m} {%
  % \tl_if_head_eq_catcode:nNTF { !1 } .
  %   { \bool_set_true:N \l__skrul_underline_bool }
  %   { \bool_set_false:N \l__skrul_underline_bool }

  % \bool_if:NTF \l__skrul_underline_bool
  %   { \tl_set:Nn \l__skrul_stripped_tl { \tl_tail:n { !1 } } }
  %   { \tl_set:Nn \l__skrul_stripped_tl { !1 } }

  %  \bool_if:NTF \l__skrul_underline_bool
  %   { \str_set:Nn \l__skrul_stripped_str { !1 } }
  %   { \str_set:Nn \l__skrul_stripped_str { !1 } }

   \tl_set:Nn \l__skrul_stripped_tl { !1 }

   \tl_set:Nf \l_mya_tl { \l__skrul_stripped_tl }

   \chordname  \l_mya_tl
   % \str_case:nnTF \l__skrul_stripped_tl
   %   {
   %     % Enharmonics
   %     {B#}  {\chordname{C}}
   %     {E#}  {\chordname{F}}
   %     {F##} {\chordname{G}}
   %     {F##/B} {\chordname{G/B}}
   %     {Am/F##} {\chordname{Am/G}}
   %   }
   %   {}
   %   {\chordname{ \l__skrul_stripped_tl }}
}
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
