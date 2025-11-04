# RoomFinder

教室までのルートを案内するアプリです。

## Todo　（↑↓優先順）

・スムーズな自動階層遷移（1F->nF） (Easing?
・ナビゲーション表示方法の再検討
・選択要素のピン表示
・データ管理をfirebaseに切り替え
・検索部屋数の制限　'もっと探す!'追加
・階層表示をInteractiveViewer内にStack
・外部からのナビゲーション呼び出し
・jsonファイルの自動上書き・更新

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
