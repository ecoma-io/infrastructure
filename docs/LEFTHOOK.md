# Lefthook Git Hooks

This repository uses [Lefthook](https://github.com/evilmartians/lefthook) to automate quality checks via Git hooks.

## Installation

Lefthook is already configured in the devcontainer. To manually install:

```bash
lefthook install
```

## Available Hooks

### Pre-Commit

Runs before each commit is created:

- **terraform-fmt**: Checks Terraform formatting
- **terraform-validate**: Validates Terraform configuration
- **ansible-lint**: Lints Ansible playbooks and roles
- **vale-lint**: Checks documentation quality (Markdown files)
- **trailing-whitespace**: Detects trailing spaces

### Pre-Push

Runs before pushing to remote:

- **gitleaks-scan**: Scans for hardcoded secrets/credentials
- **ansible-lint-full**: Full Ansible lint check
- **terraform-fmt-all**: Checks all Terraform files formatting

### Commit-Msg

Validates commit message format:

- **commit-message-lint**: Enforces [Conventional Commits](https://www.conventionalcommits.org/) format

#### Valid commit message formats:

```
feat(terraform): add AWS compute module
fix(ansible): correct swap disk mounting logic
docs(readme): update storage strategy documentation
chore(deps): update Terraform to v1.6
ci(github): add automated testing workflow
```

#### Commit types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `perf`: Performance improvements
- `build`: Build system changes

### Post-Checkout

Runs after switching branches:

- Reminders to run `terraform init`
- Reminders to update Ansible collections

### Post-Merge

Runs after successful merge:

- Alerts about infrastructure file changes

## Running Hooks Manually

Test specific hooks without committing:

```bash
# Run all pre-commit hooks
lefthook run pre-commit

# Run specific hook
lefthook run pre-commit --commands terraform-fmt

# Run pre-push hooks
lefthook run pre-push

# Skip hooks for emergency commits (use sparingly!)
LEFTHOOK=0 git commit -m "emergency fix"
```

## Skipping Hooks

### Skip specific commands:

```bash
git commit --no-verify  # Skip all pre-commit hooks
LEFTHOOK_EXCLUDE=terraform-fmt git commit -m "skip terraform check"
```

### Skip by tags:

```bash
LEFTHOOK_EXCLUDE=terraform,ansible git commit -m "skip terraform and ansible"
```

## Configuration

Main configuration: [`lefthook.yml`](lefthook.yml)

### Adding new hooks:

Edit `lefthook.yml` and add new commands under the appropriate hook:

```yaml
pre-commit:
  commands:
    my-custom-check:
      tags: custom
      glob: "*.txt"
      run: ./scripts/my-check.sh {staged_files}
```

Then reinstall:

```bash
lefthook install
```

## Troubleshooting

### Hook failed but I need to commit:

```bash
# Skip verification (emergency only!)
git commit --no-verify -m "your message"
```

### Update hooks after config change:

```bash
lefthook install
```

### Check hook status:

```bash
ls -la .git/hooks/
```

### Uninstall hooks:

```bash
lefthook uninstall
```

## Tools Integrated

- **Terraform**: Code formatting and validation
- **Ansible Lint**: Playbook and role quality checks
- **Vale**: Documentation style and grammar checking
- **Gitleaks**: Secret and credential scanning
- **Git**: Commit message format validation

## Best Practices

1. Always run `lefthook install` after cloning the repository
2. Fix all hook errors before committing (don't use `--no-verify` unless absolutely necessary)
3. Follow Conventional Commits format for all commit messages
4. Review Vale suggestions for documentation improvements
5. Never commit secrets or credentials (Gitleaks will catch them)

## CI/CD Integration

These same checks run in GitHub Actions CI pipeline. Passing hooks locally ensures CI will pass.
