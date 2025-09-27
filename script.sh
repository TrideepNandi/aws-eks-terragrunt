#!/bin/bash

# Enhanced Terragrunt Deployment Script with Dependency Management
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------------------------------
# Usage & Help
# -------------------------------
show_help() {
    echo "Usage: $0 [MODE] [COMPONENTS] [OPTIONS]"
    echo ""
    echo "MODE (default: deploy):"
    echo "  plan     - Run terragrunt plan"
    echo "  deploy   - Run terragrunt apply"
    echo "  destroy  - Run terragrunt destroy"
    echo "  validate - Run terragrunt validate"
    echo "  init     - Run terragrunt init only"
    echo ""
    echo "COMPONENTS (default: all):"
    echo "  s3-backend - Deploy only S3 backend"
    echo "  iam        - Deploy IAM roles only"
    echo "  networking - Deploy networking for specific region/cluster"
    echo "  eks        - Deploy EKS clusters for specific region/cluster"
    echo "  region     - Deploy all components for a specific region"
    echo "  infra      - Deploy iam + networking + eks (respects dependencies)"
    echo "  all        - Deploy everything in proper order"
    echo ""
    echo "REGION FILTERS (use with networking/eks/region):"
    echo "  --region us-east-1|us-west-2|eu-west-1"
    echo "  --cluster app-cluster|management-cluster"
    echo ""
    echo "OPTIONS:"
    echo "  --dry-run        - Show what would be executed without running"
    echo "  --parallel       - Run independent components in parallel"
    echo "  --skip-deps      - Skip dependency checks"
    echo "  --force          - Force execution even with warnings"
    echo ""
    echo "Examples:"
    echo "  $0 deploy s3-backend"
    echo "  $0 plan networking --region us-east-1"
    echo "  $0 deploy eks --region us-east-1 --cluster app-cluster"
    echo "  $0 deploy region --region us-west-2"
    echo "  $0 destroy all --dry-run"
    echo "  $0 deploy infra --parallel"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    show_help
    exit 0
fi

# -------------------------------
# Variables & Argument Parsing
# -------------------------------
MODE=${1:-deploy}
COMPONENTS=${2:-all}
DRY_RUN=false
PARALLEL=false
SKIP_DEPS=false
FORCE=false
REGION_FILTER=""
CLUSTER_FILTER=""

# Parse additional arguments
shift 2 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --region)
            REGION_FILTER="$2"
            shift 2
            ;;
        --cluster)
            CLUSTER_FILTER="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Starting AWS Terragrunt operation: ${YELLOW}$MODE${NC} for ${YELLOW}$COMPONENTS${NC}"

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    local warnings=()
    
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check required tools
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    else
        local tf_version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 2>/dev/null || terraform version | head -n1 | cut -d'v' -f2 | cut -d' ' -f1)
        echo -e "  ✅ Terraform: ${GREEN}$tf_version${NC}"
    fi
    
    if ! command -v terragrunt &> /dev/null; then
        missing_tools+=("terragrunt")
    else
        local tg_version=$(terragrunt --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        echo -e "  ✅ Terragrunt: ${GREEN}$tg_version${NC}"
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    else
        local aws_version=$(aws --version 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)
        echo -e "  ✅ AWS CLI: ${GREEN}$aws_version${NC}"
    fi
    
    # Check optional but recommended tools
    if ! command -v kubectl &> /dev/null; then
        warnings+=("kubectl (recommended for EKS cluster management)")
    else
        local kubectl_version=$(kubectl version --client --short 2>/dev/null | cut -d'v' -f2 2>/dev/null || echo "installed")
        echo -e "  ✅ kubectl: ${GREEN}$kubectl_version${NC}"
    fi
    
    if ! command -v jq &> /dev/null; then
        warnings+=("jq (helpful for JSON parsing)")
    else
        local jq_version=$(jq --version 2>/dev/null | cut -d'-' -f2)
        echo -e "  ✅ jq: ${GREEN}$jq_version${NC}"
    fi
    
    # Check AWS configuration
    if [ -z "${AWS_PROFILE:-}" ]; then
        warnings+=("AWS_PROFILE environment variable not set")
    else
        echo -e "  ✅ AWS Profile: ${GREEN}$AWS_PROFILE${NC}"
        
        # Test AWS credentials
        if aws sts get-caller-identity &> /dev/null; then
            local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
            local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
            echo -e "  ✅ AWS Credentials: ${GREEN}Valid${NC} (Account: $account_id)"
        else
            warnings+=("AWS credentials not configured or invalid")
        fi
    fi
    
    # Check for git (useful for version control)
    if command -v git &> /dev/null; then
        local git_version=$(git --version | cut -d' ' -f3)
        echo -e "  ✅ Git: ${GREEN}$git_version${NC}"
    fi
    
    # Report missing tools
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "\n${RED}❌ Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "  - ${RED}$tool${NC}"
        done
        echo -e "\n${YELLOW}Installation commands:${NC}"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                terraform)
                    echo -e "  ${BLUE}Terraform:${NC} https://developer.hashicorp.com/terraform/downloads"
                    echo -e "    brew install terraform  # macOS"
                    echo -e "    apt-get install terraform  # Ubuntu/Debian"
                    ;;
                terragrunt)
                    echo -e "  ${BLUE}Terragrunt:${NC} https://terragrunt.gruntwork.io/docs/getting-started/install/"
                    echo -e "    brew install terragrunt  # macOS"
                    echo -e "    wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 -O terragrunt"
                    ;;
                aws-cli)
                    echo -e "  ${BLUE}AWS CLI:${NC} https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                    echo -e "    brew install awscli  # macOS"
                    echo -e "    apt-get install awscli  # Ubuntu/Debian"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Report warnings
    if [ ${#warnings[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}⚠️  Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  - ${YELLOW}$warning${NC}"
        done
        echo ""
    fi
    
    echo -e "${GREEN}✅ All required tools are available!${NC}\n"
}

check_prerequisites

# -------------------------------
# Dependency Management
# -------------------------------
declare -A DEPENDENCIES
DEPENDENCIES[s3-backend]=""
DEPENDENCIES[iam]="s3-backend"
DEPENDENCIES[networking]="s3-backend iam"
DEPENDENCIES[eks]="s3-backend iam networking"

check_dependencies() {
    local component=$1
    local deps=${DEPENDENCIES[$component]:-}
    
    if [ "$SKIP_DEPS" = true ]; then
        return 0
    fi
    
    for dep in $deps; do
        if [ ! -f ".terragrunt-status/$dep.deployed" ]; then
            echo -e "${YELLOW}⚠️  Dependency $dep not deployed for $component${NC}"
            if [ "$FORCE" = false ]; then
                echo -e "${RED}❌ Use --force to override or deploy dependencies first${NC}"
                exit 1
            fi
        fi
    done
}

mark_deployed() {
    local component=$1
    mkdir -p .terragrunt-status
    touch ".terragrunt-status/$component.deployed"
}

mark_destroyed() {
    local component=$1
    rm -f ".terragrunt-status/$component.deployed"
}

# -------------------------------
# Enhanced Terragrunt Runner
# -------------------------------
run_component() {
    local path=$1
    local name=$2
    local cmd=$3
    local component=${4:-}

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would run: $cmd $name at $path"
        return 0
    fi

    echo -e "${BLUE}📋 $cmd${NC} ${GREEN}$name${NC} at ${YELLOW}$path${NC}"
    
    if [ ! -d "$path" ]; then
        echo -e "${RED}❌ Path not found: $path${NC}"
        return 1
    fi

    cd "$path"
    
    # Clean cache for fresh runs
    if [ "$cmd" != "validate" ]; then
        rm -rf .terragrunt-cache
    fi

    case $cmd in
        init)
            terragrunt init
            ;;
        validate)
            terragrunt validate
            ;;
        plan)
            terragrunt init
            terragrunt plan
            ;;
        deploy)
            terragrunt init
            terragrunt apply -auto-approve
            [ -n "$component" ] && mark_deployed "$component"
            ;;
        destroy)
            terragrunt destroy -auto-approve
            [ -n "$component" ] && mark_destroyed "$component"
            ;;
        *)
            echo -e "${RED}❌ Invalid command: $cmd${NC}"
            cd - > /dev/null
            exit 1
            ;;
    esac
    
    cd - > /dev/null
    echo -e "${GREEN}✅ $name $cmd complete${NC}"
}

