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