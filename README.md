# 25/12/09更新
# セキュリティが怖いのでfirebase書き込みを一時的に完全停止しました。
# RoomFinder

教室までのルートを案内するアプリです。

## Todo　（↑↓優先順）
・外部からのナビゲーション呼び出し

コンスタント
・致命エラー対策
・パフォーマンス改善
・UI改善
・アニメーション追加
・建物の登録

### My Memo
flutter pub run build_runner watch --delete-conflicting-outputs
git checkout main
git fetch origin
git pull origin main
git branch -d 
flutter build web ./lib/main_tamanavi.dart
firebase deploy --only hosting
