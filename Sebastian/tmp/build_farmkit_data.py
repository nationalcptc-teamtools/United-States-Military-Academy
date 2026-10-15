import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
dest = root / "tooling/farmkit"
selected = {3, 13, 14, 17, 18, 20, 23, 24}
held = {1, 2, 9, 12, 19, 22, 28}
labs = {21, 35, 36, 37, 38, 39, 40}
protocols = {
1: ["linux-host"], 2: ["windows-host"], 3: ["packet-analysis"],
4: ["packet-analysis"], 5: ["packet-analysis"], 6: ["packet-analysis"],
7: ["smb"], 8: ["smb", "ldap"], 9: ["smb", "msrpc", "kerberos"],
10: ["tls"], 11: ["http"], 12: ["module-specific"],
13: ["modbus-tcp", "modbus-rtu"], 14: ["modbus-tcp", "modbus-rtu"],
15: ["modbus-tcp", "modbus-rtu"], 16: ["modbus-rtu", "modbus-ascii"],
17: ["s7"], 18: ["cip"], 19: ["cip"], 20: ["opcua"], 21: ["opcua"],
22: ["bacnet-ip"], 23: ["bacnet-ip", "bacnet-mstp"], 24: ["mqtt"], 25: ["mqtt"],
26: ["iec60870-101", "iec60870-104"], 27: ["iec61850"], 28: ["dnp3"], 29: ["dlms-cosem"],
30: ["can", "j1939", "isobus-partial"], 31: ["can"], 32: ["can"], 33: ["canopen"],
34: ["mavlink"], 35: ["lorawan"], 36: ["zigbee"], 37: ["plc-lab"],
38: ["scada-lab"], 39: ["telemetry-lab"], 40: ["ics-lab"]}

def plain(text):
    return re.sub(r"\[([^]]+)\]\([^)]+\)", r"\1", text).replace("**", "").replace("`", "")

