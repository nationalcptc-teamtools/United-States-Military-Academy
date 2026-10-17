#!/usr/bin/env python3
"""Prepare individual upstream tools; never launch assessments or lab services."""
import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.error
from pathlib import Path

import install as suite
import kit

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
REGISTRY = BASE / 'onboarding.json'
KINDS = {'apt', 'python', 'native', 'asset', 'image', 'compose', 'build-image', 'syft', 'held'}


def need(ok, message):
    if not ok:
        raise suite.InstallError(message)


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':')).encode()


def sha(value):
    return hashlib.sha256(value).hexdigest()


def registry(path=REGISTRY):
    data = kit.load(path)
    need(isinstance(data, dict) and data.get('schema_version') == 'cptc.onboarding/1.0', 'Unsupported onboarding registry')
    records = data.get('tools')
    need(isinstance(records, list) and 40 <= len(records) <= 150, 'Invalid tool registry')
    ids, slugs = set(), set()
    legacy = suite.manifest()
    for item in records:
        need(isinstance(item, dict) and set(item) == {'id', 'slug', 'name', 'purpose', 'upstream', 'notice', 'kind', 'spec'}, 'Invalid tool record')
        for field in ('id', 'slug', 'name', 'purpose', 'upstream', 'notice', 'kind'):
            need(isinstance(item[field], str) and 0 < len(item[field]) <= 2000, 'Invalid tool text')
        need(re.fullmatch(r'(?:TOOL-\d{3}|PREP-[A-Z0-9-]+|RUNNER-[A-Z0-9-]+)', item['id']), 'Invalid tool ID')
        need(re.fullmatch(r'[a-z][a-z0-9-]{0,47}', item['slug']), 'Invalid tool slug')
        need(item['id'] not in ids and item['slug'] not in slugs, 'Duplicate tool')
        ids.add(item['id']); slugs.add(item['slug'])
        kind, spec = item['kind'], item['spec']
        need(kind in KINDS and isinstance(spec, dict), 'Invalid acquisition kind')
        required = {'apt': {'packages'}, 'python': {'requirements'}, 'native': {'source'}, 'asset': {'asset'},
                    'image': {'image', 'release'}, 'compose': {'source', 'images'}, 'build-image': {'source'},
                    'syft': {'url', 'sha256', 'size', 'version'}, 'held': {'reason'}}[kind]
        need(set(spec) == required, 'Invalid acquisition fields')
        if kind == 'apt':
            need(isinstance(spec['packages'], list) and 0 < len(spec['packages']) <= 30 and all(isinstance(v, str) and re.fullmatch(r'[a-z0-9][a-z0-9+.-]*', v) for v in spec['packages']), 'Invalid distro packages')
        if kind == 'python':
            need(isinstance(spec['requirements'], list) and 0 < len(spec['requirements']) <= 20 and all(isinstance(v, str) and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*==[A-Za-z0-9][A-Za-z0-9_.+-]*', v) for v in spec['requirements']), 'Exact Python pins required')
        if kind == 'native':
            need(spec['source'] in {*legacy['sources'], 'open62541'}, 'Unknown native source')
        if kind == 'asset':
            need(spec['asset'] in {p['name'] for p in legacy['payloads']}, 'Unknown staged asset')
        if kind in ('image', 'compose'):
            images = [spec['image']] if kind == 'image' else spec['images']
            need(isinstance(images, list) and 0 < len(images) <= 15 and all(isinstance(v, str) and re.fullmatch(r'(?:ghcr.io/)?[a-z0-9][a-z0-9/_.-]+@sha256:[a-f0-9]{64}', v) for v in images), 'Immutable image digests required')
        if kind in ('compose', 'build-image'):
            source = spec['source']
            need(isinstance(source, dict) and set(source) == {'repository', 'commit'}, 'Invalid source definition')
            need(isinstance(source['repository'], str) and re.fullmatch(r'https://github.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', source['repository']) and isinstance(source['commit'], str) and re.fullmatch(r'[a-f0-9]{40}', source['commit']), 'Pinned canonical source required')
        if kind == 'syft':
            need(spec['url'] == 'https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_linux_amd64.tar.gz'
                 and spec['version'] == '1.54.1' and type(spec['size']) is int and 0 < spec['size'] <= 32*1024*1024
                 and isinstance(spec['sha256'], str) and re.fullmatch(r'[a-f0-9]{64}', spec['sha256']), 'Pinned Syft release required')
        if kind == 'held':
            need(isinstance(spec['reason'], str) and bool(spec['reason']), 'Hold reason required')
    need({f'TOOL-{i:03}' for i in range(1, 41)} <= ids, 'Missing catalog entries')
    return data, legacy


def select(data, values, bundle=None):
    records = data['tools']
    by_key = {key: r for r in records for key in (r['id'], r['slug'])}
    chosen = list(values)
    if bundle:
        need(bundle in data['bundles'], 'Unknown bundle')
        chosen += data['bundles'][bundle]
    need(bool(chosen) and len(chosen) <= 150, 'Select one or more tool IDs/slugs or a bundle')
    result = {}
    for key in chosen:
        need(key in by_key, 'Unknown tool: ' + key)
        result[by_key[key]['id']] = by_key[key]
    return [result[key] for key in sorted(result)]


def identity(item, legacy):
    return sha(encoded({'recipe': item, 'legacy': legacy, 'controller': suite.file_hash(Path(__file__)), 'installer': suite.file_hash(BASE/'install.py')}))


def packages(items):
    result = set()
    for item in items:
        kind = item['kind']
        if kind == 'apt': result.update(item['spec']['packages'])
        if kind == 'python': result.update(('python3-venv', 'python3-pip'))
        if kind in ('native', 'compose', 'build-image'): result.add('git')
        if kind == 'native':
            result.update(('build-essential', 'cmake', 'pkg-config', 'python3'))
            if item['spec']['source'] == 'mbpoll': result.add('libmodbus-dev')
    return sorted(result)


def state_path(prefix, item):
    return suite.managed_path(prefix, 'receipts/' + item['slug'] + '.json')


def save(prefix, item, state):
    dest = state_path(prefix, item)
    dest.parent.mkdir(exist_ok=True)
    temporary = suite.managed_path(prefix, 'receipts/.' + item['slug'] + '.tmp')
    with temporary.open('x', encoding='utf-8') as handle:
        json.dump(state, handle, indent=2); handle.write('\n')
    os.replace(temporary, dest)


def image_id(image):
    value = suite.run(['docker', 'image', 'inspect', '--format', '{{.Id}}', image], capture=True).strip()
    need(re.fullmatch(r'sha256:[a-f0-9]{64}', value), 'Missing local image identity')
    return value


def source_check(prefix, name, source):
    path = suite.managed_path(prefix, 'src/' + name)
    need(suite.run(['git', '-C', path, 'rev-parse', 'HEAD'], capture=True).strip() == source['commit'], 'Source commit changed')
    need(not suite.run(['git', '-C', path, 'status', '--porcelain'], capture=True).strip(), 'Source checkout changed')


def open62541(prefix):
    source = {'repository': 'https://github.com/open62541/open62541', 'commit': '05c2b389b65cc35884eb40d800301af1f3d130cf'}
    src = suite.checkout(prefix, 'open62541', source)
    build = suite.managed_path(prefix, 'build/open62541')
    suite.run(['cmake', '-S', src, '-B', build, '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF', '-DUA_BUILD_EXAMPLES=ON', '-DUA_BUILD_UNIT_TESTS=OFF', '-DUA_ENABLE_ENCRYPTION=OFF', '-DCMAKE_INSTALL_PREFIX=' + str(prefix), '-DCMAKE_INSTALL_LIBDIR=lib'])
    suite.run(['cmake', '--build', build, '--parallel', '2', '--target', 'open62541', 'tutorial_server_firststeps', 'tutorial_client_firststeps'])
    suite.run(['cmake', '--install', build])
    files = [p for p in (prefix/'lib').rglob('*open62541*') if p.is_file() and not p.is_symlink()]
    files += [prefix/'include/open62541/server.h']
    need(all(p.is_file() for p in files) and len(files) >= 2, 'open62541 build outputs missing')
    return {'commit': source['commit'], 'files': {p.relative_to(prefix).as_posix(): suite.file_hash(p) for p in files}, 'notice': 'MPL-2.0; encryption disabled fixture build; examples not executed'}


def acquire(prefix, item, legacy):
    kind, spec = item['kind'], item['spec']
    if kind == 'apt':
        return {'apt': suite.run(['dpkg-query', '-W', '-f=${Package}=${Version}\n', *spec['packages']], capture=True)}
    if kind == 'python': return suite.python_group(prefix, item['slug'], spec['requirements'])
    if kind == 'native':
        name = spec['source']
        if name == 'vulscan':
            source = legacy['sources'][name]
            src = suite.checkout(prefix, name, source)
            return {'commit':source['commit'], 'notice':source['notice'], 'files':{p.relative_to(prefix).as_posix():suite.file_hash(p) for p in (src/'vulscan.nse',src/'COPYING.TXT')}}
        return open62541(prefix) if name == 'open62541' else suite.native(prefix, name, legacy['sources'][name])
    if kind == 'asset':
        asset = next(p for p in legacy['payloads'] if p['name'] == spec['asset'])
        dest = suite.managed_path(prefix, 'payloads/' + asset['name']); dest.parent.mkdir(exist_ok=True)
        suite.fetch(asset['url'], dest, expected_size=asset['size'], expected_sha=asset['sha256'])
        notice = suite.managed_path(prefix, 'payloads/PEASS-LICENSE')
        if not notice.exists(): suite.fetch(asset['license_url'], notice, limit=128*1024)
        return {'files': {p.relative_to(prefix).as_posix(): suite.file_hash(p) for p in (dest, notice)}}
    if kind in ('image', 'compose', 'build-image'):
        source = spec.get('source')
        if source: src = suite.checkout(prefix, item['slug'], source)
        if kind == 'build-image':
            tag = 'cptc-prepared/' + item['slug'] + ':' + source['commit'][:12]
            suite.run(['docker', 'build', '--platform', 'linux/amd64', '--tag', tag, src], timeout=7200)
            return {'image': image_id(tag)}
        images = [spec['image']] if kind == 'image' else spec['images']
        for image in images: suite.run(['docker', 'pull', '--platform', 'linux/amd64', image])
        result = {'images': {image: image_id(image) for image in images}}
        if kind == 'compose':
            services = ('chirpstack', 'chirpstack-gateway-bridge', 'chirpstack-rest-api', 'postgres', 'redis', 'mosquitto')
            mapping = {name: {'image': image} for name, image in zip(services, images)}
            mapping['chirpstack-gateway-bridge-basicstation'] = {'image': images[1]}
            dest = suite.managed_path(prefix, 'labs/chirpstack-images.json'); dest.parent.mkdir(exist_ok=True)
            raw = json.dumps({'services':mapping}, indent=2)+'\n'
            need(not dest.exists() or dest.read_text(encoding='utf-8') == raw, 'Existing lab configuration preserved')
            dest.write_text(raw, encoding='utf-8')
            result['files'] = {dest.relative_to(prefix).as_posix():suite.file_hash(dest)}
        return result
    if kind == 'syft':
        archive = suite.managed_path(prefix, 'downloads/syft.tar.gz'); archive.parent.mkdir(exist_ok=True)
        suite.fetch(spec['url'], archive, expected_size=spec['size'], expected_sha=spec['sha256'])
        # Read only named regular members: never extract links or paths from a vendor archive.
        files = {}
        with tarfile.open(archive, 'r:gz') as tar:
            for name, relative in (('syft', 'bin/syft'), ('LICENSE', 'notices/syft-LICENSE')):
                member = tar.getmember(name)
                need(member.isfile() and member.size <= 100*1024*1024, 'Unexpected Syft archive member')
                dest = suite.managed_path(prefix, relative); dest.parent.mkdir(exist_ok=True)
                need(not dest.exists(), 'Existing Syft output preserved; select a clean prefix')
                with tar.extractfile(member) as handle: dest.write_bytes(handle.read())
                if name == 'syft': dest.chmod(0o755)
                files[relative] = suite.file_hash(dest)
        return {'files': files}
    raise suite.InstallError('Held tool cannot be acquired')


def validate_receipt(prefix, item, legacy):
    state = kit.load(state_path(prefix, item))
    need(isinstance(state, dict) and set(state) == {'schema_version', 'identity', 'complete', 'receipt'}, 'Invalid receipt schema')
    need(state['schema_version'] == 'cptc.onboard-receipt/1.0' and state['complete'] is True and state['identity'] == identity(item, legacy), 'Incomplete or changed recipe; prepare against current source')
    value = state['receipt']
    need(isinstance(value, dict), 'Invalid component receipt')
    kind = item['kind']
    keys = {'apt': {'apt'}, 'python': {'requirements', 'packages', 'interpreter'}, 'native': {'commit', 'files', 'notice'}, 'asset': {'files'}, 'syft': {'files'}, 'image': {'images'}, 'compose': {'images', 'files'}, 'build-image': {'image'}}
    need(kind in keys and set(value) == keys[kind], 'Invalid component receipt fields')
    if 'files' in value:
        need(isinstance(value['files'], dict) and 0 < len(value['files']) <= 4096, 'Invalid file receipt')
        for name, digest in value['files'].items():
            need(isinstance(name, str) and isinstance(digest, str) and re.fullmatch(r'[a-f0-9]{64}', digest), 'Invalid file identity')
            suite.managed_path(prefix, name)
        expected = {'asset': {'payloads/'+item['spec'].get('asset',''), 'payloads/PEASS-LICENSE'}, 'syft': {'bin/syft', 'notices/syft-LICENSE'}, 'compose': {'labs/chirpstack-images.json'}}
        if kind in expected: need(set(value['files']) == expected[kind], 'Missing required prepared files')
    if kind == 'python':
        need(value['requirements'] == item['spec']['requirements'] and isinstance(value['packages'], list) and all(isinstance(p, dict) and set(p) == {'name', 'version'} and all(isinstance(v, str) for v in p.values()) for p in value['packages']), 'Invalid Python receipt')
        need(value['interpreter'] == str(prefix/'venvs'/item['slug']/'bin/python'), 'Invalid Python path')
    if kind == 'native':
        source = item['spec']['source']
        commit = '05c2b389b65cc35884eb40d800301af1f3d130cf' if source == 'open62541' else legacy['sources'][source]['commit']
        need(value['commit'] == commit and isinstance(value['notice'], str), 'Invalid source receipt')
        files = set(value['files'])
        binary = {'mbpoll':'bin/mbpoll','bacnet':'bin/bacnet-readprop'}.get(source)
        if source == 'vulscan': need(files == {'src/vulscan/vulscan.nse','src/vulscan/COPYING.TXT'}, 'Vulscan source/notice missing')
        elif binary: need(files == {binary}, 'Native client file missing')
        else:
            header = {'lib60870':'cs104_connection.h','libiec61850':'iec61850_client.h','open62541':'server.h'}[source]
            fragment = {'lib60870':'60870','libiec61850':'iec61850','open62541':'open62541'}[source]
            need(any(n.startswith('include/') and Path(n).name == header for n in files)
                 and any(n.startswith('lib/') and fragment in Path(n).name for n in files)
                 and all(n.startswith(('lib/','include/')) for n in files), 'Required native library/header missing')
    if kind == 'apt': need(isinstance(value['apt'], str) and 0 < len(value['apt']) <= 20000, 'Invalid distro receipt')
    if kind in ('image', 'compose'):
        images = [item['spec']['image']] if kind == 'image' else item['spec']['images']
        need(isinstance(value['images'], dict) and set(value['images']) == set(images) and all(isinstance(v, str) and re.fullmatch(r'sha256:[a-f0-9]{64}', v) for v in value['images'].values()), 'Invalid image receipt')
    if kind == 'build-image': need(isinstance(value['image'], str) and re.fullmatch(r'sha256:[a-f0-9]{64}', value['image']), 'Invalid built image receipt')
    return value


def check(prefix, item, legacy):
    value = validate_receipt(prefix, item, legacy)
    for name, digest in value.get('files', {}).items():
        path = suite.managed_path(prefix, name)
        need(path.is_file() and suite.file_hash(path) == digest, 'Prepared file changed: ' + name)
    if item['kind'] == 'asset':
        asset = next(p for p in legacy['payloads'] if p['name'] == item['spec']['asset'])
        path = suite.managed_path(prefix, 'payloads/'+asset['name'])
        need(path.stat().st_size == asset['size'] and suite.file_hash(path) == asset['sha256'], 'Staged asset differs from pinned upstream identity')
    kind, spec = item['kind'], item['spec']
    if kind == 'apt':
        status = suite.run(['dpkg-query', '-W', '-f=${db:Status-Status}\n', *spec['packages']], capture=True)
        need(status.splitlines() == ['installed']*len(spec['packages']), 'Distro package removed or unconfigured')
        actual = suite.run(['dpkg-query', '-W', '-f=${Package}=${Version}\n', *spec['packages']], capture=True)
        need(actual == value['apt'], 'Distro version changed')
    if kind == 'python':
        interpreter = suite.venv_python(prefix, item['slug'])
        suite.run([interpreter, '-m', 'pip', 'check'])
        current = json.loads(suite.run([interpreter, '-m', 'pip', 'list', '--format=json', '--disable-pip-version-check'], capture=True))
        need(sorted(current, key=lambda p:p['name']) == sorted(value['packages'], key=lambda p:p['name']), 'Python package inventory changed')
        normalized = {p['name'].lower().replace('_','-'):p['version'] for p in current}
        for requirement in spec['requirements']:
            name, version = requirement.split('=='); need(normalized.get(name.lower().replace('_','-')) == version, 'Python top-level pin missing')
    if kind == 'native':
        name = spec['source']; source_check(prefix, name, {'commit': value['commit']})
    if kind in ('compose', 'build-image'): source_check(prefix, item['slug'], spec['source'])
    for image, digest in value.get('images', {}).items(): need(image_id(image) == digest, 'Local image changed')
    if kind == 'build-image': need(image_id(value['image']) == value['image'], 'Built image missing')
    return value


def install(items, prefix, legacy, skip_system=False):
    for item in items: need(item['kind'] != 'held', item['name'] + ': ' + item['spec'].get('reason', 'held'))
    need(platform.system() == 'Linux' and platform.machine().lower() in ('x86_64', 'amd64'), 'Acquisition host must be Linux amd64; list/show/plan work elsewhere')
    need(sys.version_info >= (3, 11) or not any(r['slug'] == 'zigpy' for r in items), 'zigpy needs Python 3.11+')
    suite.check_existing_links(prefix)
    completed = []
    for item in items:
        path = state_path(prefix, item)
        if path.exists():
            old = kit.load(path)
            need(isinstance(old, dict) and set(old) == {'schema_version','identity','complete','receipt'}
                 and old['schema_version'] == 'cptc.onboard-receipt/1.0' and type(old['complete']) is bool
                 and isinstance(old['receipt'], dict) and old['identity'] == identity(item, legacy), 'Existing receipt is malformed or belongs to different source; choose a clean prefix')
            if old['complete']:
                validate_receipt(prefix, item, legacy)
                completed.append(item)
    # Validate every saved component before any metadata lookup, then verify reuse.
    for item in completed: check(prefix, item, legacy)
    items = [item for item in items if item not in completed]
    if not items: return
    if any(r['kind'] in ('image', 'compose', 'build-image') for r in items):
        need(shutil.which('docker'), 'Install Docker Engine separately; onboarding never installs or starts its service')
        need(suite.run(['docker', 'info', '--format', '{{.OSType}}'], capture=True).strip() == 'linux', 'Docker must use Linux containers')
    apt = packages(items)
    # Registry apt recipes contain clients/build/QA only. Service products use OCI acquisition.
    if apt:
        need(shutil.which('apt-get'), 'An apt-based Linux host is required for these components')
        if not skip_system:
            sudo = [] if os.geteuid() == 0 else ['sudo']
            suite.run([*sudo, 'apt-get', 'update'])
            suite.run([*sudo, 'env', 'DEBIAN_FRONTEND=noninteractive', 'apt-get', 'install', '-y', '--no-install-recommends', *apt])
        status = suite.run(['dpkg-query', '-W', '-f=${db:Status-Status}\n', *apt], capture=True)
        need(status.splitlines() == ['installed']*len(apt), 'Required system packages are not installed')
    prefix.mkdir(parents=True, exist_ok=True)
    for directory in ('bin', 'src', 'venvs', 'build', 'lib', 'include', 'receipts'):
        suite.managed_path(prefix, directory).mkdir(exist_ok=True)
    for item in items:
        destination = state_path(prefix, item)
        if destination.exists():
            old = kit.load(destination)
            if isinstance(old, dict) and old.get('complete') is True:
                check(prefix, item, legacy)
                continue
            need(isinstance(old, dict) and old.get('identity') == identity(item, legacy), 'Existing incomplete receipt belongs to different source; choose a clean prefix')
        state = {'schema_version': 'cptc.onboard-receipt/1.0', 'identity': identity(item, legacy), 'complete': False, 'receipt': {}}
        save(prefix, item, state)
        state['receipt'] = acquire(prefix, item, legacy)
        state['complete'] = True
        save(prefix, item, state)
        try: check(prefix, item, legacy)
        except Exception:
            state['complete'] = False; save(prefix, item, state); raise


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('list', 'show', 'plan', 'install', 'check'))
    parser.add_argument('tools', nargs='*', help='IDs or slugs from list; repeated selections deduplicate')
    parser.add_argument('--bundle', choices=('qa', 'sensors', 'labs', 'runner'))
    parser.add_argument('--prefix', type=Path, default=ROOT/'.cptc-tools')
    parser.add_argument('--skip-system', action='store_true', help='Verify already provisioned distro dependencies')
    args = parser.parse_args(argv)
    try:
        data, legacy = registry()
        if args.command == 'list':
            need(not args.tools and not args.bundle, 'list does not take selections')
            print(json.dumps([{'id':i['id'], 'slug':i['slug'], 'name':i['name'], 'kind':i['kind']} for i in data['tools']], indent=2)); return 0
        items = select(data, args.tools, args.bundle)
        if args.command == 'show': print(json.dumps(items, indent=2)); return 0
        prefix = suite.prefix_path(args.prefix)
        if args.command == 'plan':
            print(json.dumps({'tools':items, 'system_packages':packages(items), 'prefix':str(prefix), 'mutations_performed':False, 'held':[r['id'] for r in items if r['kind']=='held']}, indent=2)); return 0
        if args.command == 'install': install(items, prefix, legacy, args.skip_system)
        else:
            for item in items: validate_receipt(prefix, item, legacy)
            for item in items: check(prefix, item, legacy)
        print('Prepared selection verified. No assessment or lab service was launched.'); return 0
    except (kit.Invalid, suite.InstallError, OSError, ValueError, TypeError, KeyError, tarfile.TarError, subprocess.SubprocessError, urllib.error.URLError) as exc:
        detail = str(exc) if isinstance(exc, (kit.Invalid, suite.InstallError)) else type(exc).__name__
        print('Onboarding failed: ' + detail + '. See ONBOARDING.md; existing content is preserved.', file=sys.stderr); return 1


if __name__ == '__main__': sys.exit(main())
