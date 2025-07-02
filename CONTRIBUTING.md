# Contributing to VEPforT2T

Thank you for your interest in contributing to VEPforT2T! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

1. **Check existing issues** first to avoid duplicates
2. **Use issue templates** when available
3. **Provide detailed information**:
   - VEP version
   - Operating system
   - Complete error messages
   - Steps to reproduce

### Suggesting Enhancements

1. **Open a discussion** before implementing major changes
2. **Describe the use case** and why the enhancement would be useful
3. **Consider backwards compatibility**

### Pull Requests

1. **Fork the repository** and create a feature branch
2. **Follow coding standards**:
   - Use clear, descriptive variable names
   - Add comments for complex logic
   - Include error handling
3. **Test your changes** thoroughly
4. **Update documentation** as needed
5. **Submit a pull request** with a clear description

## Code Style Guidelines

### Shell Scripts

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use meaningful function names
- Add logging for important steps
- Handle errors gracefully

Example:
```bash
#!/bin/bash
set -euo pipefail

# Function to check file existence
check_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        log "ERROR: File not found: $file"
        return 1
    fi
    return 0
}
```

### Documentation

- Use Markdown format
- Include code examples
- Keep language clear and concise
- Update README.md for user-facing changes

## Testing

Before submitting a PR:

1. **Test the installation script** on a clean system
2. **Run VEP with test data** to ensure functionality
3. **Verify documentation** accuracy
4. **Check for hardcoded paths** that should be configurable

## Commit Messages

Follow conventional commit format:

```
type(scope): brief description

Longer explanation if needed

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

## Development Setup

1. Fork and clone the repository
2. Create a development branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Questions?

- Open an issue for questions
- Tag maintainers for urgent matters
- Join discussions in existing issues

Thank you for contributing to VEPforT2T!