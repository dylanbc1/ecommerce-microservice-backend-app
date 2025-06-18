#!/bin/bash
generate_release_notes() {
    local version=${1:-"1.0.0"}
    local environment=${2:-"dev"}
    local build_number=${3:-"1"}
    
    local release_file="change-management/releases/release-notes-${version}-${environment}.md"
    mkdir -p change-management/releases
    
    # Obtener commits recientes
    local recent_commits=$(git log --oneline -10 2>/dev/null || echo "No git history available")
    
    # Generar release notes
    sed "s/{{VERSION}}/$version/g; s/{{DATE}}/$(date)/g; s/{{ENVIRONMENT}}/$environment/g; s/{{BUILD_NUMBER}}/$build_number/g" \
        change-management/templates/release-notes-template.md > "$release_file"
    
    # Agregar commits
    echo -e "\n## 📝 Recent Commits\n\`\`\`\n$recent_commits\n\`\`\`" >> "$release_file"
    
    echo "✅ Release notes generated: $release_file"
}

generate_release_notes "$@"
