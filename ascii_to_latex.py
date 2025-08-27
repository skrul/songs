#!/usr/bin/env python3
"""
Convert Ultimate Guitar ASCII chord charts to LaTeX leadsheet format.
This script takes chord lines and lyric lines and produces inline ^{chord} notation.
"""

def convert_ascii_to_latex(chord_line, lyric_line):
    """
    Convert ASCII chord positioning to LaTeX inline format.
    
    Args:
        chord_line (str): Line with chords positioned above lyrics
        lyric_line (str): Line with lyrics/words
    
    Returns:
        str: LaTeX formatted line with ^{chord} notation
    """
    if not chord_line.strip() or not lyric_line.strip():
        return lyric_line
    
    # Pad lines to same length
    max_len = max(len(chord_line), len(lyric_line))
    chord_line = chord_line.ljust(max_len)
    lyric_line = lyric_line.ljust(max_len)
    
    result = []
    i = 0
    
    # Find chords and their positions
    chord_positions = []
    current_chord = ""
    chord_start = -1
    
    for pos, char in enumerate(chord_line):
        if char not in [' ', '\t']:
            if chord_start == -1:
                chord_start = pos
            current_chord += char
        else:
            if current_chord:
                chord_positions.append((chord_start, current_chord))
                current_chord = ""
                chord_start = -1
    
    # Handle chord at end of line
    if current_chord:
        chord_positions.append((chord_start, current_chord))
    
    # Sort by position
    chord_positions.sort()
    
    # Insert chords into lyric line
    chord_idx = 0
    result_chars = []
    
    skip_char = False
    for pos, char in enumerate(lyric_line):
        # Check if we need to insert a chord here
        while chord_idx < len(chord_positions) and chord_positions[chord_idx][0] == pos:
            chord = chord_positions[chord_idx][1]
            
            # Determine if chord falls on a space (between words) or within/at start of word
            if char in [' ', '\t']:
                # Chord falls on a space between words - replace space with chord surrounded by spaces
                result_chars.append(f' ^{{{chord}}} ')
                skip_char = True  # Don't add the original space
            else:
                # Chord falls within a word or at beginning - no space after chord  
                result_chars.append(f'^{{{chord}}}')
            chord_idx += 1
        
        if not skip_char:
            result_chars.append(char)
        skip_char = False
    
    # Handle any remaining chords at the end
    while chord_idx < len(chord_positions):
        chord = chord_positions[chord_idx][1]
        result_chars.append(f' ^{{{chord}}}')
        chord_idx += 1
    
    return ''.join(result_chars).rstrip()

def process_section(lines):
    """
    Process a section of ASCII chart (alternating chord/lyric lines).
    
    Args:
        lines (list): List of lines from ASCII chart
    
    Returns:
        list: Converted LaTeX lines
    """
    result = []
    i = 0
    
    while i < len(lines):
        line = lines[i].rstrip()
        
        # Skip empty lines
        if not line:
            result.append("")
            i += 1
            continue
        
        # Check if next line exists and might be lyrics
        if i + 1 < len(lines):
            next_line = lines[i + 1].rstrip()
            
            # If current line has chords and next line has words
            if has_chords(line) and next_line and not has_chords(next_line):
                converted = convert_ascii_to_latex(line, next_line)
                result.append(converted)
                i += 2  # Skip both lines
                continue
        
        # Single line (might be lyrics only)
        result.append(line)
        i += 1
    
    return result

def has_chords(line):
    """
    Simple heuristic to detect if a line contains chords.
    """
    # Common chord patterns
    common_chords = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'Am', 'Bm', 'Cm', 'Dm', 'Em', 'Fm', 'Gm']
    words = line.split()
    
    # If line is mostly short uppercase words, likely chords
    chord_count = 0
    for word in words:
        if any(chord in word for chord in common_chords):
            chord_count += 1
    
    return chord_count > 0 and chord_count >= len(words) * 0.5

if __name__ == "__main__":
    # Example usage
    sample_chord_line = "Gm               Bb"
    sample_lyric_line = "   Slow down you crazy child"
    
    result = convert_ascii_to_latex(sample_chord_line, sample_lyric_line)
    print(f"Input chord line: '{sample_chord_line}'")
    print(f"Input lyric line: '{sample_lyric_line}'")
    print(f"Output: '{result}'")
    
    print("\nExample with complex positioning:")
    chord_line2 = "            Eb                      Bb"
    lyric_line2 = "But then if you're so smart tell me why"
    result2 = convert_ascii_to_latex(chord_line2, lyric_line2)
    print(f"Output: '{result2}'")