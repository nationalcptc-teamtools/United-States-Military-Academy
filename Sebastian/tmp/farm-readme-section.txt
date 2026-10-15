# Installation Script (install.sh)

Install the supported assessment suite on Kali Linux x86-64. Setup acquires packages during preparation; the installed workstation can then be checked without Internet. Lab servers are optional and separately documented.

```sh
git clone https://github.com/nationalcptc-teamtools/United-States-Military-Academy.git
cd United-States-Military-Academy
bash install.sh --plan
bash install.sh --profile full
source .cptc-suite/activate
bash install.sh --check --profile full
```

Includes protocol/IT clients, isolated Python libraries, source-built OT clients/SDKs, reporting dependencies and hash-checked LinPEAS/WinPEAS downloads. Setup never runs payloads, assessment tools or lab servers. Use `--profile core` for the smaller selected-protocol profile; Prowler and legacy wkhtmltopdf are explicit options. All forty candidates have installation or held/lab dispositions.

Read [installation and offline-use guidance](tooling/farmkit/INSTALL.md), [the catalog](tooling/farmkit/CATALOG.md) and [actual checks and limitations](tooling/farmkit/VERIFICATION.md). No full offline reinstallation cache or operational/event approval is claimed. The [proposal/spec/design](tooling/farmkit/proposal.md) record requirements, source evidence and unresolved gates. Existing scanner/configuration behavior is preserved; its general Nmap defaults are not approved OT profiles.

