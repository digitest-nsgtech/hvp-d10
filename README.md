# üldine https://www.drupal.org/docs/getting-started/multisite-drupal/set-up-a-multisite
https://git.drupalcode.org/project/drupal/-/tree/11.x/sites?ref_type=heads

https://www.drupal.org/project/drupal/releases/10.4.6

https://www.drupal.org/project/drupal/releases

https://www.cloudpanel.io/docs/v2/php/applications/drupal/

composer.json ja composer.lock on hetkel lahutamatud, kuna on kasutusel ka mitte sobivaid pluginaid. Ehk uue lock faili loomine ei ole võimalik ilma et pluginaid minema ei viskaks,

Eriti

rm -rf vendor/ composer.lock
composer install --no-dev
COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --ignore-platform-reqs
Viga pakettides:

composer remove \
  ckeditor/autogrow \
  ckeditor/codemirror \
  ckeditor/fakeobjects \
  ckeditor/image \
  ckeditor/link \
  popperjs/popperjs \
  tippyjs/5.x \
  tippyjs/6.x \
  tippyjs/tippyjs \
  drupal/bartik \
  drupal/color \
  drupal/rdf \
  drupal/seven \
  drupal/dwr \
  --update-with-all-dependencies
Siis:
rm -rf vendor/ composer.lock
ja siis:
composer update

# nullist installil tuleb :
1) luua web kataloogi sites kataloog
2) sites kataloogi tuleb panna default ja all kataloog
3) web kataloogi tuleb luua .httaccess file
4) Apache konf tuleb muuta lisada <Directory /opt/hvp-drupal10/web>
    AllowOverride All
    Require all granted
</Directory>
 nii ssl kui ka 000 konfi ja ka apache konfis kus on web
5) kontrollida et apache kasutaks ka sama php versiooni mis cliendis
6) sites kataloogi tuleb luua sites.php vaata näidet
<?php
$sites['school-two.myserver.com'] = 'school-two.myserver.com';

7) pane patch ruutu
/opt/hvp-drupal10/
├── composer.json
├── composer.lock
├── patches/
│   └── help_text_does_not_override_Link_text.patch
├── vendor/
└── web/



# .htaccessi faili loomine:

sudo tee /opt/hvp-drupal10/web/.htaccess > /dev/null <<'EOF'
<IfModule mod_rewrite.c>
  RewriteEngine on
  RewriteBase /

  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^ index.php [L]
</IfModule>

<IfModule !mod_rewrite.c>
  ErrorDocument 404 /index.php
</IfModule>
EOF


# manifestid
k8s-manifests/
├── school-one/
│   ├── drupal-certificate.yaml     # or drupal-school-one-certificate.yaml
│   └── drupal-ingress.yaml         # or drupal-school-one-ingress.yaml
├── school-two/
│   ├── drupal-certificate.yaml
│   └── drupal-ingress.yaml




# apache clean url

Thanks for confirming — let’s break this down methodically.

You’re still seeing the “Your server is capable of using clean URLs, but it is not enabled” warning, even after:
	•	Installing drupal/core
	•	Running composer drupal:scaffold
	•	Ensuring /web/.htaccess exists

⸻

✅ Step-by-step checklist to resolve this

1. ✅ Confirm .htaccess exists and contains correct rewrite rules

Run:

grep "RewriteEngine" /opt/hvp-drupal10/web/.htaccess

You must see:

RewriteEngine on

Also, confirm that .htaccess has the Drupal rules like:

RewriteBase /
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [L]

If not, you’re missing the default Drupal .htaccess.

⸻

2. ✅ Confirm Apache mod_rewrite is enabled

Run:

sudo a2enmod rewrite
sudo systemctl restart apache2


⸻

3. ✅ Ensure Apache is allowing overrides via .htaccess

Edit your Apache vhost config (likely /etc/apache2/sites-available/000-default.conf or the SSL one):

<Directory /opt/hvp-drupal10/web>
    AllowOverride All
    Require all granted
</Directory>

Without AllowOverride All, Apache ignores .htaccess.

Then:

sudo systemctl restart apache2


⸻

4. ✅ Make sure Drupal knows it can use clean URLs

If Drupal still says clean URLs aren’t enabled, check:

curl -I http://school-two.myserver.com/core/authorize.php

If you get a 200 OK, rewrite isn’t working. If you get a 404 or 403, rewrite likely is working.

