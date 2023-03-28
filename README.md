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
```
3. 実行
```
$ terraform apply
```
4. リソースの削除
```
$ terraform destroy
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
