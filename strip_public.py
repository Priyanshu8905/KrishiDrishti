# strip_public.py
# Python script to clean up compilation issues by stripping unnecessary "public" access modifiers within the single-module app target

import os
import re

directories = [
    "/Users/kaushikirai/Desktop/KrishiDrishti/KrishiDrishti_fixed 3/KrishiDrishti"
]

# We want to replace occurrences of 'public ' with '' for declarations, keeping it clean
# Target constructs:
# 'public class ', 'public final class ', 'public protocol ', 'public struct ', 'public enum ', 'public init', 'public func ', 'public var ', 'public private(set) var ', 'public private(set) let ', 'public let '
# Also 'public static let ', 'public static var '

replacements = [
    (r'\bpublic\s+class\b', 'class'),
    (r'\bpublic\s+final\s+class\b', 'final class'),
    (r'\bpublic\s+protocol\b', 'protocol'),
    (r'\bpublic\s+struct\b', 'struct'),
    (r'\bpublic\s+enum\b', 'enum'),
    (r'\bpublic\s+init\b', 'init'),
    (r'\bpublic\s+func\b', 'func'),
    (r'\bpublic\s+var\b', 'var'),
    (r'\bpublic\s+let\b', 'let'),
    (r'\bpublic\s+static\s+let\b', 'static let'),
    (r'\bpublic\s+static\s+var\b', 'static var'),
    (r'\bpublic\s+private\(set\)\s+var\b', 'private(set) var')
]

for directory in directories:
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    text = f.read()
                
                modified_text = text
                for pattern, replacement in replacements:
                    modified_text = re.sub(pattern, replacement, modified_text)
                
                if modified_text != text:
                    with open(filepath, 'w') as f:
                        f.write(modified_text)
                    print(f"Cleaned modifiers in: {file}")

print("Modifier cleanup complete.")
