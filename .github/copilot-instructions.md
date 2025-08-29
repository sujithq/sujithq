# GitHub Profile Repository (sujithq/sujithq)

This is a static GitHub profile repository that showcases professional certifications, achievements, and connects social media profiles. The repository contains primarily static content with automated GitHub Actions for generating visual elements.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Repository Structure
- **README.md**: Main profile content showcasing certifications, bio, and achievements
- **assets/**: Directory containing certificates, badges, images, and icons organized by category
- **GitHub skyline STL files**: 3D GitHub contribution models for different years
- **.github/workflows/**: Automated workflows for content generation and security scanning
- **renovate.json**: Dependency update configuration
- **.whitesource**: Security scanning configuration

### Key Operations

#### Content Updates
- Modify README.md to update profile information, certifications, or achievements
- Add new certificate images to appropriate subdirectories in assets/
- Update social media links and contact information in README.md
- The repository uses standard Git operations - no build process required

#### GitHub Actions Workflows
- **test.yml**: Generates contribution snake animation every 12 hours. NEVER CANCEL - typically takes 2-5 minutes to complete. Set timeout to 10+ minutes.
- **codeql-analysis.yml**: Security analysis workflow (currently has empty language matrix - this is intentional for a static repository)

#### Asset Management
- Certificate images are organized in assets/ subdirectories by provider (microsoft, github, aws, etc.)
- Always maintain consistent image sizing (typically 100-200px width for badges)
- Use PNG or JPEG formats for images
- Reference images using GitHub raw URLs: `https://github.com/sujithq/sujithq/raw/master/assets/[path]`

### Testing and Validation

#### Content Validation
- Always preview README.md rendering after making changes
- Verify all image links work correctly by checking asset paths
- Test social media and external links functionality
- NEVER CANCEL: Workflow runs take 2-5 minutes. Set timeout to 10+ minutes.

#### GitHub Actions Testing
- Manually trigger workflows using GitHub UI or `workflow_dispatch` when testing changes
- Monitor workflow logs for any image generation issues
- Contribution snake generation creates output in `dist/` directory on `output` branch

#### Manual Validation Steps
1. Check README.md renders correctly with all images displaying
2. Verify all external links (LinkedIn, Twitter, certification links) work
3. Confirm asset organization follows existing directory structure
4. Test workflow triggers manually if making workflow changes

## Common Tasks

### Adding New Certifications
1. Save certificate image to appropriate assets/ subdirectory (e.g., assets/microsoft/, assets/github/)
2. Update README.md with new certification entry following existing format
3. Add badge or link using consistent styling (typically 40px width for social icons, 100-200px for certificates)
4. Commit changes - no build process required

### Updating Profile Information
1. Edit README.md bio section
2. Update skills in the animated typing banner if needed
3. Modify social media links in the connect section
4. Update any achievement counts or new roles

### Asset Organization
- **assets/icons/**: Social media and platform icons
- **assets/microsoft/**: Microsoft certifications and achievements
- **assets/github/**: GitHub certifications and achievements  
- **assets/aws/**: AWS certifications
- **assets/[provider]/**: Other certification providers

### Workflow Maintenance
- The snake contribution generator runs automatically every 12 hours
- CodeQL analysis is configured but intentionally has empty language matrix (no code to analyze)
- Renovate bot updates dependencies automatically
- WhiteSource/Mend security scanning monitors for vulnerabilities

## Repository Specific Notes

### No Build Process Required
- This is a static content repository - no compilation, bundling, or build steps needed
- Changes to README.md and assets are immediately effective after commit
- GitHub Actions handle automated content generation (contribution snake)

### File Size Considerations
- GitHub skyline STL files are large (15-16MB each) but necessary for 3D printing
- Keep certificate images optimized for web display
- Use appropriate compression for PNG/JPEG assets

### Branch Strategy
- Main development on `master` branch
- GitHub Actions create content on `output` branch (for snake animation)
- Feature branches for significant profile updates

### External Dependencies
- Contribution snake generator: Uses Platane/snk action
- Image hosting: GitHub raw URLs for reliable access
- External links: Professional profiles and certification verification links

## Validation Scenarios

After making changes, always verify:
1. **README Preview**: Check that README.md displays correctly with all formatting
2. **Image Loading**: Verify all certificate images and icons load properly
3. **Link Testing**: Test external links to social profiles and certifications
4. **Workflow Success**: If workflows were modified, check they complete successfully
5. **Asset Organization**: Confirm new assets follow existing directory structure

## Timing Expectations
- **Git operations**: Immediate (< 1 minute)
- **Workflow runs**: 2-5 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
- **Profile updates**: Immediate visibility after commit to master
- **Asset uploads**: Immediate availability via GitHub raw URLs

Remember: This repository focuses on content quality and professional presentation rather than code functionality. Always maintain the professional appearance and ensure all links and images work correctly.