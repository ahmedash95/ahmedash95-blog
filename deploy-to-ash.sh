# zip public.zip public/*

# scp -r public.zip root@ahmedash.com:/var/www/html/

# ssh root@ahmedash.com cd /var/www/html && unzip public.zip

scp -r public/* root@ahmedash.com:/var/www/html/
