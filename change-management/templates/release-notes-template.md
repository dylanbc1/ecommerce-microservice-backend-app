# Release Notes - v{{VERSION}} - {{DATE}}

## 🚀 Release Information
- **Version**: {{VERSION}}
- **Date**: {{DATE}}
- **Environment**: {{ENVIRONMENT}}
- **Build**: {{BUILD_NUMBER}}

## 📋 Changes Included
### ✨ New Features
{{NEW_FEATURES}}

### 🐛 Bug Fixes
{{BUG_FIXES}}

### 🔧 Technical Changes
{{TECHNICAL_CHANGES}}

## 🧪 Testing
- Unit Tests: {{UNIT_TESTS_STATUS}}
- Integration Tests: {{INTEGRATION_TESTS_STATUS}}
- Security Scans: {{SECURITY_TESTS_STATUS}}

## 🔄 Rollback Plan
In case of issues:
1. Execute: `kubectl rollout undo deployment/<service> -n {{NAMESPACE}}`
2. Verify: `kubectl get pods -n {{NAMESPACE}}`
3. Contact: devops@company.com
