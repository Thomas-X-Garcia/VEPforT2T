# Publishing VEPforT2T to GitHub

Follow these steps to publish the VEPforT2T repository to https://github.com/Thomas-X-Garcia/VEPforT2T

## Step 1: Initialize Git Repository

```bash
cd /home/i9a5000/VEPforT2T
git init
git add .
git commit -m "Initial commit: VEPforT2T - Ensembl VEP pipeline for T2T-CHM13v2.0

- Complete pipeline for running VEP on T2T-CHM13v2.0 variants
- Pure T2T annotations without GRCh38 contamination
- BCFtools liftover integration for SV references
- Comprehensive documentation and examples
- Handles T2T-specific gene identifiers (ENSG05220* pattern)"
```

## Step 2: Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `VEPforT2T`
3. Description: `Ensembl VEP pipeline optimized for T2T-CHM13v2.0 complete human genome annotation`
4. Set as Public repository
5. Do NOT initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 3: Connect Local Repository to GitHub

After creating the repository on GitHub, run these commands:

```bash
git remote add origin https://github.com/Thomas-X-Garcia/VEPforT2T.git
git branch -M main
git push -u origin main
```

## Step 4: Verify Upload

Check that all files are properly uploaded:
- Navigate to https://github.com/Thomas-X-Garcia/VEPforT2T
- Verify README.md is displayed
- Check that all directories are present

## Step 5: Add Topics (Optional)

On the GitHub repository page, click the gear icon next to "About" and add topics:
- `vep`
- `t2t`
- `chm13`
- `variant-annotation`
- `genomics`
- `bioinformatics`

## Step 6: Create Release (Optional)

1. Go to Releases → Create a new release
2. Tag version: `v1.0.0`
3. Release title: `VEPforT2T v1.0.0`
4. Description: Copy from CHANGELOG.md
5. Publish release

## Alternative: Using GitHub CLI

If you have GitHub CLI installed:

```bash
cd /home/i9a5000/VEPforT2T
git init
git add .
git commit -m "Initial commit: VEPforT2T - Ensembl VEP pipeline for T2T-CHM13v2.0"
gh repo create Thomas-X-Garcia/VEPforT2T --public --source=. --remote=origin --push
```

## Notes

- Make sure you're logged into GitHub
- If using HTTPS, you may need to enter your GitHub username and personal access token
- If using SSH, ensure your SSH keys are properly configured
- The repository will be available at: https://github.com/Thomas-X-Garcia/VEPforT2T