#!/usr/bin/env bash
set -euo pipefail
# -------------------------------
# Colors
# -------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
# -------------------------------
# Usage
# -------------------------------
show_help() {
  echo "Usage: $0 [COMMAND] [COMPONENT] [OPTIONS]"
  echo ""
  echo "COMMAND:"
  echo "  plan     - Terragrunt plan"
  echo "  apply    - Terragrunt apply"
  echo "  destroy  - Terragrunt destroy"
  echo "  validate - Terragrunt validate"
  echo "  init     - Terragrunt init"
  echo ""
  echo "COMPONENT:"
  echo "  s3-backend | iam | networking | eks | infra | all"
  echo ""
  echo "OPTIONS:"
  echo "  --region REGION"
  echo "  --cluster CLUSTER"
  echo "  --dry-run"
  echo "  --parallel"
}
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi
# -------------------------------
# Args
# -------------------------------
COMMAND=${1:-plan}
COMPONENT=${2:-all}
REGION_FILTER=""
CLUSTER_FILTER=""
DRY_RUN=false
PARALLEL=false
shift 2 || true
while [[ $# -gt 0 ]]; do
  case $1 in
  --region)
    REGION_FILTER="$2"
    shift 2
    ;;
  --cluster)
    CLUSTER_FILTER="$2"
    shift 2
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --parallel)
    PARALLEL=true
    shift
    ;;
  *)
    echo -e "${RED}Unknown option: $1${RESET}"
    show_help
    exit 1
    ;;
  esac
done
# -------------------------------
# Regions & Clusters
# -------------------------------
ALL_REGIONS=("us-east-1" "us-west-2" "eu-west-1")
ALL_CLUSTERS=("app-cluster" "management-cluster")
TG_REGION_PATH=".terragrunt-regions"
get_paths() {
  local type=$1 paths=()
  for r in "${ALL_REGIONS[@]}"; do
    [[ -n "$REGION_FILTER" && "$r" != "$REGION_FILTER" ]] && continue
    for c in "${ALL_CLUSTERS[@]}"; do
      [[ -n "$CLUSTER_FILTER" && "$c" != "$CLUSTER_FILTER" ]] && continue
      local p="$r/$c/$type"
      [[ -d "$p" ]] && paths+=("$p")
    done
  done
  printf '%s\n' "${paths[@]}"
}
# -------------------------------
# Run component
# -------------------------------
run_component() {
  local dir="$1"
  [[ ! -f "$dir/terragrunt.hcl" && "$COMMAND" != "init" ]] && return
  echo -e "${GREEN}▶ Running terragrunt $COMMAND in $dir${RESET}"
  [[ -n "$REGION_FILTER" ]] && echo -e "   🌍 Region: $REGION_FILTER"
  [[ -n "$CLUSTER_FILTER" ]] && echo -e "   🏷 Cluster: $CLUSTER_FILTER"
  local flags=""
  if [[ "$COMMAND" == "apply" || "$COMMAND" == "destroy" ]]; then
    flags="-auto-approve"
  fi
  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN]${RESET} terragrunt $COMMAND $flags at $dir"
    return
  fi
  (cd "$dir" && terragrunt "$COMMAND" $flags)
}
# -------------------------------
# Deploy sequence (normal order)
# -------------------------------
run_all_normal() {
  # s3-backend
  [[ "$COMPONENT" == "all" || "$COMPONENT" == "s3-backend" ]] && run_component "s3-backend"
  # iam
  [[ "$COMPONENT" == "all" || "$COMPONENT" == "iam" ]] && run_component "iam"
  # networking
  if [[ "$COMPONENT" == "all" || "$COMPONENT" == "networking" || "$COMPONENT" == "infra" ]]; then
    readarray -t paths < <(get_paths "networking")
    for p in "${paths[@]}"; do run_component "$p"; done
  fi
  # eks / k8s
  if [[ "$COMPONENT" == "all" || "$COMPONENT" == "eks" || "$COMPONENT" == "infra" ]]; then
    readarray -t paths < <(get_paths "k8s")
    for p in "${paths[@]}"; do run_component "$p"; done
  fi
}
# -------------------------------
# Destroy sequence (reverse order)
# -------------------------------
run_all_destroy() {
  # eks / k8s (destroy first)
  if [[ "$COMPONENT" == "all" || "$COMPONENT" == "eks" || "$COMPONENT" == "infra" ]]; then
    readarray -t paths < <(get_paths "k8s")
    for p in "${paths[@]}"; do run_component "$p"; done
  fi
  # networking
  if [[ "$COMPONENT" == "all" || "$COMPONENT" == "networking" || "$COMPONENT" == "infra" ]]; then
    readarray -t paths < <(get_paths "networking")
    for p in "${paths[@]}"; do run_component "$p"; done
  fi
  # iam
  [[ "$COMPONENT" == "all" || "$COMPONENT" == "iam" ]] && run_component "iam"
  # s3-backend (destroy last)
  [[ "$COMPONENT" == "all" || "$COMPONENT" == "s3-backend" ]] && run_component "s3-backend"
}
# -------------------------------
# Main execution logic
# -------------------------------
run_all() {
  if [[ "$COMMAND" == "destroy" ]]; then
    echo -e "${YELLOW}⚠️  Using reverse order for destroy command${RESET}"
    echo -e "${YELLOW}   Destroy sequence: k8s → networking → iam → s3-backend${RESET}"
    echo ""
    run_all_destroy
  else
    run_all_normal
  fi
}
# -------------------------------
# Main
# -------------------------------
echo -e "${BLUE}🚀 Starting Terragrunt $COMMAND${RESET}"
[[ -n "$REGION_FILTER" ]] && echo -e "   🌍 Region: $REGION_FILTER"
echo -e "   📦 Component: $COMPONENT"
echo ""
run_all
echo -e "${GREEN}✅ Terragrunt $COMMAND completed!${RESET}"
