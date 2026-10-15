import hashlib
import json
import zipfile
from pathlib import Path
root = Path(__file__).resolve().parents[1]
docs = root/'docs/proposals/farm-toolkit'
module = root/'tooling/farmkit'
pr = 'https://github.com/nationalcptc-teamtools/United-States-Military-Academy/pull/2'
sha = '7ccc0a6bbdc3e5488f18f046610f3a271221b81a'
archive = root/'output/farmkit/farmkit-1.1.0.zip'
with zipfile.ZipFile(archive) as z:
    manifest = z.read('MANIFEST.json')
    records = json.loads(manifest)['files']
    for name, record in records.items():
        content = z.read(name)
        assert content == (root/name).read_bytes()
        assert len(content) == record['size']
        assert hashlib.sha256(content).hexdigest() == record['sha256']
(archive.parent/'farmkit-1.1.0.manifest.json').write_bytes(manifest)
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(archive.parent/'farmkit-1.1.0.sha256').write_text(digest+'  farmkit-1.1.0.zip\n', encoding='utf-8')
summary = f'''

## Authorized suite installation and publication completed — 2026-10-15

Current result supersedes the preceding v1.0.0 no-installer/no-publication narrative. User explicitly requested all roles, commit/PR and an easy complete-suite installer, clarifying **assessment suite default, lab servers optional**. Root retained the editing slot; read-only architecture/provenance/review specialists supplied evidence without edits.

Published [PR #2]({pr}), open and non-draft, head `codex/farm-toolkit-suite` at `{sha}`, base `codex/report-generator` at `5fc9b7d3619daf6b491d692891d3f9511e34538c`. API independently verified exact head/base, open/unmerged state and all 28 changed public files; mergeable against that base at verification. Attached to this chat. No reporting source changes or private planning/customer/source originals/upstream payloads were published. Local integration worktree is clean after commit. No merge performed. GitHub connector create returned 403; existing authorized account's memory-only Git credential flow successfully created and verified the PR without printing or saving credentials.

Latest master `c2468f2af95bc96acc82ec0cb083725d33304aef` adds independent Linux/Windows runners and changes README cutoff to 19 October. Reporting branch advanced concurrently to5fc9b7d; root refreshed the unpublished farm branch base/index without changing protected reporting bytes. PR #1 remains open/draft and needs reconciliation with master before the stack can merge. Existing runners retain their own install/doctor/scope/operation behavior; no duplicate runner is added. The historical16OCT note is not the latest master policy. Actual event/SOW/start/timezone/official cutoff remains unresolved.

Implementation: root `install.sh` provides plan/full/core/check; separate fixed manifest installs apt clients, four isolated Python groups, source-pinned mbpoll/BACnet client/lib60870/libiec61850/Vulscan, ReportLab and SHA-256/size checked LinPEAS/WinPEAS assets with original notice. All forty candidates retain automated/optional/lab/held dispositions. Windows payloads are staged only. Prowler and legacy wkhtmltopdf are optional; lab servers/sensors/hardware are separately documented. No assessment program, payload, updater, target operation or server was launched by setup.

Actual tests: Windows Python3.12.14 **39 tests,38pass,1native-symlink privilege skip**; exact public Kali Python3.14.7 **39pass** including symlinks, root shell syntax/preview and metadata validation. Initial clean Kali image `sha256:02f5d6c019e549b0f55da58e835cad5355ef1030c6b2645265a324e37dfc4acc` installed prerequisites/Python groups, then BACnet compile failed due upstream routing default. Root disabled routing and resumed successfully. Exact final manifest full same-prefix rerun with **network none + PIP_NO_INDEX=1 + skip-system passed**. It is not a second pristine install or fresh offline dependency closure. Final state binds manifest SHA`b7ee1aaf35391ce8468acf28741b3614972287cd4b35a7ee84894aed6f9dfe24`.

Thirteen disconnected installed-state cases passed: original/restored state accepted; missing apt/native/Python inventory, removed native client/library/Vulscan link/venv config, altered payload, dirty source and absent dpkg installed status rejected; redirected bin refused before command execution. Local evidence: [inventory](../../../tmp/farm-installed-state-final.json), [installation log](../../../tmp/farm-kali-exact-final.log), [synthetic regression procedure](../../../tmp/farm_install_smoke.py). These are local test evidence, not public contents.

Independent review found/resolved **R-FT-04 incomplete required inventory** and **R-FT-05 redirected writes/invalid venv global pip risk**. Reviewer independently repeated reproductions, passive-plan prohibitions,20read-only checker tests,4installer test bodies,90public links/fragments, staged privacy/allowlist checks and exact manifest/state binding. Positive scoped verdict, no actionable findings; root's full environment tests are attributed separately. Git autocrlf fixture and evidence-byte mismatch detected during verification were corrected; LF rules preserve exact hashed fixture/manifest bytes. Final install.py SHA`adc09bc31db62d03ae2b87f0a6988870e1a4d44795a7b0a341cb434cfacf757c`.

Delivery artifacts: [public installation guide](../../../tooling/farmkit/INSTALL.md), [public proposal](../../../tooling/farmkit/proposal.md), [spec](../../../tooling/farmkit/spec.md), [design](../../../tooling/farmkit/design.md), [verification](../../../tooling/farmkit/VERIFICATION.md), [source-only ZIP](../../../output/farmkit/farmkit-1.1.0.zip), [manifest](../../../output/farmkit/farmkit-1.1.0.manifest.json), [checksum](../../../output/farmkit/farmkit-1.1.0.sha256). ZIP has23allowlisted files plus internal manifest, {archive.stat().st_size:,}bytes, SHA`{digest}`; all members/hashes match current module. Historicalv1.0.0ZIP/manifest remain preserved.

T-FT-10–14 and FR-FT-013/014 are complete for the requested reviewed installation/public contribution. Full original operational acceptance/T-FT-09, Windows execution, protocol/PCAP/traffic/hardware rehearsals, resource measurements, immutable dependency/distro/build/license closure and event staging/eligible student/SOW/freeze approval remain explicit gates. Readiness ledger is not automatically promoted. Proposal/workflow delivery is complete; requester acceptance, merger and operational/event decisions are separate.
'''
for name in ('proposal.md','spec.md','verification.md'):
    with (docs/name).open('a',encoding='utf-8',newline='\n') as h:
        h.write(summary)
