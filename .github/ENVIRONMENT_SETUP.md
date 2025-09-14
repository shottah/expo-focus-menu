# GitHub Environment Protection Setup

To enable manual approval for deployments, you need to configure environment protection rules in your GitHub repository.

## Required Environments

### 1. Development Environment

1. Go to your repository Settings → Environments
2. Click "New environment"
3. Name it: `development`
4. Click "Configure environment"
5. Under "Deployment protection rules":
   - ✅ Check "Required reviewers"
   - Add yourself as a required reviewer
   - Optional: Set "Wait timer" if you want a delay before deployment
6. Save protection rules

### 2. Production Environment (Optional)

1. Create another environment named: `production`
2. Configure with similar protection rules
3. This will be used for release deployments from main branch

## How It Works

- **Every push to development branch** will now require manual approval before proceeding
- The workflow will pause at the "Deployment Approval" step
- You'll receive a notification to review and approve the deployment
- After approval, the workflow continues (but won't publish unless it's a release)

## Approving Deployments

1. Go to the Actions tab in your repository
2. Click on the running workflow
3. You'll see "Review deployments" button
4. Click to approve or reject the deployment

## Notes

- Without these environment settings, the approval step will run automatically without waiting
- You can add multiple reviewers if needed
- You can also add deployment branch restrictions for extra security