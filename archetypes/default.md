---
title: "{{ if eq .File.ContentBaseName "index" }}{{ replace (path.Base .File.Dir) "-" " " | title }}{{ else }}{{ replace .File.ContentBaseName "-" " " | title }}{{ end }}"
date: {{ .Date }}
tags:
  - 学习
description: ""
---