# -------------------------------
# Component Arrays for Filtering
# -------------------------------
declare -a ALL_REGIONS=("us-east-1" "us-west-2" "eu-west-1")
declare -a ALL_CLUSTERS=("app-cluster" "management-cluster")

get_filtered_paths() {
    local component_type=$1
    local paths=()
    
    for region in "${ALL_REGIONS[@]}"; do
        if [ -n "$REGION_FILTER" ] && [ "$region" != "$REGION_FILTER" ]; then
            continue
        fi
        
        for cluster in "${ALL_CLUSTERS[@]}"; do
            if [ -n "$CLUSTER_FILTER" ] && [ "$cluster" != "$CLUSTER_FILTER" ]; then
                continue
            fi
            
            # Skip management-cluster for non us-east-1 regions
            if [ "$cluster" = "management-cluster" ] && [ "$region" != "us-east-1" ]; then
                continue
            fi
            
            local path="$region/$cluster/$component_type"
            if [ -d "$path" ]; then
                paths+=("$path")
            fi
        done
    done
    
    printf '%s\n' "${paths[@]}"
}

# -------------------------------
# Enhanced Modular Functions
# -------------------------------
deploy_s3_backend() {
    check_dependencies "s3-backend"
    run_component "s3-backend" "Terraform Remote State (S3)" $MODE "s3-backend"
}

deploy_iam() {
    check_dependencies "iam"
    run_component "iam" "Global IAM Roles" $MODE "iam"
}

