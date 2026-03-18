# main.tf - Crea un bucket S3 configurado como sitio web estático público.
# Incluye: bucket, hosting estático, permisos públicos, ACL y archivo index.html.

# --- Bucket S3 base ---
resource "aws_s3_bucket" "sitio" {
  bucket = var.bucket_name
}

# --- Habilita el hosting de sitio web estático ---
resource "aws_s3_bucket_website_configuration" "sitio" {
  bucket = aws_s3_bucket.sitio.id

  index_document {
    suffix = "index.html"
  }
}

# --- Permite que el dueño del bucket controle los ACLs ---
resource "aws_s3_bucket_ownership_controls" "sitio" {
  bucket = aws_s3_bucket.sitio.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# --- Desbloquea el acceso público (requerido para ACL public-read) ---
resource "aws_s3_bucket_public_access_block" "sitio" {
  bucket = aws_s3_bucket.sitio.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# --- Aplica ACL público de lectura al bucket ---
resource "aws_s3_bucket_acl" "sitio" {
  bucket = aws_s3_bucket.sitio.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.sitio,
    aws_s3_bucket_public_access_block.sitio,
  ]
}

# --- Sube el archivo index.html al bucket ---
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitio.id
  key          = "index.html"
  content_type = "text/html"
  acl          = "public-read"

  content = <<-HTML
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>Mi Sitio Estático</title>
    </head>
    <body>
      <h1>Hola Mundo desde S3</h1>
      <p>Página estática servida desde un bucket S3.</p>
    </body>
    </html>
  HTML

  depends_on = [
    aws_s3_bucket_public_access_block.sitio,
  ]
}
