# localstack cliインストール
## 前提
### 環境
WSL2 ubuntu上で実施

### 事前にDockerはインストール済み
```
$ docker -v
Docker version 24.0.1, build 6802122
```
古い？w  


## CLIをインストール
### tar.gzをダウンロード
```
$ curl --output localstack-cli-4.0.0-linux-amd64-onefile.tar.gz \
    --location https://github.com/localstack/localstack-cli/releases/download/v4.0.0/localstack-cli-4.0.0-linux-amd64-onefile.tar.gz
```

### 展開
```
$ sudo tar xvzf localstack-cli-4.0.0-linux-*-onefile.tar.gz -C /usr/local/bin
```

### インストール確認
```
$ localstack -v
LocalStack CLI 4.0.0
```

## localstack実行してみる
```
$ localstack start

     __                     _______ __             __
    / /   ____  _________ _/ / ___// /_____ ______/ /__
   / /   / __ \/ ___/ __ `/ /\__ \/ __/ __ `/ ___/ //_/
  / /___/ /_/ / /__/ /_/ / /___/ / /_/ /_/ / /__/ ,<
 /_____/\____/\___/\__,_/_//____/\__/\__,_/\___/_/|_|

 💻 LocalStack CLI 4.0.0
 👤 Profile: default

[09:08:50] starting LocalStack in Docker mode 🐳                                          localstack.py:510           container image not found on host                                              bootstrap.py:1297[09:10:36] download complete                                                              bootstrap.py:1301────────────────────────────── LocalStack Runtime Log (press CTRL-C to quit) ──────────────────────────────

LocalStack version: 4.0.4.dev99     
LocalStack build date: 2025-01-10   
LocalStack build git hash: 9f208afdf

Ready.
```

Readyいうてるしできたのか？

```
$ docker ps                                    
CONTAINER ID   IMAGE                   COMMAND                  CREATED         STATUS                   PORTS                                                                    NAMES
b4399ab3d35f   localstack/localstack   "docker-entrypoint.sh"   5 minutes ago   Up 5 minutes (healthy)   127.0.0.1:4510-4560->4510-4560/tcp, 127.0.0.1:4566->4566/tcp, 5678/tcp   localstack-main
```
なんかいるな

## awslocalもインストールする
https://docs.localstack.cloud/user-guide/integrations/aws-cli/#localstack-aws-cli-awslocal  
aws cliを都度個別設定するのは面倒なので、cliの向き先をlocalstackにするラッパーライブラリを使用する  

### インストール実行
```
$ pip install awscli-local[ver1]
(略)
Successfully installed awscli-1.36.38 awscli-local-0.22.0 botocore-1.35.97 docutils-0.16 localstack-client-2.7 rsa-4.7.2 urllib3-1.26.20
```

### インストール確認
```
$ awslocal --version
aws-cli/1.36.38 Python/3.8.10 Linux/5.4.72-microsoft-standard-WSL2 botocore/1.35.97
```

### テスト実行
```
$ awslocal sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",      
    "Account": "000000000000",
    "Arn": "arn:aws:iam::000000000000:root"
}
```

良い感じ

## awslocalでlocalstackにコマンドを実行
S3バケット一覧を確認

```
$ awslocal s3 ls
(プロセス帰ってくる。バケットなし)
```

S3バケットを作成  
cliで作成する場合は微妙な落とし穴あるので注意  
https://qiita.com/eyuta/items/3f39536aae51cdf0d197

```
$ awslocal s3api create-bucket --bucket my-local-bucket  --create-bucket-configuration LocationConstraint=ap-northeast-1
{
    "Location": "http://my-local-bucket.s3.localhost.localstack.cloud:4566/"
}
```

できた！！
```
$ awslocal s3 ls
2025-01-11 09:29:37 my-local-bucket
```