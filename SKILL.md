---
name: aws-architecture-diagram
description: Use when creating AWS system architecture diagrams with draw.io MCP. Triggers - user asks for system diagram, architecture visualization, or infrastructure overview.
---

# AWS Architecture Diagram

draw.io MCPを使用して、AWS公式アイコンスタイルのシステム構成図を作成するスキル。

## Prerequisites

draw.io MCPが設定されていること:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@drawio/mcp"]
    }
  }
}
```

## Quick Reference

| サービス | 色 | fillColor |
|----------|-----|-----------|
| Cognito (認証) | 赤 | #C7131F |
| AppSync (API) | ピンク | #BC1356 |
| Amplify | ピンク | #BC1356 |
| DynamoDB | 青 | #3334B9 |
| Lambda | オレンジ | #D05C17 |
| Translate/Bedrock (AI) | 緑 | #116D5B |
| S3 | 緑 | #3F8624 |
| CloudFront | 紫 | #8C4FFF |

## Core Pattern

### 1. AWS Cloudコンテナを配置

```xml
<mxCell value="" style="shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_aws_cloud;strokeColor=#232F3E;fillColor=none;" />
```

### 2. サービスアイコンを配置

```xml
<mxCell value="" style="shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.{service};fillColor={color};strokeColor=#ffffff;gradientColor={gradientColor};gradientDirection=north;" />
```

利用可能なアイコン: `cognito`, `appsync`, `amplify`, `dynamodb`, `lambda`, `translate`, `bedrock`, `s3`, `cloudfront`, `api_gateway`

### 3. グループボックスで囲む

```xml
<mxCell value="グループ名" style="fillColor=none;strokeColor={color};dashed=1;verticalAlign=top;fontStyle=1;fontColor={color};strokeWidth=2;" />
```

### 4. 矢印で接続

```xml
<mxCell style="edgeStyle=orthogonalEdgeStyle;rounded=0;strokeWidth=2;strokeColor=#666666;" edge="1" source="{sourceId}" target="{targetId}" />
```

## Workflow

1. ユーザーにシステム構成をヒアリング
2. 使用するAWSサービスを特定
3. グループ分けを決定（認証層、API層、データ層、AI/ML層など）
4. XMLでdraw.io図を生成
5. `mcp__drawio__open_drawio_xml` で開く

## Layout Guidelines

```
┌─────────────────────────────────────────────────┐
│                  AWS Cloud                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ 認証層    │  │ API層    │  │ データ層  │      │
│  │ Cognito  │  │ AppSync  │  │ DynamoDB │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                      │                          │
│              ┌───────┴───────┐                  │
│  ┌──────────────────────────────────┐          │
│  │         サーバーレス処理           │          │
│  │   Lambda      Lambda      Lambda  │          │
│  └──────────────────────────────────┘          │
│                      │                          │
│  ┌──────────────────────────────────┐          │
│  │           AI/ML サービス          │          │
│  │   Translate    Bedrock    SageMaker│          │
│  └──────────────────────────────────┘          │
└─────────────────────────────────────────────────┘
          │
    ┌─────┴─────┐
┌───────────────────┐
│   外部サービス     │
│  YouTube  Twitch  │
└───────────────────┘
```

## Common Mistakes

| 問題 | 解決策 |
|------|--------|
| アイコンが表示されない | `shape=mxgraph.aws4.resourceIcon` を使用 |
| 色が違う | gradientColor と fillColor の両方を設定 |
| グループが小さい | geometry の width/height を調整 |
| 矢印が見えない | strokeWidth=2 以上に設定 |
