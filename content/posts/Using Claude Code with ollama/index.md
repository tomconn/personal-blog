---
title: "Using Claude Code with Ollama"
date: 2026-03-26T09:00:00Z
draft: false # publish
tags: ["GenAI", "Ollama", "Anthropic", "Claude Code", "Local LLM"]
---

Running Large Language Models (LLMs) locally has become increasingly accessible, and combining this with Claude Code opens up powerful possibilities for AI-assisted development without relying on cloud services. In this post, I'll walk through setting up Ollama to run LLMs locally and how to integrate it with Claude Code.

## Installing Ollama

Ollama is a lightweight tool for running LLMs locally. Installation is straightforward on macOS:

```bash
brew install ollama
```

For other operating systems, refer to the [official Ollama installation guide](https://github.com/ollama/ollama).

## Installing the Claude CLI

The Anthropic Claude CLI can be installed via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

## Running the Ollama Server

Once Ollama is installed, you can start the server. The script below handles this automatically, but for manual control:

```bash
ollama serve
```

The server runs on port 11434 by default.

## Pulling a Model

Before using a model, you need to pull it. For a local model like Qwen3.5:

```bash
ollama pull qwen3.5:9b
```

Or if you have an [Ollama account](https://ollama.com) and want to use cloud-hosted models:

```bash
ollama pull minimax-m2.7:cloud
```

## The Wrapper Script

I created a wrapper script that ties everything together. It starts the Ollama server if not already running, pulls the specified model, configures the required environment variables, and launches Claude Code with the selected model:

```bash
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
```

## Usage

Make the script executable and run it with your chosen model:

```bash
chmod +x ollama-claude.sh

# For a local model
./ollama-claude.sh -m qwen3.5:9b "Explain this code for me"

# For a cloud model via Ollama
./ollama-claude.sh -m minimax-m2.7:cloud "Help me refactor this function"
```

## Selecting the Right Model

- **Local models (e.g., `qwen3.5:9b`)**: Run entirely on your machine, no internet required, and free to use. Performance depends on your hardware.
- **Cloud models (e.g., `minimax-m2.7:cloud`)**: Require an Ollama account and internet connection, but typically offer better performance and larger context windows.

## Summary

Combining Claude Code with Ollama gives you the best of both worlds: the powerful AI-assisted development experience of Claude Code running on top of locally-hosted or cloud-hosted LLMs through Ollama. Whether you prefer the privacy and cost benefits of local models or the raw power of cloud-hosted ones, this setup provides flexibility for different use cases.

The wrapper script automates the boilerplate, letting you focus on actually using the AI rather than managing infrastructure.