deploy_networking() {
    check_dependencies "networking"
    
    local paths
    readarray -t paths < <(get_filtered_paths "networking")
    
    if [ ${#paths[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No networking paths found for filters${NC}"
        return 0
    fi
    
    if [ "$PARALLEL" = true ] && [ "$MODE" != "destroy" ]; then
        echo -e "${BLUE}🔄 Running networking components in parallel${NC}"
        for path in "${paths[@]}"; do
            (
                name=$(echo "$path" | sed 's|/|-|g' | tr '[:lower:]' '[:upper:]')
                run_component "$path" "$name Networking" $MODE
            ) &
        done
        wait
    else
        for path in "${paths[@]}"; do
            name=$(echo "$path" | sed 's|/|-|g' | tr '[:lower:]' '[:upper:]')
            run_component "$path" "$name Networking" $MODE
        done
    fi
}

deploy_eks() {
    check_dependencies "eks"
    
    local paths
    readarray -t paths < <(get_filtered_paths "k8s")
    
    if [ ${#paths[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No EKS paths found for filters${NC}"
        return 0
    fi
    
    if [ "$PARALLEL" = true ] && [ "$MODE" != "destroy" ]; then
        echo -e "${BLUE}🔄 Running EKS components in parallel${NC}"
        for path in "${paths[@]}"; do
            (
                name=$(echo "$path" | sed 's|/|-|g' | sed 's|-k8s||' | tr '[:lower:]' '[:upper:]')
                run_component "$path" "$name EKS Cluster" $MODE
            ) &
        done
        wait
    else
        for path in "${paths[@]}"; do
            name=$(echo "$path" | sed 's|/|-|g' | sed 's|-k8s||' | tr '[:lower:]' '[:upper:]')
            run_component "$path" "$name EKS Cluster" $MODE
        done
    fi
}

deploy_region() {
    if [ -z "$REGION_FILTER" ]; then
        echo -e "${RED}❌ --region required for region deployment${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🌍 Deploying all components for region: ${YELLOW}$REGION_FILTER${NC}"
    deploy_networking
    deploy_eks
}

deploy_infra() {
    echo -e "${BLUE}🏗️  Deploying infrastructure components with dependency management${NC}"
    deploy_iam
    deploy_networking
    deploy_eks
    mark_deployed "infra"
}

# -------------------------------
# Destroy Order (reverse dependencies)
# -------------------------------
destroy_infra() {
    echo -e "${RED}🔥 Destroying infrastructure in reverse dependency order${NC}"
    # EKS first (depends on networking)
    deploy_eks
    # Networking second (depends on IAM)  
    deploy_networking
    # IAM last (depends on s3-backend)
    deploy_iam
    mark_destroyed "infra"
}

destroy_all() {
    echo -e "${RED}🔥 Destroying all components in reverse dependency order${NC}"
    # EKS clusters first
    deploy_eks
    # Networking second
    deploy_networking  
    # IAM third
    deploy_iam
    # S3 backend last (everything depends on it)
    deploy_s3_backend
}

# -------------------------------
# Main Logic
# -------------------------------
echo -e "${BLUE}📊 Configuration Summary:${NC}"
echo -e "  Mode: ${YELLOW}$MODE${NC}"
echo -e "  Components: ${YELLOW}$COMPONENTS${NC}"
[ -n "$REGION_FILTER" ] && echo -e "  Region Filter: ${YELLOW}$REGION_FILTER${NC}"
[ -n "$CLUSTER_FILTER" ] && echo -e "  Cluster Filter: ${YELLOW}$CLUSTER_FILTER${NC}"
[ "$DRY_RUN" = true ] && echo -e "  ${BLUE}Dry Run Mode${NC}"
[ "$PARALLEL" = true ] && echo -e "  ${BLUE}Parallel Execution${NC}"
[ "$SKIP_DEPS" = true ] && echo -e "  ${YELLOW}Skipping Dependencies${NC}"
echo ""

case $COMPONENTS in
    s3-backend)
        deploy_s3_backend
        ;;
    iam)
        deploy_iam
        ;;
    networking)
        deploy_networking
        ;;
    eks)
        deploy_eks
        ;;
    region)
        if [ "$MODE" = "destroy" ]; then
            # Destroy EKS first, then networking for the region
            deploy_eks
            deploy_networking
        else
            deploy_region
        fi
        ;;
    infra)
        if [ "$MODE" = "destroy" ]; then
            destroy_infra
        else
            deploy_infra
        fi
        ;;
    all)
        if [ "$MODE" = "destroy" ]; then
            destroy_all
        else
            deploy_s3_backend
            deploy_infra
            mark_deployed "all"
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid component: $COMPONENTS${NC}"
        echo -e "${YELLOW}Valid components: s3-backend, iam, networking, eks, region, infra, all${NC}"
        show_help
        exit 1
        ;;
esac

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}🔍 Dry run completed - no changes made${NC}"
else
    echo -e "${GREEN}🎉 Component(s) $MODE completed successfully!${NC}"
fi
