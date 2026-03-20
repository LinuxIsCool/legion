#!/usr/bin/env bash
# lib/recipe-runner.sh — parse profile, run recipes in order

# Simple TOML array parser — extracts recipe names from profiles
parse_recipes() {
    local profile_path="$1"
    # Extract the recipes array — handles multiline TOML arrays
    local in_recipes=false
    local recipes=()

    while IFS= read -r line; do
        # Strip comments and whitespace
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [[ -z "$line" ]] && continue

        if [[ "$line" == recipes* ]]; then
            in_recipes=true
            # Handle single-line: recipes = ["a", "b", "c"]
            if [[ "$line" == *"]"* ]]; then
                local values
                values="$(echo "$line" | sed 's/.*\[//' | sed 's/\]//' | tr ',' '\n')"
                while IFS= read -r val; do
                    val="$(echo "$val" | tr -d '"' | tr -d "'" | xargs)"
                    [[ -n "$val" ]] && recipes+=("$val")
                done <<< "$values"
                in_recipes=false
            fi
            continue
        fi

        if $in_recipes; then
            if [[ "$line" == "]"* ]]; then
                in_recipes=false
                continue
            fi
            # Split comma-separated values on this line
            local csv
            csv="$(echo "$line" | tr ',' '\n')"
            while IFS= read -r val; do
                val="$(echo "$val" | tr -d '"' | tr -d "'" | xargs)"
                [[ -n "$val" ]] && recipes+=("$val")
            done <<< "$csv"
        fi
    done < "$profile_path"

    printf '%s\n' "${recipes[@]}"
}

run_profile() {
    local profile_path="$1"
    local recipes_dir="$2"
    local dry_run="${3:-false}"

    local profile_name
    profile_name="$(basename "$profile_path" .toml)"

    log_step "Running profile: ${profile_name}"

    local recipes
    mapfile -t recipes < <(parse_recipes "$profile_path")

    if [[ ${#recipes[@]} -eq 0 ]]; then
        log_fail "No recipes found in ${profile_path}"
        return 1
    fi

    log_info "Recipes (${#recipes[@]}): ${recipes[*]}"
    echo ""

    local failed=0
    local skipped=0
    local completed=0

    for recipe_name in "${recipes[@]}"; do
        local recipe_path="${recipes_dir}/recipe-${recipe_name}.sh"

        if [[ ! -f "$recipe_path" ]]; then
            log_fail "Recipe not found: recipe-${recipe_name}.sh"
            ((failed++))
            continue
        fi

        if [[ "$dry_run" == "true" ]]; then
            log_info "[dry-run] Would run: recipe-${recipe_name}.sh"
            continue
        fi

        log_step "Recipe: ${recipe_name}"

        if bash "$recipe_path"; then
            ((completed++))
        else
            log_fail "Recipe failed: ${recipe_name}"
            ((failed++))
        fi
    done

    echo ""
    log_step "Summary"
    log_info "Completed: ${completed}  Skipped: ${skipped}  Failed: ${failed}"

    if [[ $failed -gt 0 ]]; then
        log_fail "Some recipes failed — check output above"
        return 1
    fi

    log_ok "All recipes completed successfully"
}
