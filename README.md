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

cpしてみる
```
$ awslocal s3 cp README.md s3://my-local-bucket/
upload: ./README.md to s3://my-local-bucket/README.md
```

lsしてみる
```
$ awslocal s3 ls my-local-bucket
2025-01-12 09:52:22       3614 README.md
```

# aws sdkでlocalstackで作成したリソースを参照する
## 準備
### package.jsonの準備
とりあえずテスト用に ```@aws-sdk/client-s3``` とローカル実行用に ```tsx``` を準備  
  
```package.json
{
  "name": "localstack-hello-world",
  "version": "1.0.0",
  "description": "WSL2 ubuntu上で実施",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "@aws-sdk/client-s3": "^3.726.1",
    "tsx": "^4.19.2"
  }
}
```

### 必要なライブラリのインストール
```
$ npm i
```

### サンプルコードの準備

該当リージョンのバケットをリスト表示するサンプル  
```sample/sampleListBuckets.ts
import { S3Client, ListBucketsCommand } from '@aws-sdk/client-s3';

// LocalStack用のS3クライアント
const s3Client = new S3Client({
    endpoint: 'http://localhost:4566',
    // forcePathStyle: true, // ListBucketsはバケットを指定しないため、バケットの名前解決の意識は不要
    region: 'ap-northeast-1',
    credentials: {
        accessKeyId: 'dummy',
        secretAccessKey: 'dummy'
    },
});

async function listBuckets() {
    try {
        const command = new ListBucketsCommand({});
        const response = await s3Client.send(command);

        console.log('S3 Buckets:');
        response.Buckets?.forEach(bucket => {
            console.log(`- ${bucket.Name} (created: ${bucket.CreationDate})`);
        });

        return response.Buckets;

    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}

// 実行
listBuckets()
    .then(() => console.log('Done'))
    .catch(err => console.error('Failed:', err));
```
該当バケット内のオブジェクトをリスト表示するサンプル  

```sample/sampleListObjects.ts
import { S3Client, ListObjectsV2Command } from '@aws-sdk/client-s3';

// LocalStack用のS3クライアント
const s3Client = new S3Client({
  endpoint: 'http://localhost:4566',
  region: 'ap-northeast-1',
  credentials: {
    accessKeyId: 'dummy',
    secretAccessKey: 'dummy'
  },

  // バケット名をURLのパス部分に含める設定。
  // Virtual-Hostedスタイルではバケット名がホスト部分に含まれる:
  //   http://<bucket-name>.s3.<region>.amazonaws.com/<key-name>
  // Path-Styleではバケット名がパス部分に含まれる:
  //   http://<endpoint>/<bucket-name>/<key-name>
  // LocalStackでは、エンドポイントが「s3.」で始まる設定が不要なPath-Styleの方が
  // 簡潔で互換性が高いため、こちらを利用する
  forcePathStyle: true
});

async function listObjects(bucketName: string) {
  try {
    const command = new ListObjectsV2Command({
      Bucket: bucketName
    });

    const response = await s3Client.send(command);
    console.log('Objects in bucket:', response.Contents);
    return response.Contents;

  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}

// 実行
listObjects('my-local-bucket')
  .then(() => console.log('Done'))
  .catch(err => console.error('Failed:', err));
```

## 検証
```
$ npx tsx sample/sampleListBuckets.ts 
S3 Buckets:
- my-local-bucket (created: Sun Jan 12 2025 08:49:08 GMT+0900 (Japan Standard Time))
Done
```

```
$ npx tsx sample/sampleListObjects.ts 
Objects in bucket: [
  {
    Key: 'README.md',
    LastModified: 2025-01-12T00:52:22.000Z,
    ETag: '"4c851e47fddbbf6c32e38ec64ece05f9"',
    Size: 3614,
    StorageClass: 'STANDARD'
  }
]
Done
```

良い感じ！

## local環境のリソースの状態保存

https://docs.localstack.cloud/user-guide/state-management/cloud-pods/

### 有料だった
```
$ localstack pod save s3-test
👋 This feature is part of our paid offering!
=============================================
You tried to use a LocalStack feature that requires a paid subscription,
but the license activation has failed! 🔑❌

Reason: No credentials were found in the environment. Please make sure to
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.

Reason: No credentials were found in the environment. Please make sure to
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
If you are using the CLI, you can also run `localstack auth set-
token`.

Due to this error, LocalStack has quit.


Reason: No credentials were found in the environment. Please make sure to
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
If you are using the CLI, you can also run `localstack auth set-
token`.


Reason: No credentials were found in the environment. Please make sure to
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
Reason: No credentials were found in the environment. Please make sure to
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
either set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token.
If you are using the CLI, you can also run `localstack auth set-
token`.

Due to this error, LocalStack has quit.

- Please check that your credentials are set up correctly and that you have an active license.
  You can find your credentials in our webapp at https://app.localstack.cloud.
- If you haven't yet, sign up on the webapp and get a free trial!
```


### 弱い代替案だが、terraformでlocalstack環境のリソースを作成することが可能
https://docs.localstack.cloud/user-guide/integrations/terraform/

```terraform-local/main.tf
############################################################################
## terraformブロック
############################################################################
terraform {
  # Terraformのバージョン指定
  required_version = "~> 1.7.0"

  # Terraformのaws用ライブラリのバージョン指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33.0"
    }
  }
}

############################################################################
## providerブロック
############################################################################
provider "aws" {
  # リージョンを指定
  region = "ap-northeast-1"

  # LocalStackを利用する場合の設定
  # https://docs.localstack.cloud/user-guide/integrations/terraform/
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
  }
}

locals {
  project = "localstack-terraform"
}

############################################################################
## resourceブロック
############################################################################
# Localstackでしか作れないような汎用的な名前のバケット
resource "aws_s3_bucket" "bucket" {
  bucket = "sample-bucket"
}
```


```
$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with   
the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.bucket will be created
  + resource "aws_s3_bucket" "bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "sample-bucket"
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags_all                    = (known after apply)
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
╷
│ Warning: AWS account ID not found for provider
│
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on main.tf line 20, in provider "aws":
│   20: provider "aws" {
│
│ See https://registry.terraform.io/providers/hashicorp/aws/latest/docs#skip_requesting_account_id for implications.  
╵

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.bucket: Creating...
aws_s3_bucket.bucket: Creation complete after 1s [id=sample-bucket]
╷
│ Warning: AWS account ID not found for provider
│
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on main.tf line 20, in provider "aws":
│   20: provider "aws" {
│
│ See https://registry.terraform.io/providers/hashicorp/aws/latest/docs#skip_requesting_account_id for implications.  
╵

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

しっかりリソースはできている

```
$ awslocal s3 ls
2025-01-13 08:56:43 test
2025-01-13 09:39:48 sample-bucket
```