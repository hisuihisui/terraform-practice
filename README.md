# terraform-practice
実践Terraform　AWSにおけるシステム設計とベストプラクティス

## 1. セットアップ
### 環境変数の設定

### terraformのインストール
https://hisuiblog.com/terraform-ubuntu-install/

### git-secretsのインストール
```
$ git clone https://github.com/awslabs/git-secrets.git
$ cd git-secrets
$ sudo make install
// sudo: make: command not found と表示されたら
sudo apt install make
make -version
```

## 2. 基本操作
### リソースの作成
1. リソースに必要なバイナリファイルをダウンロード
```
$ terraform init
```
2. 実行計画(これからなにが起きるのか)を出力
```
$ terraform plan

// 一部のみ
$ terraform plan --target=<リソース名>
```
3. 実行
```
$ terraform apply

// 一部のみ
$ terraform apply --target=<リソース名>
```
4. リソースの削除
```
$ terraform destroy

// 一部のみ
$ terraform destroy --target=<リソース名>
```

### コマンド実行時のメッセージ
1. (+) created：リソースの新規作成 <br>
2. (~) update in-place：既存リソースの更新 <br>
3. (-/+) replaced：既存リソースを削除して新しいリソースを作成 → サービスダウンの可能性あり <br>
4. (-) destroy：既存リソースの削除 <br>

### tfstateファイル
現在のリソースの状態を保存している <br>
  → tfstateファイルとHCLコードの差分のみを変更する

## HCL (HashiCorp Configuration Language)
・resource ：リソースを定義するブロック <br>

## 基本構文
### 変数
・宣言法
```
variable "<変数名>" {
  // 実行時に上書きしない場合に使用
  default = "<値>"
}
```
・呼び出し方
```
var.<変数名>
```
・コマンド実行時に変数上書き
```
$ terraform paln -var '<変数名>=<値>'
```
・環境変数に設定
```
$ TF_VAR_<変数名>=<値> terraform plan
```

### ローカル変数
・宣言方法
```
locals  {
  <変数名> = "<値>"
}
```
・呼び出し方
```
local.<変数名>
```
・variablesと違いコマンド実行時に上書き不可 <br>

### 出力値
・使い方
```
output "<変数名>" {
  value = <リソース>.<名前>.<プロパティ>
}
```
・モジュールから値を取得する際に使用可能


### データソース
・使い方
```
data "リソース" "変数名" {}
```
・filterなどで検索条件を指定可能

### プロバイダ
・AWS、GCP、Azure等のAPIの違いを吸収する <br>
・Terraform本体とは分離されている <br>
  → Terraform init コマンドでプロバイダのバイナリファイルをダウンロードする必要あり <br>
・使い方
```
provider "<名前>" {}
```

### 参照
TYPE.NAME.ATTRIBUTE の形式で他のリソースの値を参照できる

### 組み込み関数
文字列操作やコレクション操作、ファイル操作など、よくする処理が組み込み関数として提供されている

### モジュール
・定義：別ディレクトリを作成し、そこにmain.tfファイルを作成 <br>
・呼び出し方
```
module "name" {
  source = "path"
  parameter_name = value
}
```
・使い方
```
terraform init or terraform get
terraform plan
terraform apply
```

## 権限管理
### ポリシー
ポリシーの定義方法は2通り <br>
1. ポリシードキュメントというJSONファイルを作成 → AWSコンソールで登録するJSONと同じ <br>
2. aws_iam_policy_documentデータソース

## ストレージ
### S3バケットの削除
S3バケットを削除するには空になっている必要がある <br>
　→バケットにオブジェクトが残っていると terraform destroy しても削除できない <br>
　　→ force_destory = true に変更し、applyしたあとdestroyすると削除できる

## ドメイン
### Route53
・ドメインの登録はTerraformでは不可 <br>
　→前提：example.com を登録済み

## データストア
### スローapply問題
RDSやElastoCacheのappllyには時間がかかる

## Terraform ベストプラクティス
### 削除操作を抑止する
削除されると困るリソースに下記を記載 <br>
　→削除しようとするとエラーになる
```
lifecycle {
  prevent_destroy = true
}
```
※リソース定義全体を削除するとリソースが削除される点に注意

### コードフォーマットをかける
標準でコードフォーマット機能がある
```
$ terraform fmt

// サブディレクトリ含め再帰的にフォーマット
$ terraform fmt -recursive

// フォーマット済みかチェック
$ terraform fmt -recursive -check
 → 未フォーマットのコードがあると、Exit Codeが0以外になる
```

### バリデーションをかける
変数に値がセットされていなかったり、構文エラーを教えてくれる
```
$ terraform validate

// サブディレクトリ含め再帰的にバリデート
$ find . -type f -name '*. tf' -exec dirname {} \; | sort -u | xargs -I {} terraform validate {}
```
※バリデーション実行前にterraform init が必要

