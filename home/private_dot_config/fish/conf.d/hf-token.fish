# HuggingFace token universal export.
# Source: ~/.claude/local/secrets/hf-token.env (chmod 600).
# Loaded into every fish shell so HF-aware tools (whisperx, pyannote,
# huggingface_hub, transformers, datasets, etc.) never prompt.
#
# Three env-var aliases cover the full HF tool surface:
#   - HF_TOKEN              (whisperx, modern HF tools)
#   - HUGGING_FACE_HUB_TOKEN (huggingface_hub library default)
#   - HUGGINGFACE_TOKEN     (legacy / some pyannote releases)

set -l _hf_env_file "$HOME/.claude/local/secrets/hf-token.env"

if test -f $_hf_env_file -a -r $_hf_env_file
    while read -l line
        # skip blanks + comments
        if test -z "$line"; or string match -q '#*' -- "$line"
            continue
        end
        # split KEY=VALUE
        set -l kv (string split -m1 '=' -- "$line")
        if test (count $kv) -eq 2
            set -gx $kv[1] $kv[2]
        end
    end < $_hf_env_file
end
