import os
import json
import boto3
import botocore
import io
from PIL import Image

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    # Only RESULT_BUCKET is passed as an environment variable
    result_bucket = os.environ.get('RESULT_BUCKET')
    # For local testing, allow reading from a local file if running outside AWS Lambda
    if os.environ.get('AWS_SAM_LOCAL') == 'true':
        test_image_path = os.environ.get('TEST_IMAGE_PATH', 'yellowparrot.jpeg')
        try:
            with open(test_image_path, 'rb') as f:
                image_content = f.read()
            key = os.path.basename(test_image_path)
        except Exception as e:
            print(f"Error reading local test image: {e}")
            return {'statusCode': 500, 'body': f'Error reading local test image: {e}'}
    else:
        s3 = boto3.client('s3')
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        try:
            response = s3.get_object(Bucket=bucket, Key=key)
            image_content = response['Body'].read()
            print(f"Fetched image from S3: {bucket}/{key}")
        except botocore.exceptions.ClientError as e:
            print(f"Error getting object from S3: {e}")
            return {'statusCode': 500, 'body': f'Error getting object: {e}'}

    # Use Rekognition to detect labels
    rekognition = boto3.client('rekognition', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
    try:
        rekog_response = rekognition.detect_labels(
            Image={'Bytes': image_content},
            MaxLabels=5,
            MinConfidence=70
        )
        print("Rekognition response:", rekog_response)
        labels = [label['Name'] for label in rekog_response['Labels']]
        description = f"Detected: {', '.join(labels)}"
    except Exception as e:
        print(f"Rekognition error: {e}")
        # Fallback to image size if Rekognition fails
        try:
            img = Image.open(io.BytesIO(image_content))
            description = f"Image size: {img.size[0]}x{img.size[1]}"
        except Exception as e2:
            print(f"Image processing error: {e2}")
            description = f"Could not process image: {e2}"

    # Use the same name as the source file, but with .json extension
    result_key = f"{os.path.splitext(os.path.basename(key))[0]}.json"
    result_body = json.dumps({'image': key, 'description': description})
    if os.environ.get('AWS_SAM_LOCAL') == 'true':
        # For local test, print result to console instead of writing to file
        print(result_body)
    else:
        try:
            s3.put_object(Bucket=result_bucket, Key=result_key, Body=result_body)
            print(f"Successfully wrote {result_key} to {result_bucket}")
        except Exception as e:
            print(f"Failed to write to S3: {e}")
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Processed', 'result_key': result_key, 'description': description})
    }
