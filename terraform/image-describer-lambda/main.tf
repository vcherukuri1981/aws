resource "random_pet" "source_bucket" {}
resource "random_pet" "destination_bucket" {}

resource "aws_s3_bucket" "source" {
  bucket = "image-src-${random_pet.source_bucket.id}"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  bucket = "image-dest-${random_pet.destination_bucket.id}"
  force_destroy = true
}

