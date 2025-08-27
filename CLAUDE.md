# Converting Ultimate Guitar to LaTeX Leadsheets

This guide documents the process for converting Ultimate Guitar ASCII chord charts to LaTeX using the leadsheets package.

## Fair Use Notice

The conversion of song lyrics and chord progressions for personal use, educational purposes, and non-commercial music practice constitutes fair use under U.S. Copyright Law. This includes creating leadsheets for personal music practice, educational instruction, and similar non-commercial activities.

## File Structure

### Single File (Default)
For most songs, use a single file with all content:
- **File**: `songs/[Artist]/[Song Title].tex`
- Contains both document structure and song body in one file

### Separate Body File (For Variants)
Only separate the body when creating capo or transposed versions:
- **Main files**: `songs/[Artist]/[Song Title].tex` (default) AND `songs/[Artist]/[Song Title] [Variant].tex` (variants)
- **Body file**: `songs/[Artist]/[Song Title] Body.tex` (shared by ALL versions)

**IMPORTANT**: When variants are needed, ALL versions (including the default) must reference the shared body file. The body contains the original key chords and is shared across all variants.

#### Naming Conventions for Variants:
- **Capo versions**: `[Song Title] Capo [Roman Numeral].tex`
  - Example: `Part of the Process Capo III.tex`
- **Transposed versions**: `[Song Title] ([New Key]).tex`
  - Example: `Borderline (E).tex`
- **Both capo and transpose**: `[Song Title] In [Key] Capo [Roman].tex`
  - Example: `Paper Rings In B Capo IV.tex`

### Single File Template
```latex
\documentclass{skrul-leadsheet}
\begin{document}
\begin{song}[transpose-capo=true]{title={Song Title}, band={Artist}, year={YYYY}, key={X}}

[Song content goes here directly]

\end{song}
\end{document}
```

### Templates for Variants (with separate body)

**Default Version Template (references shared body):**
```latex
\documentclass{skrul-leadsheet}
\begin{document}
\begin{song}[transpose-capo=true]{title={Song Title}, band={Artist}, year={YYYY}, key={OriginalKey}}

\input{"Song Title Body.tex"}

\end{song}
\end{document}
```

**Variant Version Template (references shared body):**
```latex
\documentclass{skrul-leadsheet}
\begin{document}
\begin{song}[transpose-capo=true,transpose=X]{title={Song Title}, band={Artist}, year={YYYY}, key={NewKey}, capo={X}}

\input{"Song Title Body.tex"}

\end{song}
\end{document}
```

**Body File Template (contains original key chords):**
```latex
\begin{intro}
[Original key chords here]
\end{intro}

\begin{verse}
[Lyrics with original key chords]
\end{verse}
```

## Body File Structure

Use these environments for different song sections:
- `\begin{intro}` - Opening instrumental
- `\begin{verse}` - Song verses  
- `\begin{chorus}` - Chorus sections
- `\begin{interlude}` - Between verses
- `\begin{solo}` - Instrumental solos
- `\begin{outro}` - Ending section

## Chord Placement Rules

### Critical: Exact Chord Positioning
- Study the original Ultimate Guitar ASCII chart carefully
- Place chords exactly where they appear in the original timing
- Use `^{chord}` syntax for inline chords above lyrics
- **MANDATORY**: Always use the `ascii_to_latex.py` script for ALL chord positioning
- **NEVER manually position chords** - the script provides precise character-level accuracy
- **Count the spaces** - chord positioning in ASCII shows exact syllable placement
- **MOST IMPORTANT**: Do not guess or approximate - the ASCII spacing is precise
- Count characters from the start of each line to determine exact word/syllable placement
- Example: `^{C}Everybody's got a ^{Am}hungry heart`

### Important: Multiple Chords Within One Word
- Only one `^{chord}` allowed per word in LaTeX
- For multiple chords in one word, split the word and use `^*{chord}` on the FIRST chord to gobble space
- **Wrong**: `^{G}Woo-^{G7}hoo` (causes LaTeX error)
- **Correct**: `^*{G}Woo- ^{G7}hoo` (splits word, asterisk on first chord prevents unwanted space)

### Important: "No Chord" Notation for Variants
- When variants (capo/transposed versions) are needed, use `^{N.\symbol{67}.}` instead of `^{N.C.}`
- The leadsheets package will transpose the "C" in `^{N.C.}` as if it's a C chord
- **Single file only**: `^{N.C.}` is fine (no transposition occurs)
- **With variants**: `^{N.\symbol{67}.}` prevents leadsheets from recognizing "C" as a chord