def write(name, value):
    (dest/name).parent.mkdir(parents=True, exist_ok=True)
    (dest/name).write_text(json.dumps(value, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")

tools = []
for row in (root/"docs/proposals/farm-toolkit/tool-catalog.md").read_text(encoding="utf-8").splitlines():
    if not re.match(r"\| TOOL-\d{3} \[", row):
        continue
    cells = [s.strip() for s in row.strip("|").split("|")]
    match = re.match(r"(TOOL-\d{3}) \[([^]]+)\]\(([^)]+)\)", cells[0])
    tid, name, upstream = match.groups()
    n = int(tid[-3:])
    disposition = "selected" if n in selected else "hold" if n in held else "lab" if n in labs else "conditional"
    priority = next((p for p in ("P0", "P1", "P2") if p in cells[1]), "P2")
    runtime, operation = plain(cells[3]), plain(cells[4])
    anchor = "host-enumeration" if n in (1,2,7,8,9,12) else "offline-pcap" if n in (3,4,5,6) else "modbus" if n in (13,14,15,16) else "s7" if n == 17 else "cip" if n in (18,19) else "opc-ua" if n in (20,21) else "bacnet" if n in (22,23) else "mqtt" if n in (24,25) else "lab-and-conditional"
    operations = list(dict.fromkeys(re.findall(r"\b[OPAHWL]\b", operation.split(";")[0])))
    rationale = "Initial primary-protocol evaluation route; not acquired or runtime accepted." if n in selected else "Optional lab/reference system; do not install in an engagement network." if n in labs else "Held for the license/module/maintenance issue below; no default staging." if n in held else "Use only when authorized technology evidence justifies this capability; avoid redundant dependencies."
    evidence = list(dict.fromkeys(re.findall(r"\]\((https://[^)]+)\)", cells[5]))) or [upstream]
    if n == 37:
        evidence = ["https://github.com/Autonomy-Logic/openplc-runtime/blob/main/LICENSE"]
    needs_hardware = "Conditional adapter/driver and physical-access approval; use synthetic files/virtual bus first." if n in (16,30,31,32,33,34,35,36) else "None for offline metadata; real capture/serial interfaces need separate permission and hardware."
    tools.append({"id": tid, "name": name, "upstream": upstream, "priority": priority,
      "disposition": disposition, "rationale": rationale, "purpose": plain(cells[2]), "runtime": runtime,
      "operations": operations, "outputs": [operation.split(";",1)[1].strip() if ";" in operation else "Tool/profile-specific; select exact format before integration."],
      "license": {"summary": plain(cells[5]), "evidence": evidence, "review": "hold" if n in (1,2,9,22) else "pending"},
      "maintenance": {"state": "inactive" if n==19 else "archived" if n==28 else "unassessed",
        "notes": "Explicit inactive/archived upstream warning; fallback owner needed." if n in (19,28) else "Upstream declaration reviewed; no independent security/dependency audit or maintenance assurance."},
      "protocols": protocols[n], "needs": {"dependencies": runtime, "privileges": "Least privilege; exact selected-release and operation requirements remain to be verified. Do not disable endpoint controls.", "hardware": needs_hardware},
      "limitations": [plain(cells[5]), "Scenario is hypothetical; tool capability does not establish customer technology, vulnerability or permission."],
      "owner": "Eligible student maintainer (unassigned)", "checked_at": "2026-10-15", "runbook": "RUNBOOKS.md#"+anchor,
      "acquisition_status": "not_acquired", "runtime_status": "not_run", "runtime_evidence": None})

write("catalog.json", {"schema_version": "cptc.farm-catalog/1.0", "checked_at": "2026-10-15",
 "context": {"platforms": ["Kali/Linux x86-64 (provisional)", "Windows x64 payloads (provisional)"], "asset_knowledge": "unknown", "scenario_status": "hypotheses"}, "tools": tools})

records = [
("PEASS",[1,2],"peass-ng/PEASS-ng","20261015-c468195d","652ba220e4115a8e7e2c9622c66cd88fdf3b81a6",["LICENSE"],"GPL-2-or-later with custom clarifications; hold intended distribution/result-parsing review.","Choose exact LinPEAS/WinPEAS asset and variant; third-party components and Windows runtime remain separate."),
("TSHARK",[3],"wireshark/wireshark","v4.6.9","2d548b197c7582332f143c15259e1650aff7cc26",["COPYING","epan/packet.h"],"GPL-2.0-or-later source declarations; component notices separate.","Official stable source candidate; Linux package dependencies/build inputs not closed. Windows Npcap terms separate; not selected for mirroring."),
("PYMODBUS",[13],"pymodbus-dev/pymodbus","v3.16.1","804ae510d400e7690d86c8a1f648fa3f6c940330",["LICENSE","pyproject.toml"],"BSD-3-Clause upstream declaration.","Python >=3.10; serial/simulator extras and build toolchain require their own pins."),
("MBPOLL",[14],"epsilonrt/mbpoll","v1.5.4","d541211d0e2451888de11c82fb1604c3d6285b1a",["COPYING","README.md"],"GPL-3 family; retain selected artifact notices.","This release uses libmodbus >=3.1.7; libmodbuspp belongs to v2 development, not this release."),
("SNAP7",[17],"gijzelaerr/python-snap7","3.2.1","28bb2c89bde92795af76e61ecc201cf61c0f42b1",["LICENSE","pyproject.toml"],"MIT upstream declaration.","Pure Python >=3.10; no mandatory runtime dependencies declared. CLI/discovery/PPI extras separate. No full hardware test suite against targets."),
("CPPPO",[18],"pjkundert/cpppo","v5.2.5","f7c224bbb2389bd26d0088eeb1a93db3a5c4858f",["LICENSE","requirements.txt"],"GPL-3 with stated protocol exception; alternative license not selected.","Requires crypto_licensing >=4.2.0 and greenery >=2.0,<3.0; lock/review dependencies and prove offline operation before staging."),
("ASYNCUA",[20],"FreeOpcUa/opcua-asyncio","v2.1.0","a5a3ce0f6c012e8b09d3e9a948e25a64b2e29b37",["COPYING","pyproject.toml"],"LGPL-3.0-or-later upstream declaration.","Python >=3.10; cryptography >=45 and other dependencies/build wheels not acquired; exclude write/method CLI operations."),
("BACNET",[23],"bacnet-stack/bacnet-stack","bacnet-stack-1.6.1","7a53f0a72a92de1621d30fc63703a29afe12bfaf",["README.md","apps/readprop/main.c"],"GPL-2.0-or-later WITH GCC-exception-2.0 core; MIT/Apache examples per file.","Select compiled app/core and generate per-file notices. Verify explicit unicast binding; CLI name alone does not rule out discovery."),
("MQTT",[24],"eclipse-mosquitto/mosquitto","v2.1.2","99fa50f30e325609394c324c8ff71cfbbe95d8ab",["LICENSE.txt"],"EPL-2.0 OR BSD-3-Clause upstream declaration.","Select client dependencies, TLS and notices; broker lab-only. Source bytes/signature not retrieved or verified.")]
projects=[]
for name, numbers, repo, release, commit, licenses, license_summary, notes in records:
    base="https://github.com/"+repo
    projects.append({"id":"SRC-"+name,"tool_ids":[f"TOOL-{n:03d}" for n in numbers], "repository":base,"release":release,"commit":commit,
      "archive_candidate":base+"/archive/"+commit+".tar.gz", "license_evidence":[base+"/blob/"+commit+"/"+p for p in licenses],
      "license_summary":license_summary,"dependency_notes":notes,"acquisition_status":"not_acquired","sha256":None})
write("sources.json", {"schema_version":"cptc.source-references/1.0","checked_at":"2026-10-15","projects":projects})
write("artifact-lock.json", {"schema_version":"cptc.artifact-lock/1.0","data_category":"upstream","artifacts":[]})

gates=[
("OD-FT-01","pending","Captain/officials","Actual event/date/timezone and SOW/ROE unknown; October 2025 is the rulebook baseline.",[]),
("OD-FT-02","partial","Captain/student maintainer","Contribution access exists for earlier reporting work; this package publication, event assignment and frozen revision remain pending.",[]),
("OD-FT-03","pending","Runtime owner","Exact Linux/Windows/Python/.NET image, privileges and resource capacity unknown.",[]),
("OD-FT-04","pending","Maintainer/officials","Approved public acquisition/staging route and source/binary/cache format need a decision.",[]),
("OD-FT-05","pending","Maintainer/license reviewer","Custom/mixed license and component obligations require selected-artifact review; held tools remain held.",[]),
("OD-FT-06","pending","Engagement lead/customer/officials","No protocols, vendors, target endpoints or acceptable OT operations confirmed.",[]),
("OD-FT-07","pending","Team lab owner","Facilities, simulator choice and rehearsal ownership pending.",[]),
("OD-FT-08","recorded","Local preparation design","Eight primary evaluation candidates chosen; no reporting adapters or mandatory redundant stacks.",["CATALOG.md","RUNBOOKS.md"])]
write("readiness.json", {"schema_version":"cptc.readiness/1.0", "gates":[dict(zip(["id","state","owner","detail","evidence"],g)) for g in gates],
 "rehearsals":[{"id":r,"state":"pending","owner":"Team runtime/lab owner (unassigned)","detail":"Not run on the agreed selected-version environment; synthetic integrity-helper checks are not this rehearsal.","evidence":[]} for r in ["clean-kali","linux-host","windows-host","offline-pcap","modbus","s7","cip","opcua","bacnet","mqtt","resources"]]})

fixture=dest/"examples/artifacts/fixture.txt"
fixture.parent.mkdir(parents=True,exist_ok=True)
fixture.write_bytes(b"SYNTHETIC preparation integrity fixture.\nNo upstream software.\n")
write("examples/synthetic-lock.json", {"schema_version":"cptc.artifact-lock/1.0","data_category":"synthetic","artifacts":[{
 "id":"SYNTHETIC-ARTIFACT-001","tool_ids":[],"version":"synthetic-1.0","source_commit":"0"*40,
 "origin":"https://example.invalid/synthetic/fixture.txt","path":"fixture.txt","size":fixture.stat().st_size,
 "sha256":hashlib.sha256(fixture.read_bytes()).hexdigest(),"platform":"synthetic","architecture":"none",
 "license":"Team-authored synthetic fixture","license_review":"synthetic-only","dependencies":[],"dependency_review":"reviewed",
 "smoke_check":"Integrity-helper fixture only; not an upstream tool smoke test."}]})

lines=["# Tool selection catalog", "", "Generated from catalog.json; checked 2026-10-15. Selected means selected for evaluation. No upstream tool is acquired or runtime verified. Farm scenarios are hypotheses.", "", "## Selection", "", "| Tool | Disposition | Protocols | Purpose |", "| --- | --- | --- | --- |"]
for t in tools:
    lines.append(f"| {t['id']} [{t['name']}]({t['upstream']}) | {t['disposition']} | {', '.join(t['protocols'])} | {t['purpose']} |")
for t in tools:
    lines.extend(["", "## "+t["id"]+" "+t["name"], "", t["rationale"], "", "- Runtime: "+t["runtime"], "- Dependencies: "+t["needs"]["dependencies"], "- Privileges: "+t["needs"]["privileges"], "- Hardware: "+t["needs"]["hardware"], "- Operations: "+", ".join(t["operations"])+"; outputs: "+"; ".join(t["outputs"]), "- License: "+t["license"]["summary"], "- Evidence: "+", ".join(f"[upstream {i+1}]({u})" for i,u in enumerate(t["license"]["evidence"])), "- Maintenance: "+t["maintenance"]["notes"], "- Owner: "+t["owner"]+"; runtime: not run; acquisition: not acquired.", "- [Runbook]("+t["runbook"]+")."])
(dest/"CATALOG.md").write_text("\n".join(lines)+"\n",encoding="utf-8")
print("Wrote",len(tools),"catalog entries and",len(projects),"pinned source references; no upstream bytes acquired.")

examples=[]
for n,(status,error,exit_code) in enumerate([("success-empty",None,0),("partial","truncated",1),("failed","timeout",1),("failed","authentication",1),("failed","unsupported-protocol",1),("not-run","prerequisite-missing",None)],1):
    examples.append({"id":f"RUN-SYNTHETIC-{n:03d}","tool_id":"TOOL-013","tool_version":"synthetic-1.0","profile_id":"synthetic-status-example","operator":"Synthetic fixture author","scope_ref":"SCOPE-SYNTHETIC-001","started_at":None if status=="not-run" else "2026-10-15T10:00:00-04:00","finished_at":None if status=="not-run" else "2026-10-15T10:00:01-04:00","status":status,"error_category":error,"exit_code":exit_code,"evidence_id":None,"source_sha256":None,"limitations":["Invented status example; no upstream tool, target or source output exists.","Not a completed report or direct input to current reportgen; no findings inferred."]})
write("examples/run-statuses.json",{"schema_version":"cptc.rehearsal-examples/1.0","data_category":"synthetic","examples":examples})
