#!/bin/bash
set -e

MODEL=""
HELP=""

while getopts ":m:h" opt; do
  case $opt in
    m) MODEL="$OPTARG" ;;
    h) HELP="yes" ;;
    :) echo "Option -$OPTARG requires a model argument" >&2; exit 1 ;;
    *) echo "Unknown option -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [ -n "$HELP" ] || [ -z "$MODEL" ]; then
    echo "Usage: $0 -m <model> [--dangerously-skip-permissions] [-p] <prompt>"
    echo "  -m <model>   Model to use (required)"
    echo "  -h           Show this help"
    exit 0
fi

if ! lsof -i :11434 2>/dev/null | grep -q LISTEN; then
    ollama serve &
    OLLAMA_PID=$!
else
    OLLAMA_PID=""
fi

ollama pull "$MODEL" 2>/dev/null || true

sleep 2

# Verify model exists before starting Claude
if ! ollama list | tail -n +2 | awk '{print $1}' | grep -q "^${MODEL}$"; then
    echo "ERROR: Model $MODEL not found"
    [ -n "$OLLAMA_PID" ] && kill $OLLAMA_PID 2>/dev/null || true
    exit 1
fi

export ANTHROPIC_BASE_URL="http://127.0.0.1:11434"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY=""

claude --model "$MODEL" "${@}"

if [ -n "$OLLAMA_PID" ]; then
    kill $OLLAMA_PID 2>/dev/null || true
fi