Also check /admin/config/search/clean-urls (on older versions) or try drush config:get system.site clean_url.

⸻

5. ❌ Still failing? Force test with a rewritten path

Try visiting:

http://school-two.myserver.com/index.php?q=node

Then try:

http://school-two.myserver.com/node

If /node works, clean URLs are working. If only /index.php?q=node works — rewrite still failing.

⸻

✅ Summary of minimum requirements
	•	.htaccess present in /web
	•	Apache has mod_rewrite enabled
	•	Apache config allows AllowOverride All for that directory
	•	Web server uses that directory as DocumentRoot

⸻

Let me know what you find from the curl test and if RewriteEngine is present in your .htaccess. We’ll nail this down.



# erinevad appache versioonide teema

You’re running PHP 8.3.6 in CLI, but Apache (or PHP-FPM) uses PHP 8.1.27.

Twig 3.19+ (and Twig\DeprecatedCallableInfo) requires PHP ≥8.1, which you have only in CLI, not under the web server context.

The error is happening only in the browser, because Apache is using PHP 8.1, and your current vendor/ was built using PHP 8.3 CLI — causing incompatibility between compiled classes and actual runtime.

Ah, that clarifies it — yes, if you’re seeing PHP 8.1.27 in the Drupal web UI, but your host machine has PHP 8.3, then:

✅ The Apache + PHP environment is running inside a Kubernetes pod, and it uses PHP 8.1.

⸻

🔍 Why this happens:
	•	Your host VM might have PHP 8.3 and Apache configured.
	•	But Drupal is being served by a container running in Kubernetes, and that container has PHP 8.1 installed.
	•	So all composer, php, or Apache module changes on the VM won’t affect what the browser sees — because those happen outside the pod.

⸻

✅ To verify:

Run this inside the pod (from your VM):

kubectl exec -it <pod-name> -- php -v

Replace <pod-name> with the name of your Drupal pod (e.g., drupal10-667f558c78-qcv4j).

⸻

🛠️ How to upgrade to PHP 8.3 in Kubernetes:

You need to change the container image used in your deployment. Most likely:

1. You’re using an image like:

image: php:8.1-apache

2. Update it to:

image: php:8.3-apache

Or, if you’re using a Drupal-specific image:

image: drupal:10.4.6-php8.3-apache

You can check the latest valid Drupal Docker tags here.

⸻

🚀 Steps to fix:
	1.	Edit your deployment:

kubectl edit deployment <your-drupal-deployment>

	2.	Locate the image line and update it, for example:

spec:
  containers:
    - name: drupal
      image: drupal:10.4.6-php8.3-apache

	3.	Save and exit. Kubernetes will automatically roll out a new pod using PHP 8.3.
	4.	Confirm after restart:

kubectl get pods
kubectl exec -it <new-pod-name> -- php -v


⸻

⚠️ Don’t forget:
	•	You may need to reinstall Composer dependencies if you mounted the Drupal code externally.
	•	Ensure your composer.lock and vendor/ contents are compatible with PHP 8.3.
	•	Clear Drupal caches if needed:

kubectl exec -it <pod-name> -- drush cr

Let me know your current deployment YAML or Helm setup, and I can help you adjust it precisely.





# baasi kustutamine

sudo mysql -u root

DROP DATABASE your_db_name;
CREATE DATABASE your_db_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON your_db_name.* TO 'your_db_user'@'localhost' IDENTIFIED BY 'your_password';
FLUSH PRIVILEGES;
EXIT;


# baasi dumpi panemine baasi

mysql -h 1.1.1.1 -u school2_user -p school2_db < dump-uus-kool-d10.sql

ja samas serveris:
mysql -u root -p school2_db < dump-uus-kool-d10.sql



# composeris võib tekkida probleem ka aegunud https://github.com/algolia/places

        "post-install-cmd": [
            "find ./web/libraries//algolia.places -type f -exec sed -i 's/cdn\\.polyfill\\.io/cdnjs\\.cloudflare\\.com\\/polyfill/g' {} +",


# ennast kataloogi vms omanikuks panemine: 
sudo chown -R $(whoami):$(whoami) /opt/hvp-drupal10/web/sites

# Apache kasutaja omanikuks tõstmine
mkdir -p sites/school-two/files
chmod -R 775 sites/school-two/files
chown -R www-data:www-data sites/school-two/files