#!/usr/bin/env bash
# Existing CLAUDE.md must not be overwritten by init.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Pre-existing CLAUDE.md with user content
cat > "$TMPDIR/CLAUDE.md" <<'EOF'
# My Project

My custom rules here.
EOF

original_content=$(cat "$TMPDIR/CLAUDE.md")
mkdir -p "$TMPDIR/.protocol"

# The continuity block should be inserted, not replacing content
# Simulate the insert (between h1 and first paragraph)
python3 -c "
content = open('$TMPDIR/CLAUDE.md').read()
assert '<!-- continuity:start -->' not in content, 'Marker already present'
block = '''
<!-- continuity:start -->
Project lifecycle is managed through \`.protocol/\`.
<!-- continuity:end -->
'''
# Insert after first heading line
lines = content.split('\n')
out = []
inserted = False
for line in lines:
    out.append(line)
    if not inserted and line.startswith('# '):
        out.append(block)
        inserted = True
open('$TMPDIR/CLAUDE.md', 'w').write('\n'.join(out))
"

# Original content must still be present
grep -q "My custom rules here." "$TMPDIR/CLAUDE.md"
grep -q "<!-- continuity:start -->" "$TMPDIR/CLAUDE.md"
