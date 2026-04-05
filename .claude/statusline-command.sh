#!/usr/bin/env bash
input=$(cat)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.id // empty')

# Build model label
if [ -n "$model" ]; then
  model_label="[${model}] "
else
  model_label=""
fi

# Default to 0 if no context data yet
if [ -z "$used" ]; then
  used="0"
fi

used_int=$(printf '%.0f' "$used")

# Determine color based on usage percentage
if [ "$used_int" -lt 50 ]; then
  color="\033[32m"   # green
elif [ "$used_int" -lt 80 ]; then
  color="\033[33m"   # yellow
else
  color="\033[31m"   # red
fi

reset="\033[0m"

# Build 10-character ASCII progress bar
bar_width=10
filled=$(( used_int * bar_width / 100 ))
empty=$(( bar_width - filled ))

bar=""
i=0
while [ "$i" -lt "$filled" ]; do
  bar="${bar}█"
  i=$(( i + 1 ))
done
while [ "$i" -lt "$bar_width" ]; do
  bar="${bar}░"
  i=$(( i + 1 ))
done

printf "%s${color}[${bar} ${used_int}%%]${reset}" "$model_label"
