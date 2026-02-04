# Claude Code ガイドライン

## Agents 一覧

| ファイル | 内容 |
|---------|------|
| `agents/code-reviewer.md` | コードレビュー、セキュリティ/品質/パフォーマンスチェック |
| `agents/debug-browser.md` | ブラウザ操作+サーバーログ監視による自律デバッグ |
| `agents/nuxt4-coder.md` | Nuxt 4コーディング専門。Composition API/TypeScript/Nitro、レイヤー責務(api→services→repositories)、ファイル命名規則、Vueスタイルガイド |

## Rules 一覧

| ファイル | 内容 |
|---------|------|
| `rules/agents.md` | エージェントオーケストレーション、並列実行、code-reviewer使用 |
| `rules/performance.md` | DB最適化、キャッシュ、API設計、リソース管理 |
| `rules/security.md` | セキュリティチェック、シークレット管理、脆弱性対策 |

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:

1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes
