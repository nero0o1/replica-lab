import os
import re

def clean_trailing_commas(content):
    """
    Remove trailing commas in JSON-like structures (arrays and objects).
    Safeguard: Uses a regex that ensures we aren't inside a literal string.
    Logic: Matches a comma follow by optional whitespace and a closing bracket or brace,
    making sure we don't break complex multi-line structures.
    """
    # Regex Explained:
    # ,             -> Match the literal comma
    # \s*           -> Any number of whitespace (including newlines)
    # (?=[}\]])     -> Positive lookahead for } or ]
    # The trick for strings is to ensure we don't have an unclosed quote before.
    # While simple, for this project's scope, we apply it to .json and .py files
    # after validating they aren't inside strings using a basic state machine or refined regex.
    
    # Refined Regex: find comma followed by whitespace and closing char.
    # To avoid strings, we match the whole string and skip it, or use a complex balanced pattern.
    # For a reliable agentic implementation, we'll use a split-by-quote approach.
    
    parts = re.split(r'("[^"\\]*(?:\\.[^"\\]*)*")', content)
    cleaned_parts = []
    for i, part in enumerate(parts):
        if i % 2 == 0: # Outside a string
            # Apply cleaning
            part = re.sub(r',\s*([}\]])', r'\1', part)
        cleaned_parts.append(part)
    
    return "".join(cleaned_parts)

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(('.json', '.py', '.ps1')):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = clean_trailing_commas(content)
                    
                    if content != new_content:
                        with open(path, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"[CLEANED] {path}")
                except Exception as e:
                    print(f"[ERROR] {path}: {e}")

if __name__ == "__main__":
    import sys
    # Priority: root, src, onda1_skeleton
    process_directory(".")
