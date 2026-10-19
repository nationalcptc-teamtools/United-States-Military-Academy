"""Selection, integrity and acquisition boundaries with synthetic artifacts."""
import contextlib
import copy
import io
import json
import tempfile
import tarfile
import unittest
from pathlib import Path
from unittest.mock import patch
import sys

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE))
import onboard as tool


class OnboardingTests(unittest.TestCase):
    def setUp(self):
        self.data, self.legacy = tool.registry()
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.prefix = Path(self.temp.name)/'prepared'

    def item(self, slug): return tool.select(self.data, [slug])[0]

    def receipt(self, item, value):
        self.prefix.mkdir(exist_ok=True)
        tool.save(self.prefix, item, {'schema_version':'cptc.onboard-receipt/1.0','identity':tool.identity(item,self.legacy),'complete':True,'receipt':value})

    def test_complete_unique_catalog_and_deterministic_selection(self):
        self.assertEqual(len(self.data['tools']), 74)
        for n in range(1,41): self.assertEqual(len(tool.select(self.data,[f'TOOL-{n:03}'])),1)
        self.assertEqual(tool.select(self.data,['zeek','TOOL-004','syft']),tool.select(self.data,['syft','zeek']))
        with self.assertRaises(tool.suite.InstallError): tool.select(self.data,['not-a-tool'])

    def test_individual_closure_excludes_unrelated_profile_components(self):
        selected=tool.select(self.data,['cantools'])
        self.assertEqual(selected[0]['spec']['requirements'],['cantools==45.0.0'])
        self.assertEqual(tool.packages(selected),['python3-pip','python3-venv'])
        self.assertFalse(any(i['kind']=='asset' or i['slug']=='reporting' for i in selected))

    def test_plan_has_no_subprocess_network_or_writes(self):
        for slug in ('syft','openplc','conpot','metasploit','chirpstack','pip-tools'):
            with patch.object(tool.suite,'run',side_effect=AssertionError('subprocess')), patch.object(tool,'save',side_effect=AssertionError('write')), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(tool.main(['plan',slug,'--prefix',str(self.prefix)]),0)
        self.assertFalse(self.prefix.exists())

    def test_held_selection_precedes_all_changes_even_with_valid_tools(self):
        with patch.object(tool.suite,'run') as run, patch.object(tool.platform,'system',return_value='Linux'), self.assertRaises(tool.suite.InstallError):
            tool.install(tool.select(self.data,['syft','metasploit']),self.prefix,self.legacy)
        run.assert_not_called();self.assertFalse(self.prefix.exists())

    def test_bad_pins_and_unsupported_fields_fail_before_dispatch(self):
        for mutate in (lambda r:r['spec'].update(image='zeek/zeek:latest'),lambda r:r.update(kind='shell'),lambda r:r['spec'].update(command='echo bad')):
            data=copy.deepcopy(self.data);r=next(r for r in data['tools'] if r['slug']=='zeek');mutate(r)
            path=Path(self.temp.name)/'registry.json';path.write_text(json.dumps(data))
            with patch.object(tool.suite,'run') as run,self.assertRaises(tool.suite.InstallError): tool.registry(path)
            run.assert_not_called()

    def test_host_preflight_does_not_create_prefix(self):
        with patch.object(tool.platform,'system',return_value='Windows'),patch.object(tool.suite,'run') as run,self.assertRaises(tool.suite.InstallError):
            tool.install([self.item('syft')],self.prefix,self.legacy)
        run.assert_not_called();self.assertFalse(self.prefix.exists())

    def test_incomplete_or_wrong_identity_rejected_before_metadata_commands(self):
        item=self.item('ffuf');self.receipt(item,{'apt':'ffuf=1\n'})
        path=tool.state_path(self.prefix,item)
        for field,value in (('identity','0'*64),('complete',False),('schema_version','bad')):
            data=json.loads(path.read_text());original=copy.deepcopy(data);data[field]=value;path.write_text(json.dumps(data))
            with patch.object(tool.suite,'run') as run,self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)
            run.assert_not_called();path.write_text(json.dumps(original))

    def test_saved_paths_cannot_escape_prefix(self):
        item=self.item('syft');self.receipt(item,{'files':{'../outside':'0'*64}})
        with patch.object(tool.suite,'run') as run,self.assertRaises((tool.suite.InstallError,tool.kit.Invalid)):
            tool.check(self.prefix,item,self.legacy)
        run.assert_not_called()

    def test_missing_asset_members_cannot_be_accepted(self):
        item=self.item('linpeas');self.receipt(item,{'files':{'payloads/PEASS-LICENSE':'0'*64}})
        with self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)

    def test_tampered_prepared_file_fails_without_execution(self):
        item=self.item('syft');self.prefix.mkdir()
        files={}
        for name in ('bin/syft','notices/syft-LICENSE'):
            path=self.prefix/name;path.parent.mkdir(exist_ok=True);path.write_bytes(b'synthetic');files[name]=tool.sha(b'synthetic')
        self.receipt(item,{'files':files})
        with patch.object(tool.suite,'run') as run:tool.check(self.prefix,item,self.legacy)
        run.assert_not_called();(self.prefix/'bin/syft').write_bytes(b'changed')
        with self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)

    def test_removed_distro_package_cannot_pass_version_check(self):
        item=self.item('ffuf');self.receipt(item,{'apt':'ffuf=1\n'})
        with patch.object(tool.suite,'run',side_effect=['config-files\n','ffuf=1\n']),self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)

    def test_missing_image_and_modified_local_identity_fail(self):
        item=self.item('zeek');image=item['spec']['image'];self.receipt(item,{'images':{image:'sha256:'+'1'*64}})
        for reply in ('', 'sha256:'+'2'*64):
            with patch.object(tool.suite,'run',return_value=reply),self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)

    def test_image_acquisition_only_pulls_and_inspects(self):
        item=self.item('zeek')
        with patch.object(tool.suite,'run',side_effect=[None,'sha256:'+'1'*64]) as run:
            value=tool.acquire(self.prefix,item,self.legacy)
        self.assertEqual(len(value['images']),1)
        self.assertEqual([c.args[0][1] for c in run.call_args_list],['pull','image'])
        self.assertFalse(any('run' in c.args[0] or 'up' in c.args[0] for c in run.call_args_list))

    def test_vulscan_reference_does_not_touch_legacy_repository_link(self):
        item=self.item('vulscan');src=self.prefix/'src/vulscan';src.mkdir(parents=True)
        for name in ('vulscan.nse','COPYING.TXT'):(src/name).write_bytes(b'synthetic')
        with patch.object(tool.suite,'checkout',return_value=src),patch.object(tool.suite,'native',side_effect=AssertionError('legacy link')):
            result=tool.acquire(self.prefix,item,self.legacy)
        self.assertEqual(set(result['files']),{'src/vulscan/vulscan.nse','src/vulscan/COPYING.TXT'})

    def test_compose_pins_every_constituent_service_without_starting(self):
        item=self.item('chirpstack');self.prefix.mkdir()
        with patch.object(tool.suite,'checkout',return_value=self.prefix/'src/chirpstack'),patch.object(tool.suite,'run',side_effect=lambda a,**kw:'sha256:'+'1'*64 if 'inspect' in a else None) as run:
            value=tool.acquire(self.prefix,item,self.legacy)
        config=json.loads((self.prefix/'labs/chirpstack-images.json').read_text())
        self.assertEqual(len(config['services']),7)
        self.assertEqual(set(v['image'] for v in config['services'].values()),set(item['spec']['images']))
        self.assertEqual(len(value['images']),6)
        self.assertFalse(any('up' in c.args[0] or 'run' in c.args[0] for c in run.call_args_list))

    def test_failed_acquisition_retains_incomplete_receipt(self):
        item=self.item('syft')
        with patch.object(tool.platform,'system',return_value='Linux'),patch.object(tool.platform,'machine',return_value='x86_64'),patch.object(tool,'acquire',side_effect=tool.suite.InstallError('synthetic download failure')),self.assertRaises(tool.suite.InstallError):
            tool.install([item],self.prefix,self.legacy)
        self.assertIs(json.loads(tool.state_path(self.prefix,item).read_text())['complete'],False)

    def test_complete_receipt_reused_without_apt_or_acquisition(self):
        item=self.item('ffuf');self.receipt(item,{'apt':'ffuf=1\n'})
        with patch.object(tool.platform,'system',return_value='Linux'),patch.object(tool.platform,'machine',return_value='x86_64'),patch.object(tool.suite,'run',side_effect=['installed\n','ffuf=1\n']) as run,patch.object(tool,'acquire') as acquire:
            tool.install([item],self.prefix,self.legacy)
        acquire.assert_not_called();self.assertEqual(run.call_count,2)
        self.assertFalse(any('apt-get' in c.args[0] for c in run.call_args_list))

    def test_malformed_existing_receipt_precedes_all_package_changes(self):
        item=self.item('ffuf');self.receipt(item,{'apt':['bad']})
        with patch.object(tool.platform,'system',return_value='Linux'),patch.object(tool.platform,'machine',return_value='x86_64'),patch.object(tool.suite,'run') as run,self.assertRaises(tool.suite.InstallError):
            tool.install([item],self.prefix,self.legacy)
        run.assert_not_called()

    def test_native_receipt_cannot_substitute_unrelated_file(self):
        item=self.item('mbpoll');self.receipt(item,{'commit':self.legacy['sources']['mbpoll']['commit'],'notice':'synthetic','files':{'unrelated':'0'*64}})
        with patch.object(tool.suite,'run') as run,self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)
        run.assert_not_called()

    def test_asset_bytes_must_match_upstream_not_only_local_receipt(self):
        item=self.item('linpeas');self.prefix.mkdir();folder=self.prefix/'payloads';folder.mkdir()
        files={}
        for name in ('linpeas.sh','PEASS-LICENSE'):
            path=folder/name;path.write_bytes(b'synthetic');files['payloads/'+name]=tool.sha(b'synthetic')
        self.receipt(item,{'files':files})
        with self.assertRaises(tool.suite.InstallError):tool.check(self.prefix,item,self.legacy)

    def test_syft_archive_never_extracts_symlinks(self):
        item=self.item('syft');self.prefix.mkdir()
        archive=self.prefix/'downloads/syft.tar.gz';archive.parent.mkdir()
        with tarfile.open(archive,'w:gz') as tar:
            member=tarfile.TarInfo('syft');member.type=tarfile.SYMTYPE;member.linkname='/outside';tar.addfile(member)
        with patch.object(tool.suite,'fetch'),self.assertRaises(tool.suite.InstallError):tool.acquire(self.prefix,item,self.legacy)
        self.assertFalse((self.prefix/'bin/syft').exists())

    def test_new_files_are_in_both_package_allowlists(self):
        import build
        for name in ('onboard.py','onboarding.json','ONBOARDING.md','tests/test_onboard.py','syft-local.yaml','requirements/reporting.in'):
            self.assertIn(name,build.FILES)
        path=BASE.parent/'workbench/delivery.py'
        if path.is_file():
            delivery=path.read_text(encoding='utf-8')
            for name in ('onboard.py','onboarding.json','ONBOARDING.md','tool-onboarding.svg','tools.py'):
                self.assertIn('"'+name+'"',delivery if name!='tool-onboarding.svg' else delivery.replace('docs/assets/',''))


if __name__=='__main__':unittest.main()