p = docs/'proposal.md'
text = p.read_text(encoding='utf-8').replace('Active role: Delivery Lead, completed local role-cycle handoff', 'Active role: Delivery Lead, reviewed public contribution delivered')
text = text.replace('Status: **local preparation package implemented, verified and independently reviewed; full runtime/event acceptance pending**', 'Status: **assessment installer implemented, tested, independently reviewed, committed and published as PR #2; operational/event acceptance pending**')
text = text.replace('## Original request', 'Current delivery: [PR #2]('+pr+'), commit `7ccc0a6`, [installer/verification addendum](#authorized-suite-installation-and-publication-completed--2026-10-15). Earlier v1.0.0 narratives below are historical and superseded by that addendum.\n\n## Original request',1)
p.write_text(text,encoding='utf-8',newline='\n')
p=docs/'tasks.md'
text=p.read_text(encoding='utf-8')
rows=[]
for line in text.splitlines():
    if any(line.startswith('| T-FT-'+str(i)+' ') for i in range(11,15)):
        line=line.rsplit('|',2)[0]+'| Complete; see final verification/publication addendum |'
    rows.append(line)
p.write_text('\n'.join(rows)+'\n',encoding='utf-8',newline='\n')
with p.open('a',encoding='utf-8',newline='\n') as h:
    h.write('\nPublication verified: [PR #2]('+pr+'), commit `'+sha+'`; T-FT-09 remains external.\n')
with (docs/'review.md').open('a',encoding='utf-8',newline='\n') as h:
    h.write('\n## Installer/publication review extension — 2026-10-15\n\nIndependent read-only `/root/validation_review` returned a positive scoped verdict with no remaining actionable findings. R-FT-04/05 resolved and independently rechecked; exact state/manifest binding confirmed. Independently passed20read-only checker and4installer test bodies, passive-plan prohibitions,90links, public privacy/28-file allowlist and checked Git newline handling. Root executed full Windows/Kali and13disconnected cases; reviewer inspected logs/procedure rather than rerunning installation. Original R-FT-01–03 remain resolved. Acceptance limits and exact code/manifest hashes are in the final verification addendum and public VERIFICATION.md. Publication verified as [PR #2]('+pr+'), no merge.\n')
with (root/'docs/journal.md').open('a',encoding='utf-8',newline='\n') as h:
    h.write('\n## 2026-10-15 — Farm assessment suite installed, reviewed and published\n'+summary.split('## Authorized suite installation and publication completed — 2026-10-15',1)[1])
print(json.dumps({'zip_bytes':archive.stat().st_size,'zip_sha256':digest,'members':len(records),'pr':pr,'commit':sha}))
