openssl genrsa -out dev/rsa.private 2048
openssl rsa -in dev/rsa.private -out dev/rsa.public -pubout -outform PEM