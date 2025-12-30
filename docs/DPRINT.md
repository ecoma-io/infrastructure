# dprint Configuration

[dprint](https://dprint.dev/) is a pluggable and configurable code formatter that handles multiple file types.

## Supported Formats

- **JSON**: Configuration files, package manifests
- **YAML**: Ansible playbooks, GitHub workflows, Kubernetes configs
- **Markdown**: Documentation files
- **TOML**: Configuration files
- **Dockerfile**: Container definitions

## Configuration

See [`dprint.json`](../dprint.json) for current configuration.

### Key Settings

- **Indent**: 2 spaces
- **Line Width**: 120 characters (JSON), maintain for Markdown
- **Quotes**: Prefer double quotes in YAML
- **Trailing Commas**: Never in JSON

## Usage

### Format all files:

```bash
dprint fmt
```

### Check formatting without changes:

```bash
dprint check
```

### Format specific files:

```bash
dprint fmt path/to/file.json path/to/other.yml
```

### Auto-format on commit:

Automatically enabled via lefthook pre-commit hook.

## IDE Integration

### VS Code

Install the [dprint extension](https://marketplace.visualstudio.com/items?itemName=dprint.dprint):

```bash
code --install-extension dprint.dprint
```

Configure in `.vscode/settings.json`:

```json
{
  "editor.defaultFormatter": "dprint.dprint",
  "editor.formatOnSave": true
}
```

### JetBrains IDEs

Install the [dprint plugin](https://plugins.jetbrains.com/plugin/18192-dprint).

## Adding New Plugins

Edit `dprint.json` and add plugin URL:

```json
{
  "plugins": [
    "https://plugins.dprint.dev/json-0.19.4.wasm",
    "https://plugins.dprint.dev/your-plugin-here.wasm"
  ]
}
```

Available plugins: https://dprint.dev/plugins/

## Excluding Files

Add patterns to `excludes` in `dprint.json`:

```json
{
  "excludes": [
    "**/node_modules",
    "**/.terraform",
    "**/custom-pattern/**"
  ]
}
```

## Performance

- **Incremental**: Only formats changed files
- **Parallel**: Processes multiple files simultaneously
- **Fast**: Written in Rust, very performant

## Troubleshooting

### dprint not found:

```bash
export PATH="$HOME/.dprint/bin:$PATH"
```

Add to `~/.bashrc` or `~/.zshrc` for persistence.

### Check dprint version:

```bash
dprint --version
```

### Clear dprint cache:

```bash
rm -rf ~/.dprint/cache
```

### Update dprint:

```bash
curl -fsSL https://dprint.dev/install.sh | sh
```

## CI/CD Integration

dprint runs automatically in:

- **Pre-commit**: Formats staged files
- **Pre-push**: Validates all files are formatted
- **GitHub Actions**: Can add explicit check step

Example GitHub Actions step:

```yaml
- name: Check code formatting
  run: dprint check
```
