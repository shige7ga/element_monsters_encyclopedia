# 作業方針

- 出力は日本語で行う。
- ファイルの削除は行わない。
- WSL環境で新しいファイルを作成した後は、ホスト側で編集できるよう `sudo chown -R $USER:$USER ./` を実行して所有者を更新する。
- ビューを作成・編集する際は、ERBのインデントを整え、実装の役割が分かるコメントを各セクションに記載する。

## 技術構成

- Ruby 3.4系、Rails 8.1系、PostgreSQL、Tailwind CSS、Deviseを使用する。
- 画像アップロードはActive Storageを窓口とし、Cloudinaryをストレージバックエンドとして使用する。
- テストはRSpecとFactoryBotを使用して統一する。
- Solid Queueはprimary DBを使用し、必要なテーブルは通常のdb:migrateで管理する。

## Tailwind CSS・アセット管理

- Tailwind CSSはNode.js版（Tailwind CSS v4）と`cssbundling-rails`で管理し、`tailwindcss-rails` gemは使用しない。
- CSSの入力ファイルは`app/assets/stylesheets/application.tailwind.css`、出力ファイルは`app/assets/builds/application.css`とする。
- 開発時のCSS監視には`yarn build:css --watch`を使用し、通常の開発サーバー起動には`bin/dev`を使用する。
- レイアウトではビルド済みの`application.css`のみを読み込む。`@import "tailwindcss";`を入力ファイル以外へ書かず、未処理のままブラウザへ配信しない。
- Tailwind CSSの別方式を追加せず、Node.js版Tailwindと`cssbundling-rails`の構成を維持する。
- UIは原則daisyUIコンポーネントを優先し、daisyUIで不足する場合のみTailwind Utilityを併用する。
- daisyUIを利用する場合も、既存のブランドカラー・デザイン方針を維持する。
- 新規UIで独自CSSを増やす前にdaisyUIコンポーネントを検討し、不要な全面リデザインは行わない。

## 画像管理

- 画像のアップロード、添付、バリデーションはActive Storageで管理し、`has_one_attached`、`has_many_attached`、Active Storageのヘルパーやvariantを使用する。
- Cloudinaryは保存先、画像変換、CDN配信に使用し、アプリケーションコードからCloudinary APIを直接呼び出さない。
- `config/storage.yml`には接続情報を環境変数経由で設定し、APIキーなどの秘密情報を直接記載しない。
- 本番環境は`config.active_storage.service = :cloudinary`を使用し、Cloudinary gemがRenderの`CLOUDINARY_URL`から認証情報を取得する。開発・テスト環境はDiskサービスを維持する。
- 添付画像を持つ投稿を削除する場合は、レコード削除前にActive Storageの`purge`を実行し、保存先の画像も同期的に削除する。

## 認証情報と環境変数

- Docker Composeによる開発環境では`.env`をComposeが読み込むため、アプリで必要な値は`compose.yml`で`web`サービスへ明示的に渡す。Dockerを介さずRailsを起動する場合は、`dotenv-rails`を導入して`.env`を読み込む。
- `.env`はGit管理せず、`.env.example`には変数名のみを記載して実値を含めない。本番環境では`.env`と同じ変数をデプロイ基盤の環境変数として設定する。
- 秘密情報をアプリケーションコード、Git管理対象の設定、ログ、エラー画面、コミット、プルリクエスト、Issue、テストコード、スクリーンショットに記載しない。漏えい時は無効化・ローテーション・再設定・動作確認を行う。

## アップロードの安全性

- 画像は拡張子ではなくMIMEタイプで検証し、`image/jpeg`、`image/png`、`image/webp`のみを許可する。
- 機能ごとにファイルサイズ上限を設定し、無制限アップロードを許可しない。
- アップロード・変更・削除は認可と所有者確認を行う。認可が必要な機能ではPunditの導入を検討する。
- ブラウザからCloudinaryへ直接アップロードする場合は署名付きアップロードのみを使用し、未署名アップロード、クライアントへのAPI Secretや署名生成処理の露出を禁止する。

## 実装と検証の進め方

- 変更前に関連するモデル、コントローラー、ビュー、ルーティング、マイグレーション、テスト、設定を確認し、既存の命名・設計に沿って必要な範囲だけを変更する。
- 実装前に、機能概要、変更・作成ファイル、ファイルごとの変更内容、データベース変更、テスト、確認方法を共有する。
- 機能は一度に一つずつ実装し、動作確認とテストを終えてから次の機能へ進む。
- 実装後は、変更・作成ファイル、ファイルごとの変更内容、実現した挙動、テスト結果、ブラウザ確認結果を共有する。
- テストでは正常系に加え、バリデーション、権限、境界値、エラー表示を確認する。

## Git運用

- ファイルの作成・編集・削除など、フォルダ内の構成に変更を加える作業を始める前に、作業用のGitブランチを作成して切り替える。
- ユーザーから`git push`と指示されるまでは、同じ作業ブランチで作業を継続する。
- ひとまとまりの編集が完了したら、コミットするかどうかをユーザーに確認する。
- ユーザーから`git ci`と指示された場合は、変更内容が分かる適切なコミットメッセージを付けてコミットする。
- ユーザーから`git push`と指示された場合のみ、リモートリポジトリへpushし、プルリクエストのタイトルと概要を出力する。
- ユーザーから`git pull`と指示された場合は、`main`ブランチへ切り替えてリモートリポジトリから最新状態をpullし、ローカルの作業ブランチを削除する。
