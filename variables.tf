variable "region" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘳𝘦𝘨𝘪𝘰𝘯 --->"

}

variable "access_key" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘢𝘤𝘤𝘦𝘴𝘴 𝘬𝘦𝘺 --->"

}

variable "secret_key" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘴𝘦𝘤𝘳𝘦𝘵 𝘬𝘦𝘺 --->"

}

variable "mime_types" {
  default = {
    htm   = "text/html"
    html  = "text/html"
    css   = "text/css"
    ttf   = "font/ttf"
    json  = "application/json"
    png   = "image/png"
    jpg   = "image/jpeg"
    woff2 = "font/woff2"
    woff  = "font/woff"
    eot   = "application/vnd.ms-fontobject"
    js    = "text/javascript"
    otf   = "font/otf"
    svg   = "image/svg+xml"
  }
}
