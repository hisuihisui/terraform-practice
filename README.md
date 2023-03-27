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
terraform init
```
2. 実行計画(これからなにが起きるのか)を出力
```
terraform plan
```
3. 実行
```
terraform apply
```
4. リソースの削除
```
terraform destroy
```

### コマンド実行時のメッセージ
1. (+) created：リソースの新規作成 <br>
2. (~) update in-place：既存リソースの更新 <br>
3. (-/+) replaced：既存リソースを削除して新しいリソースを作成 → サービスダウンの可能性あり <br>

### tfstateファイル
現在のリソースの状態を保存している <br>
  → tfstateファイルとHCLコードの差分のみを変更する

## HCL (HashiCorp Configuration Language)
・resource ：リソースを定義するブロック <br>
