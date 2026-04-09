#!/usr/bin/env bash
set -euo pipefail

YAML_FILE="$1"
OUTPUT_FILE="$2"
TARGET_REGISTRY="$3"

# 保存最终需要打包的镜像
SAVE_IMAGES=()
SRC_IMAGES=()

# 使用 process substitution 避免子 shell 问题
while read -r URL NAME VERSION LOCAL; do
  # 只处理 local 为 docker_image 的条目
  if [ "$LOCAL" != "docker_image" ]; then
    continue
  fi

  SRC_IMAGE="${URL}/${NAME}:${VERSION}"
  DST_IMAGE="${TARGET_REGISTRY}/${NAME}:${VERSION}"

  echo "Pull: $SRC_IMAGE"
  docker pull "$SRC_IMAGE"

  echo "Tag: $SRC_IMAGE -> $DST_IMAGE"
  docker tag "$SRC_IMAGE" "$DST_IMAGE"

  SAVE_IMAGES+=("$DST_IMAGE")
  SRC_IMAGES+=("$SRC_IMAGE")
done < <(awk '
  /^- name:/ {name=$3}
  /^  version:/ {version=$2}
  /^  origin_addr:/ {getline; match($0,/url: (.*)/,a); url=a[1]}
  /^  local:/ {local=$2; print url,name,version,local}
' "$YAML_FILE")

# 保存镜像到 tar 包
if [ ${#SAVE_IMAGES[@]} -eq 0 ]; then
  echo "没有需要打包的镜像，退出。"
  exit 0
fi

echo "Saving images to $OUTPUT_FILE ..."
docker save -o "$OUTPUT_FILE" "${SAVE_IMAGES[@]}"
echo "完成: $OUTPUT_FILE"