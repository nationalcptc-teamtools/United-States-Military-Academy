from pathlib import Path
root = Path(__file__).resolve().parents[1]
docs = root/'docs/proposals/development-functions'
for name in ('proposal.md','verification.md','review.md'):
    path = docs/name
    text = path.read_text(encoding='utf-8')
    text = text.replace('release-1.0.0/', 'release-1.0.0-settled/')
    text = text.replace('package-verification.json', 'package-verification-final.json')
    text = text.replace('68d95199a8ecd86a5a93d0f55579094c59ac2df8f45130b62242428902d552e5', 'fc2e71072a2d3becb5516ec35e3a1edc3bd7b656bffb49aa273f3a9a001c2550')
    text = text.replace('07a420f61f5c95e35dcd7aa14a549965604a79f1dcb6dbeffc6d964ed0252565', 'f212a923b3a90485199bedbe2bbe557a9d1f91ef436c0225bc762a92122d186c')
    text = text.replace('f11db91f33b3923ddc838ad988aa399131f572104b353bda991f82bf48a85b96', '69b457d76295e6e6e52fe68e58e5751a1ce75e795c1f4db68c28dc44961952a2')
    text = text.replace('1.212 s', '1.215 s')
    path.write_text(text,encoding='utf-8')
path = docs/'scope.md'
text = path.read_text(encoding='utf-8')
lines = text.splitlines()
for i,line in enumerate(lines):
    if line.startswith('| IDEA-DF-007 | Include |'):
        lines[i] = '| IDEA-DF-007 | Include | search/card lifecycle gap from existing catalog | test_catalog | Known archived OpenDNP3 and its old spacing alias resolve to the cataloged maintained-alternative gap; no accepted replacement or full retirement inventory is invented. |'
    if line.startswith('| IDEA-DF-060 | Include |'):
        lines[i] = '| IDEA-DF-060 | Include | Eight-field card readiness view | test_catalog | All43 cards separately label cataloged/downloaded/integrity/test/review/acceptance/publication/event states; unknowns stay explicit, license review differs from tool review, no promotion framework or approval inferred. |'
path.write_text('\n'.join(lines)+'\n',encoding='utf-8')
path = root/'tmp/workbench-final-check.py'
text = path.read_text(encoding='utf-8').replace('release-1.0.0/workbench','release-1.0.0-settled/workbench').replace('package-verification.json','package-verification-final.json')
text = text.replace('68d95199a8ecd86a5a93d0f55579094c59ac2df8f45130b62242428902d552e5','fc2e71072a2d3becb5516ec35e3a1edc3bd7b656bffb49aa273f3a9a001c2550')
text = text.replace("            identifier = cells[0]", "            if name == 'scope.md' and cells[1] not in ('Include','Defer','Exclude'):\n                continue\n            identifier = cells[0]")
path.write_text(text,encoding='utf-8')
print('Final paths/identities/scope wording updated')
