#!/bin/bash

# Colores para output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

# Configuración del proyecto
PROJECT_NAME="netfix-hub"
GITHUB_USERNAME="aparicioedge"
REPO_URL="https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git"

echo -e "${BLUE}=== Configurando $PROJECT_NAME ===${NC}"

# 1. Crear estructura del proyecto
create_project_structure() {
    mkdir -p $PROJECT_NAME/{src/{app,components,lib,styles,utils},{public,docs,tests}/{assets,images}}
    mkdir -p $PROJECT_NAME/src/app/{auth,dashboard,admin,api}
    mkdir -p $PROJECT_NAME/src/components/{ui,layout,shared}
    mkdir -p $PROJECT_NAME/src/lib/{auth,db,api}
    mkdir -p $PROJECT_NAME/.github/workflows
}

# 2. Inicializar Git y GitHub
setup_git() {
    cd $PROJECT_NAME
    git init
    
    # Crear .gitignore
    cat > .gitignore << EOL
node_modules/
.next/
.env
.env.local
.DS_Store
*.log
.vercel
out/
build/
.turbo
dist/
EOL

    # Crear README.md
    cat > README.md << EOL
# $PROJECT_NAME

Advanced security platform powered by AI.

## Getting Started

\`\`\`bash
npm install
npm run dev
\`\`\`

## Features
- AI-powered security scanning
- Real-time threat detection
- Quantum-ready security
EOL

    git add .
    git commit -m "Initial commit"
    git branch -M main
    # git remote add origin $REPO_URL
    # git push -u origin main
}

# 3. Configurar Next.js
setup_nextjs() {
    # Inicializar proyecto Next.js
    npx create-next-app@latest . --typescript --tailwind --app --use-npm --no-git

    # Instalar dependencias adicionales
    npm install @prisma/client @trpc/client @trpc/server @trpc/react-query
    npm install next-auth @auth/prisma-adapter stripe lucide-react
    npm install @radix-ui/react-alert-dialog @radix-ui/react-dropdown-menu
    
    # Dependencias de desarrollo
    npm install -D prisma typescript @types/node @types/react @types/bcrypt
}

# 4. Configurar Next.js para despliegue estático
setup_deployment() {
    # Configurar next.config.js
    cat > next.config.js << EOL
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  basePath: process.env.NEXT_PUBLIC_BASE_PATH || '',
  assetPrefix: process.env.NEXT_PUBLIC_BASE_PATH || '',
}

module.exports = nextConfig
EOL

    # Configurar GitHub Actions
    cat > .github/workflows/deploy.yml << EOL
name: Deploy Next.js site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build
        run: npm run build
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./out

  deploy:
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOL
}

# 5. Configurar variables de entorno
setup_env() {
    cat > .env << EOL
NEXT_PUBLIC_BASE_PATH="/$PROJECT_NAME"
DATABASE_URL="postgresql://user:password@localhost:5432/netfix_hub"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
NEXTAUTH_URL="http://localhost:3000"
STRIPE_SECRET_KEY="your-stripe-secret-key"
STRIPE_WEBHOOK_SECRET="your-stripe-webhook-secret"
GITHUB_CLIENT_ID="your-github-client-id"
GITHUB_CLIENT_SECRET="your-github-client-secret"
EOL
}

# 6. Configurar scripts de desarrollo
setup_scripts() {
    # Actualizar package.json
    cat > package.json << EOL
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "export": "next export",
    "deploy": "next build && next export"
  }
}
EOL

    # Script de desarrollo
    cat > dev.sh << EOL
#!/bin/bash
npm run dev
EOL
    chmod +x dev.sh

    # Script de despliegue
    cat > deploy.sh << EOL
#!/bin/bash
npm run deploy
git add .
git commit -m "Deploy updates"
git push origin main
EOL
    chmod +x deploy.sh
}

# Ejecutar todas las funciones
main() {
    create_project_structure
    setup_git
    setup_nextjs
    setup_deployment
    setup_env
    setup_scripts

    echo -e "${GREEN}¡Proyecto configurado con éxito!${NC}"
    echo -e "\nPasos siguientes:"
    echo "1. Crear repositorio en GitHub"
    echo "2. Configurar GitHub Pages en la configuración del repositorio"
    echo "3. Actualizar variables de entorno en .env"
    echo "4. Ejecutar: ./dev.sh para desarrollo"
    echo "5. Ejecutar: ./deploy.sh para desplegar"
}

# Ejecutar script
main
