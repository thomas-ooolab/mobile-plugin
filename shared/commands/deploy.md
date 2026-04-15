---
title: Deploy Helper
description: Guide through deployment process with pre-flight checks
---

# Deploy Pre-flight Checklist

Before deploying, verify:

1. **Branch**: On correct branch? Up to date with main?
2. **Tests**: All tests passing? `npm test` / `yarn test`
3. **Build**: Production build succeeds? `npm run build`
4. **Env**: Environment variables configured for target?
5. **Migrations**: Database migrations ready and tested?
6. **Dependencies**: Lock file up to date? No security advisories?

## Steps

1. Run pre-flight checks above
2. Create a release tag following semver
3. Push to trigger CI/CD pipeline
4. Monitor deployment logs
5. Verify health checks pass
6. Run smoke tests against deployed environment

## Rollback Plan

If deployment fails:
1. Check error logs
2. If data migration involved — check if reversible
3. Revert to previous tag/release
4. Notify team in Slack
