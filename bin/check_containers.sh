#!/bin/bash

# Script to check container availability for nf-core/tandemrepeat

echo "=========================================="
echo "Checking container availability"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_docker() {
    local image=$1
    echo -e "\nChecking Docker: $image"
    if docker manifest inspect "$image" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Available${NC}: $image"
        return 0
    else
        echo -e "${RED}✗ Not found${NC}: $image"
        return 1
    fi
}

check_quay() {
    local repo=$1
    local tag=$2
    echo -e "\nChecking Quay.io: quay.io/$repo:$tag"

    # Try to get manifest from Quay API
    response=$(curl -s "https://quay.io/api/v1/repository/$repo/tag/?specificTag=$tag" 2>/dev/null)

    if echo "$response" | grep -q "\"name\": \"$tag\""; then
        echo -e "${GREEN}✓ Available${NC}: quay.io/$repo:$tag"
        return 0
    else
        echo -e "${RED}✗ Not found${NC}: quay.io/$repo:$tag"
        return 1
    fi
}

# Check TRF
echo -e "\n${YELLOW}1. TRF (Tandem Repeats Finder)${NC}"
check_quay "biocontainers/trf" "4.09.1--h031d066_3"

# Check ULTRA
echo -e "\n${YELLOW}2. ULTRA${NC}"
check_quay "biocontainers/ultra" "0.1--pyhdfd78af_0"

# Check Vampire
echo -e "\n${YELLOW}3. Vampire${NC}"
check_quay "biocontainers/vampire" "1.0--pyhdfd78af_0"

echo -e "\n=========================================="
echo "Checking Bioconda packages"
echo "=========================================="

# Check if conda is available
if command -v conda &> /dev/null; then
    echo -e "\n${YELLOW}Checking Bioconda packages...${NC}"

    for pkg in trf ultra vampire; do
        echo -e "\nSearching: $pkg"
        result=$(conda search -c bioconda "$pkg" 2>/dev/null | grep -v "Loading" | tail -5)
        if [ -n "$result" ]; then
            echo -e "${GREEN}✓ Found in Bioconda:${NC}"
            echo "$result"
        else
            echo -e "${RED}✗ Not found in Bioconda${NC}"
        fi
    done
else
    echo "Conda not available, skipping package check"
fi

echo -e "\n=========================================="
echo "Recommendations"
echo "=========================================="
echo ""
echo "If any container is missing:"
echo "1. Check correct package name at https://anaconda.org/bioconda/"
echo "2. Submit to Bioconda: https://github.com/bioconda/bioconda-recipes"
echo "3. Or use custom Dockerfile"
echo ""
echo "Alternative container sources:"
echo "- Galaxy Depot: https://depot.galaxyproject.org/singularity/"
echo "- Biocontainers Registry: https://biocontainers.pro/"
echo ""
