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

\usepackage{tabularx}
\usepackage{xparse}
\usepackage{adjustbox}
\usepackage{amssymb}

\definesongproperty{bpm}
\definesongproperty{meter}
\definesongproperty{note}

\definesongtitletemplate{leadsheet}{%
\Large
{\textbf{\songproperty{title}} - \songproperty{band}}
{\footnotesize
  \space\space // \space\space \songproperty{bpm} bpm
  \space\space // \space\space key: \songproperty{key}
  \ifsongproperty{capo}{\space\space // \space\space\capo}{}
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
    Am/F##=Am/G,
    Ab#m=Am,
    A##m7=Bm7,
    B#=C,
    B#/B=C/B,
    B#*=C*,
    B#m=Cm,
    B#add9=Cadd9,
    Bb#=B,
    Bb#m7=Bm7,
    B#maj7=Cmaj7,
    B#m6=Cm6,
    C##=D,
    C##m=Dm,
    C##*=D*,
    C##7=D7,
    C##7*=D7*,
    C##/F#=D/F#,
    C##/C#=D/C#,
    C##/C#*=D/C#*,
    C##/B=D/B,
    C##/B*=D/B*,
    Db#=D,
    D##m=Em,
    D/Gb=D/F#,
    Eb#m=Em,
    Eb#m*=Em*,
    E#=F,
    E#*=F*,
    F##=G,
    F##*=G*,
    F##7=G7,
    F##/A##*=G/B*,
    F##/B=G/B,
    G##=A,
    G##*=A*,
    G##m=Am,
    G##m*=Am*,
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

\makeatletter
\newcommand\cellwidth{\TX@col@width}
\makeatother

\NewDocumentCommand \xb { m O{\space} }{{
\smash{%
 \raisebox{10pt}{%
    \begin{tabular}{@{}c}
      #2 \\
      \writechord{#1} \\
    \end{tabular}
   }
 }
}}

\NewDocumentCommand \xbb { m O{\space} m O{\space} }{{
\smash{%
  \raisebox{10pt}{%
    \begin{tabular}{@{}cc@{}}
      #2 & #4 \\
      \writechord{#1} & \writechord{#3} \\ \hline
    \end{tabular}
    }
  }
}}

\NewDocumentCommand \xbbbb { m o m o m o m o }{{
\begin{tabular}{@{}lll}
\IfNoValueTF{#2}{}{#2} & \IfNoValueTF{#4}{}{#4} & \IfNoValueTF{#6}{}{#6}  & \IfNoValueTF{#8}{}{#8}  \\[-1ex]
\writechord{#1} & \writechord{#3} & \writechord{#5} & \writechord{#7}  \\ \hline
\end{tabular}}
}

% Globally smashes the row height of all tabularx rows. However, this
% messes with the baseline of the first row so compensate for it later.
\setlength{\extrarowheight}{-1.5ex}

\NewDocumentCommand \chordtable { m }{{
\adjustbox{valign=t}{
  \begin{tabularx}{\textwidth}{XXXXXX}
    \\[0.4ex] % row height compensation
    #1
  \end{tabularx}
  }
  \vspace*{-4ex} % remote some extra padding on bottom?
  }}

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
\provideversetype{xbreak}[name=Break]
\provideversetype{v1}[name=V1]
\provideversetype{v2}[name=V2]
\provideversetype{v3}[name=V3]
\provideversetype{v4}[name=V4]
\provideversetype{c1}[name=C1]
\provideversetype{c2}[name=C2]
\provideversetype{c3}[name=C3]
\provideversetype{c4}[name=C4]
\provideversetype{c5}[name=C5]
\provideversetype{c6}[name=C6]


\provideversetype{b0}[name=B]
\provideversetype{b1}[name=B1]
\provideversetype{b2}[name=B2]
\provideversetype{b3}[name=B3]
\provideversetype{b4}[name=B4]

\provideversetype{s1}[name=S1]
\provideversetype{s2}[name=S2]

\provideversetype{i1}[name=I1]
\provideversetype{i2}[name=I2]


\provideversetype{intr}[name=In]
\provideversetype{out}[name=Out]
\provideversetype{s}[name=S]

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
