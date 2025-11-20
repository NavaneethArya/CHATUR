# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

### 1. **DO NOT** create a public GitHub issue

Security vulnerabilities should be reported privately to protect users.

### 2. Email Security Team

Send an email to: **navaneetharyarao@gmail.com**

Include the following information:
- Type of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### 3. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity

### 4. Disclosure Policy

- We will acknowledge receipt of your report
- We will keep you informed of the progress
- We will credit you for the discovery (if desired)
- We will not disclose your identity without permission

## Security Best Practices

### For Users

1. **Keep the app updated** - Always use the latest version
2. **Use strong passwords** - For email authentication
3. **Enable 2FA** - When available
4. **Review permissions** - Only grant necessary permissions
5. **Report suspicious activity** - Contact support immediately

### For Developers

1. **Never commit secrets** - Use environment variables
2. **Keep dependencies updated** - Regularly update packages
3. **Follow secure coding practices** - Review code for vulnerabilities
4. **Use HTTPS** - For all network requests
5. **Implement proper authentication** - Use Firebase Auth securely
6. **Validate input** - Sanitize user inputs
7. **Use secure storage** - For sensitive data

## Security Features

### Authentication

- **Phone OTP**: Secure OTP-based phone authentication
- **Email/Password**: Encrypted password storage via Firebase
- **Google Sign-In**: OAuth 2.0 secure authentication
- **Session Management**: Secure session handling

### Data Protection

- **Encryption in Transit**: All API calls use HTTPS
- **Firebase Security Rules**: Database and storage access control
- **Secure Storage**: Sensitive data stored securely
- **No Sensitive Data in Logs**: Avoid logging sensitive information

### API Security

- **API Key Management**: Keys stored securely, never in code
- **Rate Limiting**: Implemented where applicable
- **Input Validation**: All inputs validated and sanitized
- **Error Handling**: Secure error messages (no sensitive data exposure)

## Known Security Considerations

### Current Limitations

1. **API Keys**: Currently stored in code (should use environment variables)
2. **Offline Security**: Limited offline data protection
3. **Biometric Auth**: Not yet implemented

### Planned Security Enhancements

- [ ] Biometric authentication
- [ ] End-to-end encryption for sensitive data
- [ ] Advanced session management
- [ ] Security audit logging
- [ ] Penetration testing
- [ ] Dependency vulnerability scanning

## Security Checklist for Contributors

Before submitting code, ensure:

- [ ] No hardcoded secrets or API keys
- [ ] Input validation implemented
- [ ] Error messages don't expose sensitive data
- [ ] Authentication checks in place
- [ ] Firebase security rules updated (if needed)
- [ ] Dependencies are up-to-date
- [ ] No sensitive data in logs
- [ ] HTTPS used for all network requests
- [ ] Permissions requested appropriately
- [ ] Code reviewed for security issues

## Dependency Security

We regularly update dependencies to address security vulnerabilities:

```bash
# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Audit dependencies (when available)
flutter pub audit
```

## Reporting Security Issues

**Email**: navaneetharyarao@gmail.com  
**Response Time**: Within 48 hours

Thank you for helping keep Chatur secure! 🔒