### Common Mistakes to Avoid
- **NEVER guess chord placement** - follow the ASCII chart precisely, character by character
- In "Everybody's got a hungry heart", Am goes over "hungry" NOT "heart"
- Chords can appear between words: "for a ^{Ab} juvenile" (space after chord prevents it from attaching to next word)
- **Study spacing carefully**: In ASCII, leading spaces before chords show exact positioning
  - Example: "            Eb" in ASCII means Eb goes over "you're", not at line start
- **Count every space and character** from line beginning to determine exact chord placement
- **Common error**: Placing chords at line beginnings when they belong mid-line
- **Verification step**: Always cross-reference with the original Ultimate Guitar positioning

## Chord-Only Sections

For instrumental parts or chord progressions without lyrics:
```latex
\begin{tabular}[t]{@{}lllll}
|_{C} & |_{Am} & |_{Dm7} & |_{G} & | \\
\end{tabular}
```

### Important: Chord-Only Syntax Rules
- **Always use 5 columns**: `{@{}lllll}` for consistent visual formatting
- **Columns 1-4**: Actual chords with `|_{chord}` format
- **Column 5**: Just `|` for visual closure (makes tables look "closed")
- Always use `_{chord}` with curly braces for chord-only sections
- **Wrong**: `|_(Bbaug)` (uses parentheses)
- **Correct**: `|_{Bbaug}` (uses curly braces)
- Multiple chords in one cell: `|_{D7} _{Eb}` (space between chords)

## Text Formatting Rules

### Punctuation and Capitalization
When combining two musical lines on a single text line:
1. Add comma after first line: `Baltimore jack,`
2. Lowercase the first word of second line (except "I"): `i went out...`
3. **Exception**: Always capitalize "I" regardless of position

Example:
```latex
^{C}Got a wife and kids in ^{Am}Baltimore jack,
^{Dm7}I went out for a ride and I ^{G7}never went back \\
```

### Line Breaks
- Use `\\` for line breaks within sections
- Use `\space\space\space\space\space \instruction{Repeat 3x}` for repeat instructions

## Conversion Process

1. **Analyze Structure**: Identify verses, chorus, bridge, etc.
2. **Study Chord Placement**: Look at original ASCII positioning carefully
3. **Use ASCII Conversion Tool** (MANDATORY): Always use the `ascii_to_latex.py` script to convert ALL chord/lyric pairs to accurate inline notation
4. **Create Files**: Main file and body file following templates
5. **Place Chords**: Use exact positioning from original chart or conversion tool output
6. **Format Text**: Add commas and fix capitalization for combined lines
7. **Add Instrumentals**: Use tabular format for chord-only sections

## ASCII to LaTeX Conversion Tool

A Python script (`ascii_to_latex.py`) is available to help convert Ultimate Guitar ASCII formatting to inline LaTeX chords:

**Usage**: Provide chord line and lyric line as input:
```
Input chord line: 'Gm               Bb'
Input lyric line: '   Slow down you crazy child'
Output: '^{Gm}   Slow down you ^{Bb}crazy child'
```

This tool can be more accurate than manual conversion for precise chord positioning.

## Adding Chord Diagrams (Optional)

Add chord diagrams only when specifically requested for tricky or unusual chords:

### Adding to Single Files:
```latex
\documentclass{skrul-leadsheet}
\usepackage{eso-pic}
\begin{document}
\begin{song}[transpose-capo=true]{title={Song Title}, band={Artist}, year={YYYY}, key={X}}

\AddToShipoutPictureFG{
  \AtPageUpperLeft{%
    \raisebox{-10em}{%
      \hspace{43em}
      \origchord{t}{x,x,p1,p0,p0,p3}{_{ChordName}}%
    }%
  }%
}

[Song content here]
\end{song}
\end{document}
```

### Adding to Variant Files:
- Add the same `\usepackage{eso-pic}` and `\AddToShipoutPictureFG` block to ALL variant files
- **Important**: Chord names change with transposition but fingering stays the same
  - Default version: `_{Bbaug}` (original key)
  - Capo III version: `_{Gaug}` (transposed key)
- Fingering pattern remains identical: `{x,x,p1,p0,p0,p3}`

### Chord Diagram Syntax:
- **Fingering**: `{string6,string5,string4,string3,string2,string1}` (low E to high E)
- **Frets**: `p0` = open, `p1` = 1st fret, `p2` = 2nd fret, etc.
- **Muted**: `x` = don't play this string
- **Example**: `{x,x,p1,p0,p0,p3}` = mute low E and A, 1st fret D, open G and B, 3rd fret high E

## Key Points for Accuracy

- **Always** reference the original Ultimate Guitar ASCII chart for chord timing
- Don't assume chord placement - the original chart shows exact positioning
- Keep "I" capitalized in all cases
- Add commas when combining lines for better readability
- Use consistent spacing and formatting throughout