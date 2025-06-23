# Post-Merge Validation Report

**Timestamp**: Mon Jun 23 11:56:53 BST 2025
**Branch**: main
**Commit**: f0909fbec6d8ae3818999293331eb77967f7ecb3

## Validation Results

- ✅ **Critical Files Exist**: PASSED
  - Details: All critical files present
- ✅ **Python Syntax**: PASSED
  - Details: All Python files compile
- ❌ **Swift Syntax**: FAILED
  - Details: Syntax errors in: OpenWebUI-Desktop/OpenWebUI-Desktop/Models/AppState.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Models/ContainerManager.swift OpenWebUI-Desktop/OpenWebUI-Desktop/OpenWebUIApp.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Views/SetupView.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Views/SettingsView.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Views/WebView.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Views/DiagnosticsView.swift OpenWebUI-Desktop/OpenWebUI-Desktop/Views/ErrorView.swift OpenWebUI-Desktop/OpenWebUI-Desktop/ContentView.swift
- ❌ **Python Imports**: FAILED
  - Details: Import errors: CLI main import Installer class import GUI main import (PyQt6 may not be installed)
- ❌ **Merge Conflict Artifacts**: FAILED
  - Details: Found conflict markers in: ./openwebui-installer/venv/lib/python3.13/site-packages/pygments/lexers/bqn.py
./openwebui-installer/venv/lib/python3.13/site-packages/pygments/lexers/apl.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/parsers/rst/tableparser.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/parsers/rst/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/parsers/rst/states.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/utils/smartquotes.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/utils/math/latex2mathml.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/utils/math/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/transforms/frontmatter.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/nodes.py
./openwebui-installer/venv/lib/python3.13/site-packages/docutils/statemachine.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/auth/handler.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/adapters/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/adapters/host_header_ssl.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/adapters/ssl.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/adapters/source.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/multipart/decoder.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/multipart/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/multipart/encoder.py
./openwebui-installer/venv/lib/python3.13/site-packages/requests_toolbelt/streaming_iterator.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/general_hardcoded_tmp.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/hashlib_insecure_functions.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/pytorch_load.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/injection_sql.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/general_bad_file_permissions.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/tarfile_unsafe_members.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/markupsafe_markup_xss.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/injection_paramiko.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/exec.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/mako_templates.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/try_except_pass.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/ssh_no_host_key_verification.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/app_debug.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/injection_wildcard.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/logging_config_insecure_listen.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/trojansource.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/request_without_timeout.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/try_except_continue.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/general_bind_all_interfaces.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/yaml_load.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/crypto_request_no_cert_validation.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/weak_cryptographic_key.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/asserts.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/plugins/jinja2_templates.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/screen.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/custom.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/html.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/xml.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/sarif.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/yaml.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/csv.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/text.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/formatters/json.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/blacklists/imports.py
./openwebui-installer/venv/lib/python3.13/site-packages/bandit/blacklists/calls.py
./openwebui-installer/venv/lib/python3.13/site-packages/pip/_vendor/distro/distro.py
./openwebui-installer/venv/lib/python3.13/site-packages/mypy/build.py
./openwebui-installer/venv/lib/python3.13/site-packages/mypy/main.py
./openwebui-installer/venv/lib/python3.13/site-packages/mypy/stubtest.py
./openwebui-installer/venv/lib/python3.13/site-packages/setuptools/tests/test_windows_wrappers.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_pswindows.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_contracts.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_unicode.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_misc.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_linux.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_process.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_bsd.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_system.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_memleaks.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_windows.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_scripts.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/tests/test_testutils.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_common.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/__init__.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_psosx.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_psbsd.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_psaix.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_pslinux.py
./openwebui-installer/venv/lib/python3.13/site-packages/psutil/_pssunos.py
./openwebui-installer/venv/lib/python3.13/site-packages/coverage/plugin.py
./openwebui-installer/venv/lib/python3.13/site-packages/pbr/git.py
./openwebui-installer/venv/lib/python3.13/site-packages/pbr/tests/test_packaging.py
./openwebui-installer/venv/lib/python3.13/site-packages/_pytest/_argcomplete.py
./openwebui-installer/venv/lib/python3.13/site-packages/_pytest/hookspec.py
./openwebui-installer/venv/lib/python3.13/site-packages/_pytest/pytester.py
- ✅ **Universal App Store Components**: PASSED
  - Details: All components present
- ✅ **CLI Runtime Support**: PASSED
  - Details: Runtime parameter support detected
- ✅ **Swift ContainerManager**: PASSED
  - Details: ContainerManager.swift exists
- ❌ **Duplicate Directories**: FAILED
  - Details: Both openwebui-installer and openwebui_installer directories exist
- ❌ **Basic Functionality**: FAILED
  - Details: Issues: CLI help command Installer instantiation
- ❌ **Git Repository Integrity**: FAILED
  - Details: Uncommitted changes in working directory Untracked important files: .branch-analysis/branch_analysis_20250623_115014.md .branch-analysis/validation_report_20250623_115247.md .branch-analysis/validation_report_20250623_115653.md 
- ✅ **Universal App Store Schema**: PASSED
  - Details: All required sections present

## Summary

**Validation Date**: Mon Jun 23 11:57:55 BST 2025
**Total Tests**: 12
**Repository State**: ❌ ISSUES DETECTED

## Recommendations

❌ **Some validations failed.** Please review and resolve the issues above.

### Common Fixes:
1. Run `python3 -m py_compile` on failed Python files
2. Check for merge conflict markers and resolve them
3. Ensure all required Universal App Store files are present
4. Test imports and fix any missing dependencies

### Manual Verification:
- Test CLI: `python3 -m openwebui_installer.cli --help`
- Test imports: `python3 -c "from openwebui_installer.installer import Installer"`
- Check Swift compilation if Xcode is available
