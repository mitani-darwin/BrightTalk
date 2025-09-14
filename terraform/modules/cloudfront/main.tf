# CloudFront distribution for video content acceleration
resource "aws_cloudfront_origin_access_control" "video_oac" {
  name                              = "${var.project_name}-${var.environment}-video-oac"
  description                       = "OAC for video content distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution for video streaming
resource "aws_cloudfront_distribution" "video_distribution" {
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_id                = "${var.project_name}-${var.environment}-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.video_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} ${var.environment} video content"
  default_root_object = ""

  # Default cache behavior for video content
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-${var.environment}-s3-origin"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    # Cache policy optimized for video streaming
    cache_policy_id = aws_cloudfront_cache_policy.video_cache_policy.id

    # Origin request policy for video content
    origin_request_policy_id = aws_cloudfront_origin_request_policy.video_origin_request_policy.id
  }

  # Specific cache behavior for video files
  ordered_cache_behavior {
    path_pattern           = "*.mp4"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-${var.environment}-s3-origin"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.video_cache_policy.id
  }

  ordered_cache_behavior {
    path_pattern           = "*.webm"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-${var.environment}-s3-origin"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.video_cache_policy.id
  }

  ordered_cache_behavior {
    path_pattern           = "*.mov"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project_name}-${var.environment}-s3-origin"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.video_cache_policy.id
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Price class for cost optimization
  price_class = var.price_class

  tags = {
    Name        = "${var.project_name}-${var.environment}-video-distribution"
    Environment = var.environment
    Purpose     = "Video content acceleration"
  }
}

# Custom cache policy for video content
resource "aws_cloudfront_cache_policy" "video_cache_policy" {
  name        = "${var.project_name}-${var.environment}-video-cache-policy"
  comment     = "Cache policy optimized for video streaming"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Range", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# Custom origin request policy for video content
resource "aws_cloudfront_origin_request_policy" "video_origin_request_policy" {
  name    = "${var.project_name}-${var.environment}-video-origin-request-policy"
  comment = "Origin request policy for video content"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Range", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
    }
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

# Update S3 bucket policy to allow CloudFront OAC access
resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.video_distribution.arn
          }
        }
      }
    ]
  })
}