#!/bin/bash

# Check if a tool exists in Bioconda

echo "=========================================="
echo "Checking Bioconda for: ULTRA"
echo "=========================================="

# Method 1: Anaconda API
echo -e "\n[Method 1] Checking Anaconda API..."
response=$(curl -s "https://api.anaconda.org/package/bioconda/ultra")
if [ -n "$response" ] && [ "$response" != "{}" ] && ! echo "$response" | grep -q "Not Found"; then
    echo "✓ Found in Bioconda!"
    echo "Details:"
    echo "$response" | grep -o '"version":"[^"]*"' | head -3
    echo "$response" | grep -o '"latest_version":"[^"]*"'
else
    echo "✗ Not found in Bioconda"
fi

# Method 2: HTTP status
echo -e "\n[Method 2] Checking HTTP status..."
status=$(curl -s -o /dev/null -w "%{http_code}" https://anaconda.org/bioconda/ultra)
if [ "$status" = "200" ]; then
    echo "✓ Package page exists (HTTP 200)"
else
    echo "✗ Package page not found (HTTP $status)"
fi

# Method 3: Check GitHub recipe
echo -e "\n[Method 3] Checking Bioconda Recipes GitHub..."
gh_status=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/bioconda/bioconda-recipes/contents/recipes/ultra")
if [ "$gh_status" = "200" ]; then
    echo "✓ Recipe exists in bioconda-recipes"
else
    echo "✗ No recipe found (HTTP $gh_status)"
fi

# Method 4: Check BioContainers
echo -e "\n[Method 4] Checking BioContainers registry..."
bc_response=$(curl -s "https://api.biocontainers.pro/ga4gh/trs/v2/tools?name=ultra")
if [ -n "$bc_response" ] && ! echo "$bc_response" | grep -q '"tools":\[\]'; then
    echo "✓ Found in BioContainers"
    echo "$bc_response" | grep -o '"name":"[^"]*"' | head -3
else
    echo "✗ Not found in BioContainers"
fi

# Check alternative names
echo -e "\n=========================================="
echo "Checking alternative package names..."
echo "=========================================="

for name in "ultra-annotator" "ultra_tr" "ultratandem" "vntr" "ultra-repeat"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://anaconda.org/bioconda/$name")
    if [ "$status" = "200" ]; then
        echo "? Found similar package: $name (HTTP 200)"
    fi
done

echo -e "\n=========================================="
echo "Summary"
echo "=========================================="
echo "If ULTRA is not found, you need to:"
echo "1. Submit to Bioconda: https://github.com/bioconda/bioconda-recipes"
echo "2. Or use Wave to build from GitHub source"
echo "3. Or use local Conda environment with pip install"
