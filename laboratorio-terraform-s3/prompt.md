Crea un proyecto Terraform básico en la carpeta laboratorio-terraform-s3 con los siguientes archivos:

main.tf — crea un bucket S3 en us-west-2 con:

Static website hosting habilitado (index_document = "index.html")
acl = "public-read" (o la política mínima necesaria para que sea público)
Un recurso aws_s3_object que suba un index.html con el contenido: <h1>Hola Mundo</h1>
El content_type del objeto debe ser text/html


variables.tf — define la variable bucket_name con un valor default como "mi-web-hola-mundo"
outputs.tf — muestra el endpoint del sitio estático al finalizar el apply
providers.tf — configura el provider aws con region = "us-west-2"

Requisitos:

Terraform >= 1.0
Sin módulos externos, sin backend remoto, sin estado compartido
Lo más simple posible, solo lo necesario para que funcione
Incluir comentarios breves en cada archivo explicando qué hace