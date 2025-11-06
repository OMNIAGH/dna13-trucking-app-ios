#!/bin/bash
echo "🚀 Uploading D.N.A 13 Trucking App to GitHub..."
git init
git remote add origin https://github.com/OMNIAGH/dna13-trucking-app-ios.git
git add .
git commit -m "Complete iOS app: 58 Swift files, documentation, deployment configs - Production ready"
git branch -M main
git push -u origin main
echo "✅ Upload completo!"
