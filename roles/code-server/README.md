# Code-server

Install [code-server](https://github.com/cdr/code-server).

Variables:

- `code_server_version`: code-server version to install, e.g. `v3.4.1`. ⚠️ **Must be >= v3.2.0**. Defaults to latest available in code-server repository
- `code_server_tag_name`: code-server version tag name, when it is different than `code_server_version`, e.g. `2.1698`. Defaults to `code_server_version`
- `code_server_extensions`: VSCode extensions to install from [Visual Studio Marketplace](https://marketplace.visualstudio.com), list of extension ids, e.g. `['ms-kubernetes-tools.vscode-kubernetes-tools']`
