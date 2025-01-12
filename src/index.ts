import { S3Client, ListBucketsCommand } from '@aws-sdk/client-s3';

// LocalStack用のS3クライアント
const s3Client = new S3Client(
    process.env.ENV === "local" ? {
        endpoint: 'http://localhost:4566',
        region: 'ap-northeast-1',
        credentials: {
            accessKeyId: 'dummy',
            secretAccessKey: 'dummy'
        },
        // forcePathStyle: true, // ListBucketsはバケットを指定しないため、バケットの名前解決の意識は不要
    } : {}
);

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

export const handler = async () => {
    // 実行
    await listBuckets()
        .then(() => console.log('Done'))
        .catch(err => console.error('Failed:', err));
};