### オートコンプリート（タブ補完）を有効にする
```
$ terraform -install-autocomplete
```
上記実行後にシェルを再起動

### プラグインキャッシュを有効にする
プロバイダのバイナリファイルをキャッシュしておく
```
1. $ vi ~/.terraformrc
2. plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
3. $ mkdir -p "$HOME/.terraform.d/plugin-cache"
```

### TFLintで不正なコードを検出する
planコマンドでエラーにならない不正なコードを検出できる
```
// インストール
$
$ tflint --version

// 実行
$ tflint

// --deep でAWS APIを実行した詳細なチェック
$ tflint --deep --aws-region=ap-northeast-1
```

## 高度な構文
### 主要な組み込み関数
```
// 対話型
$ terraform console

$ exit
```

## tfstateファイルの管理
### ステートS3バケット
Terraformで使用するリソースはTerraform外部で管理されるべき <br>
 →CLIやコンソールで作成してみるなど
```
// バケット作成
$ aws s3 api create-bucket --bucket tfstate-pragmatic-terraform --create-bucket-configuration LocationConstraint=ap-northeast-1

// バージョニング設定
$ aws s3 api put-bucket-versioning --bucket tfstate-pragmatic-terraform --versioning-configuration Status=Enabled

// 暗号化設定
$ aws s3 api put-bucket-encryption --bucket tfstate-pragmatic-terraform \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
         " SSEAlgorithm": "AES256"
        }    
      }
    ]
  }'

// ブロックパブリックアクセス
$ aws s3 api put-public-access-block --bucket tfstate-pragmatic-terraform \
  --public-access-block-configuration '{
   "BlockPublicAcls": true,  
   "IgnorePublicAcls": true,  
   "BlockPublicPolicy": true,  
   "RestrictPublicBuckets": true
  }'

// 動作確認
terraform init
```
### Terraform Cloud
HashiCorp社のサービスでtfstateファイルの保存やロック、履歴管理が行える

## リソース参照パターン
tfstateファイルのリソースの参照方法

### リテラル
リソースIDをべた書きで指定

### リモートステート
リモートのストレージに保存されているtfstateファイルの値を参照する

### SSMパラメータストア連携
任意の値をグローバル変数のように扱える <br>
※SSMパラメータストアの値が正しい必要がある

### データソースと依存関係の分離
・各リソースに対応したデータソースを使ってリソースを参照 <br>
・存在しないリソースを指定するとplanでエラーになる <br>
・tfstateファイルやリソースの識別子に依存しない

### Data-only Modules
データソースのみ定義されたモジュール <br>
<br>
・メリット <br>
　1. モジュールの柔軟性 <br>
　　→ 出力値さえ定義すれば、リソースの参照方法は問わない <br>
　2. 入力値と出力値が明確に定義化され、ドキュメンテーションの面で利便性が高い <br>
　3. 異なるコードから呼び出せて、一貫性がある

## リファクタリング
・コード修正だけでなくtfstateファイルの操作を行う <br>
・使用したコマンドでtfstateファイルが変更されるかを意識する

### tfstateファイルのバックアップ
tfstateファイルを書き換えるので、バージョニング設定をしておくなど、状態を戻せるようにしておく

### ステートの参照
```
// 定義されているリソース一覧を参照
$ terraform state list

// idからリソースの逆引き
$ terraform state list -id=<value>

// リソースの詳細を参照
$ terraform state show <リソース名>

// tfstateファイルを標準出力する
$ terraform state pull
```

### ステートの上書き
・serialの変更が必要
```
// tfstateファイルを上書き
$ terraform state push <ファイル>
```
※tfstateファイルを直接書き換えるのはかなりリスクがたかい

### リソースをステート管理外にする
※実際にリソースが削除されるわけではない
```
$ terraform state rm <リソース名>
```

### リネーム
```
// リネーム
$ terraform state mv <リネーム前リソース名> <リネーム後リソース名>

// モジュールのリネームの場合は
$ terraform get
$ terraform plan
// で差分を確認できる
```

### tfstateファイル間の移動
※リスクが高いため、tfstateファイルのバックアップを作成しながら実施すること
```
// 特定のリソースをファイルに書き出す
// 元のtfstateファイルからは削除される
$ terraform state mv -state-out=<ファイル名> <移動前のリソース名> <移動後のリソース名>

// 移動先のtfstateファイルをコピー
$ terraform state pull > <ファイル名>

// tfstate間のリソース移動
$ terraform state mv -state=<移動前のファイル> -state-out=<移動後のファイル> <移動前のリソース名> <移動後のリソース名>

// 移動してきたリソースのプッシュ
$ terraform state push <pushするtfstateファイル>
```

## 既存リソースのインポート
### terraform import
```
// tfファイルに雛型は必要
// tfstateに書き込まれる→コードの修正が必要
$ terraform import <リソース名> <ID?>
```

### terraformer
一括でインポートしてくれるツールとして、terraformer, terraforming がある
