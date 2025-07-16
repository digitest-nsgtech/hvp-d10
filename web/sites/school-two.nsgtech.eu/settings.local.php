<?php

$base_url = 'https://school-two.nsgtech.eu';

#putenv('AWS_ACCESS_KEY_ID=d1bc27863cb8bdee9e7204900d55a35a');
#putenv('AWS_SECRET_ACCESS_KEY=d1bc27863cb8bdee9e7204900d55a35a');


$databases = [];

$settings['hash_salt']  = file_get_contents(__DIR__ . '/salt.txt');

$settings['update_free_access'] = FALSE;
# $settings['file_public_base_url'] = 'http://downloads.example.com/files';
# $settings['file_public_path'] = 'sites/default/files';
# $settings['file_additional_public_schemes'] = ['example'];
# $settings['file_private_path'] = '';
# $settings['file_temp_path'] = '/tmp';
# $settings['session_write_interval'] = 180;
# $settings['maintenance_theme'] = 'claro';
/**
 * OVERRIDES
 */
$settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';

# $settings['container_base_class'] = '\Drupal\Core\DependencyInjection\Container';
# $settings['yaml_parser_class'] = NULL;

/**
 * For example:
 * $settings['trusted_host_patterns'] = [
 *   '^www\.example\.com$',
 * ];
*/
# $settings['trusted_host_patterns'] = [];

$settings['file_scan_ignore_directories'] = [
  'node_modules',
  'bower_components',
];
$settings['entity_update_batch_size'] = 50;
$settings['entity_update_backup'] = TRUE;
$settings['state_cache'] = TRUE;
$settings['migrate_node_migrate_type_classic'] = FALSE;

/**
 * Load local development override configuration, if available.
 *
 * Create a settings.local.php file to override variables on secondary (staging,
 * development, etc.) installations of this site.
 *
 * Typical uses of settings.local.php include:
 * - Disabling caching.
 * - Disabling JavaScript/CSS compression.
 * - Rerouting outgoing emails.
 *
 * Keep this code block at the end of this file to take full effect.
 */
#
# if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
#   include $app_root . '/' . $site_path . '/settings.local.php';
# }



$databases['default']['default'] = array (
  'database' => 'school2_db',
  'username' => 'school2_user',
  'password' => 'school2_pass',
  'prefix' => '',
  'host' => '10.0.0.2',
  'port' => '3306',
  'isolation_level' => 'READ COMMITTED',
  'driver' => 'mysql',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
);

// ——————————————————————————
// 0) Credentials & wrapper flags
// ——————————————————————————
$settings['s3fs.access_key'] = 'd1bc27863cb8bdee9e7204900d55a35a';
$settings['s3fs.secret_key'] = 'b54382b9e06474f8a117a7ee1ed3aba0';
$settings['s3fs.use_s3_for_public']  = TRUE;
$settings['s3fs.use_s3_for_private'] = TRUE;

// ——————————————————————————
// 1) Tell Drupal to use the S3FS wrapper
// ——————————————————————————
$config['system.file']['default_scheme'] = 's3fs';

// ——————————————————————————
// 2) Define your adapters
//    (keyed by name, not 0/1)
// ——————————————————————————
$config['s3fs.adapters']['school_two_public'] = [
  'bucket'        => 'drupaltest',
  'endpoint'      => 'https://eu2.contabostorage.com',
  'use_https'     => TRUE,
  'public_folder' => basename(__DIR__) . '/public',
  'visibility'    => 'public',
];
$config['s3fs.adapters']['school_two_private'] = [
  'bucket'         => 'drupaltest',
  'endpoint'       => 'https://eu2.contabostorage.com',
  'use_https'      => TRUE,
  'private_folder' => basename(__DIR__) . '/private',
  'visibility'     => 'private',
];

// ——————————————————————————
// 3) Point S3FS at those adapters
// ——————————————————————————
$config['s3fs.settings']['default_public_adapter']  = 'school_two_public';
$config['s3fs.settings']['default_private_adapter'] = 'school_two_private';

/*
// create public and private buckets
// create etc/host record for bor.minio as defined in docker-compose file and within these configs

$config['s3fs.settings']['access_key'] = 'd1bc27863cb8bdee9e7204900d55a35a'; // Your keys
$config['s3fs.settings']['secret_key'] = 'b54382b9e06474f8a117a7ee1ed3aba0'; // Your keys

$config['s3fs.settings']['bucket'] = 'drupaltest'; // sets drupal to pull assets from bor.$config['s3fs.settings']['hostname'] if no_rewrite_cssjs is set to true
$config['s3fs.settings']['region'] = 'eu-west-1'; // Your region (doesn't really matter if using minio, just set it to something)

$config['s3fs.settings']['use_https'] = TRUE;
#$config['s3fs.settings']['no_rewrite_cssjs'] = TRUE;

$config['s3fs.settings']['use_customhost'] = TRUE;
$config['s3fs.settings']['hostname'] = "eu2.contabostorage.com";

//$config['s3fs.settings']['use_cname'] = TRUE; // I'm not using this
//$config['s3fs.settings']['domain'] = 'bor.minio'; // I'm not using this

// public and private folders
$settings['s3fs.use_s3_for_public'] = TRUE;
$settings['s3fs.use_s3_for_private'] = TRUE;

// create these bucket names in minio
$config['s3fs.settings']['public_folder'] = 'school-two-public'; // Your public directories in S3 (name of the bucket in minio)
$config['s3fs.settings']['private_folder'] = 'school-two-private'; // Your private directories in S3 (name of the bucket in minio)
*/