
#!/usr/bin/env bash
set -euo pipefail

source "./.github/workflows/scripts/e2e-utils.sh"

RELEASE_TAG=""

THIS_FILE=$(gh api -H "Accept: application/vnd.github.v3+json" "/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" | jq -r '.path' | cut -d '/' -f3)
echo "THIS_FILE: $THIS_FILE"

# List the releases and find the latest for THIS_FILE.
RELEASE_LIST=$(gh release list)
while read line; do
    TAG=$(echo "$line" | cut -f1)
    BODY=$(gh release view "$TAG" --json body | jq -r '.body')
    if [[ "$BODY" == *"$THIS_FILE"* ]]; then
        RELEASE_TAG="$TAG"
        break
    fi
done <<< "$RELEASE_LIST"

if [[ -z "$RELEASE_TAG" ]]; then 
    echo "Tag not found for $THIS_FILE"
    exit 3
fi

echo "Latest tag found is $RELEASE_TAG"

PATCH=$(echo "$RELEASE_TAG" | cut -d '.' -f3)

NEW_PATCH=$((PATCH + 1))
MAJOR_MINOR=$(echo "$RELEASE_TAG" | cut -d '.' -f1,2)
NEW_RELEASE_TAG="$MAJOR_MINOR.$NEW_PATCH"

BRANCH=$(echo "$THIS_FILE" | cut -d '.' -f4)

TAG="$NEW_RELEASE_TAG"

echo "New release tag used: $TAG"

cat << EOF > DATA
**E2e release creation**:
Tag: $TAG
Branch: $BRANCH
Commit: $GITHUB_SHA
Caller file: $THIS_FILE
Caller name: $GITHUB_WORKFLOW
EOF

gh release create "$TAG" --notes-file ./DATA --target "$BRANCH"
