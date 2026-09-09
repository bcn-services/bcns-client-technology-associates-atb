"""Fill VERIFICATION.md placeholders from a downloaded verification-report artifact.
   python3 verify/fill_report.py <artifact-dir-win32> [<table-arm64.md>]
Replaces <!-- TABLE:win32 -->, <!-- RUNNER-INFO -->, <!-- TABLE:arm64 --> in place;
the placeholders are kept as HTML comments after the inserted block so the script can be re-run."""
import sys, os, re
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
art = sys.argv[1]; arm = sys.argv[2] if len(sys.argv) > 2 else None
p = os.path.join(root, 'VERIFICATION.md'); s = open(p).read()
def block(tag, body):
    global s
    pat = re.compile(r'<!-- ' + re.escape(tag) + r' -->.*?<!-- /' + re.escape(tag) + r' -->|<!-- ' + re.escape(tag) + r' -->', re.S)
    s = pat.sub(lambda m: f'<!-- {tag} -->\n{body.strip()}\n<!-- /{tag} -->', s, count=1)
block('TABLE:win32', open(os.path.join(art, 'table.md')).read())
ri = open(os.path.join(art, 'runner-info.txt')).read().strip()
tc = open(os.path.join(art, 'toolchain.txt')).read().strip() if os.path.exists(os.path.join(art, 'toolchain.txt')) else ''
block('RUNNER-INFO', "Runner used for this report:\n\n```\n" + ri + ("\n" + tc if tc else '') + "\n```")
if arm: block('TABLE:arm64', open(arm).read())
open(p, 'w').write(s); print('filled', p)
